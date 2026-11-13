import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../recipe/data/recipe_data.dart';
import 'baking_session.dart';
import 'baking_repository.dart';
import 'baking_labels.dart';
import 'baking_timeline.dart';
import 'baking_composer.dart';
import 'preparation_selection.dart';
import '../recipe/data/recipe_repository.dart';
import '../recipe/data/recipe_family.dart';
import '../theme/app_components.dart';
import '../recipe/editor/recipe_notes.dart';

/// Entering from a recipe resumes an active bake, then its earliest planned bake.
/// The planner's Add action always creates a separate bake.
class BakingEntry extends StatefulWidget {
  const BakingEntry({
    super.key,
    required this.recipeId,
    required this.recipe,
    this.repository,
    this.recipeRepository,
    this.familyName,
    this.variantName,
    this.sharedNotes = const [],
  });
  final int recipeId;
  final RecipeData recipe;
  final String? familyName;
  final String? variantName;
  final List<RecipeNote> sharedNotes;
  final BakingRepository? repository;
  final RecipeRepository? recipeRepository;
  @override
  State<BakingEntry> createState() => _BakingEntryState();
}

class _BakingEntryState extends State<BakingEntry> {
  late final repository = widget.repository ?? BakingRepository();
  late Future<BakingSession?> session;
  @override
  void initState() {
    super.initState();
    session = open();
  }

  Future<BakingSession?> open() async {
    var recipe = widget.recipe;
    BakingComposition? composition;
    if (recipe.preparations.isNotEmpty) {
      final existing = await repository.activeForRecipe(widget.recipeId);
      if (existing != null) return existing;
      if (!mounted) return null;
      final recipes = widget.recipeRepository ?? RecipeRepository();
      final selected = await selectPreparations(context, recipe, recipes);
      if (selected == null || !mounted) {
        if (mounted) Navigator.maybePop(context);
        return null;
      }
      composition = await BakingComposer(recipes)
          .resolve(RecipeRecord(id: widget.recipeId, recipe: recipe), selected);
      recipe = composition.recipe;
    }
    return repository.openForRecipe(
      widget.recipeId,
      recipe,
      DateTime.now(),
      familyName: composition?.root.family?.name ?? widget.familyName,
      variantName: composition?.root.variant?.name ?? widget.variantName,
      sharedNotes: composition?.root.family?.notes ?? widget.sharedNotes,
      extraDependencies: composition?.dependencies ?? const {},
      components: composition?.components ?? const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return FutureBuilder<BakingSession?>(
      future: session,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return BakingView(
            sessionId: snapshot.data!.id!,
            repository: repository,
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(widget.recipe.name)),
          body:
              snapshot.hasError ||
                  snapshot.connectionState == ConnectionState.done
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.sessionLoadError),
                      TextButton(
                        onPressed: () => setState(() {
                          session = open();
                        }),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class BakingView extends StatefulWidget {
  const BakingView({
    super.key,
    required this.sessionId,
    this.repository,
    this.clock,
  });
  final int sessionId;
  final BakingRepository? repository;
  final DateTime Function()? clock;
  @override
  State<BakingView> createState() => _BakingViewState();
}

class _BakingViewState extends State<BakingView> with WidgetsBindingObserver {
  late final repository = widget.repository ?? BakingRepository();
  late final DateTime Function() clock = widget.clock ?? DateTime.now;
  BakingSession? session;
  bool loading = true;
  bool busy = false;
  String? error;
  Timer? ticker;
  BakingTimelineDrag? drag;
  BakingSession? preview;
  double dragPixels = 0;
  int? selectedStage;
  bool timelineOnly = false;
  double zoom = 1;
  double timelineOffset = 0;
  BakingTimelineScale? timelineBaseScale;
  final timelineRowKeys = <int, GlobalKey>{};
  final timelineSurfaceKey = GlobalKey();
  bool get editing => busy || drag != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  bool? sectionVisible;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (sectionVisible == visible) return;
    sectionVisible = visible;
    ticker?.cancel();
    ticker = null;
    if (visible) {
      ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted &&
            drag == null &&
            session?.status == BakeSessionStatus.active) {
          setState(() {});
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        sectionVisible == true) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final saved = await repository.load(widget.sessionId);
      if (mounted) setState(() => session = saved);
    } catch (_) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.sessionLoadError);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> change(
    void Function(BakingSession) action, {
    BakingSession? candidate,
  }) async {
    if (busy || session == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final update = candidate ?? session!.copy();
      action(update);
      final saved = await repository.save(update);
      if (mounted) setState(() => session = saved);
    } catch (_) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context)!.sessionSaveError);
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          preview = null;
        });
      }
    }
  }

  void beginDrag(int id, bool resize, BakingTimelineScale scale) {
    if (editing) return;
    setState(() {
      selectedStage = id;
      dragPixels = 0;
      drag = BakingTimelineDrag(
        session: session!,
        stageId: id,
        resize: resize,
        now: clock(),
        scale: scale,
      );
      preview = drag!.original.copy();
    });
  }

  void updateDrag(int id, double dx) {
    if (drag?.stageId != id) return;
    setState(() {
      dragPixels += dx;
      preview = drag!.preview(dragPixels);
    });
  }

  Future<void> endDrag(int id) async {
    if (drag?.stageId != id || preview == null) return;
    final candidate = preview!;
    final original = drag!.original;
    drag = null;
    if (candidate.progress[id]!.durationMinutes ==
            original.progress[id]!.durationMinutes &&
        candidate.progress[id]!.notBefore == original.progress[id]!.notBefore) {
      setState(() => preview = null);
      return;
    }
    await change((_) {}, candidate: candidate);
  }

  void cancelDrag() {
    if (drag == null) return;
    setState(() {
      drag = null;
      preview = null;
    });
  }

  Future<void> startTime([int? stageId]) async {
    final saved = session!;
    final initial = stageId == null
        ? saved.plannedStart
        : saved.schedule(clock())[stageId]!.start;
    final selected = await pickBakeTime(context, initial);
    if (selected == null || !mounted) return;
    await change((s) {
      if (stageId == null) {
        s.plannedStart = selected;
      } else {
        s.setStepStart(stageId, selected);
      }
    });
    if (mounted && error == null) {
      setState(() {
        timelineBaseScale = null;
        zoom = 1;
        timelineOffset = 0;
      });
    }
  }

  Future<void> chooseDuration(RecipeStage stage) async {
    final s = AppLocalizations.of(context)!;
    var input = '${session!.progress[stage.id]!.durationMinutes}';
    final form = GlobalKey<FormState>();
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.chooseDuration),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: input,
            onChanged: (value) => input = value,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${s.durationColumn} (min)',
              helperText: '${stage.durationMin}–${stage.durationMax} min',
            ),
            validator: (text) {
              final n = int.tryParse(text ?? '');
              return n == null ||
                      n < stage.durationMin! ||
                      n > stage.durationMax!
                  ? s.durationRangeError
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, int.parse(input));
              }
            },
            child: Text(s.saveSchedule),
          ),
        ],
      ),
    );
    if (minutes != null && mounted) {
      await change((s) => s.setDuration(stage.id, minutes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final bake = preview ?? session;
    final colors = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): cancelDrag},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    bake == null
                        ? s.openBake
                        : [
                            bake.familyName ?? bake.recipe.name,
                            if (bake.variantName != null) bake.variantName!,
                          ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (bake != null) const SizedBox(width: 12),
                if (bake != null)
                  AppStatusBadge(
                    label: sessionStatusText(s, bake.status),
                    tone: sessionStatusTone(bake.status),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: s.bakingHelp,
                icon: const Icon(Icons.info_outline),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(s.bakingHelp),
                    content: Text('${s.recipeSnapshot}\n\n${s.scheduleHint}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          MaterialLocalizations.of(context).closeButtonLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : bake == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error ?? s.sessionLoadError),
                      TextButton(onPressed: load, child: Text(s.retry)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (busy) const LinearProgressIndicator(),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            error!,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      sessionSummary(bake),
                      if (bake.components.length > 1) ...[
                        const SizedBox(height: 16),
                        AppSurface(
                          child: ExpansionTile(
                            title: Text(s.preparationSnapshotHint),
                            leading: const Icon(Icons.account_tree_outlined),
                            childrenPadding: const EdgeInsets.all(16),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              for (final component in bake.components.take(
                                bake.components.length - 1,
                              )) ...[
                                Text(
                                  component.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                for (final ingredient
                                    in component.recipe.ingredients)
                                  Text(
                                    [
                                      if (ingredient.amount != null)
                                        '${ingredient.amount}',
                                      ingredient.unit,
                                      ingredient.name,
                                      ingredient.condition,
                                    ].where((v) => v.isNotEmpty).join(' '),
                                  ),
                                const SizedBox(height: 8),
                                if (component.recipe.notes.isNotEmpty ||
                                    component.sharedNotes.isNotEmpty)
                                  RecipeNotesSection(
                                    notes: component.recipe.notes,
                                    shared: component.sharedNotes,
                                  ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (bake.recipe.notes.isNotEmpty ||
                          bake.sharedNotes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        RecipeNotesSection(
                          notes: bake.recipe.notes,
                          shared: bake.sharedNotes,
                        ),
                      ],
                      const SizedBox(height: 16),
                      workspace(bake),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget sessionSummary(BakingSession bake) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ready = bake.completionWindow(drag?.now ?? clock());
    final start = Column(
      key: const ValueKey('bake-start-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.sessionStartLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        if (bake.status == BakeSessionStatus.planned)
          Tooltip(
            message: s.changeStart,
            excludeFromSemantics: true,
            child: Semantics(
              label: s.changeStart,
              child: OutlinedButton.icon(
                key: const ValueKey('change-bake-start'),
                onPressed: editing ? null : () => startTime(),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(bakeTime(context, bake.plannedStart)),
              ),
            ),
          )
        else
          Text(bakeTime(context, bake.plannedStart)),
      ],
    );
    final completion = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.readyBetween, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          '${bakeTime(context, ready.earliestEnd)} – ${bakeTime(context, ready.latestEnd)}',
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 800
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: start),
                const SizedBox(width: 24),
                Expanded(child: completion),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [start, const SizedBox(height: 12), completion],
            ),
    );
  }

  Widget workspace(BakingSession bake) => LayoutBuilder(
    builder: (context, constraints) {
      final s = AppLocalizations.of(context)!;
      final both = constraints.maxWidth >= 1500;
      final showTimeline = both || timelineOnly;
      final showDetails = both || !timelineOnly;
      final now = drag?.now ?? clock();
      final issues = bake
          .dependencyTimings(now)
          .where(
            (timing) =>
                timing.needsReview &&
                selectedStage != null &&
                timing.touches(selectedStage!),
          );
      final selectedWarning = issues.isEmpty
          ? ''
          : dependencyTimingText(s, bake, issues.first);
      final selectionLabel = selectedStage == null
          ? ''
          : [
              '${bake.recipe.stages.firstWhere((stage) => stage.id == selectedStage).name} · ${bakeTime(context, bake.schedule(now)[selectedStage]!.start)} → ${bakeTime(context, bake.schedule(now)[selectedStage]!.end)} · ${bake.progress[selectedStage]!.durationMinutes} min',
              if (selectedWarning.isNotEmpty) selectedWarning,
            ].join('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!both)
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.table_rows_outlined),
                      label: Text(s.tableView),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.timeline),
                      label: Text(s.timelineTitle),
                    ),
                  ],
                  selected: {timelineOnly},
                  onSelectionChanged: editing
                      ? null
                      : (selection) =>
                            setState(() => timelineOnly = selection.single),
                ),
              if (showTimeline) ...[
                IconButton(
                  tooltip: s.timelineEarlier,
                  onPressed: editing
                      ? null
                      : () => setState(() => timelineOffset -= .5),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: s.timelineZoomOut,
                  onPressed: editing || zoom <= .25
                      ? null
                      : () => setState(() => zoom /= 2),
                  icon: const Icon(Icons.zoom_out),
                ),
                TextButton(
                  onPressed: editing
                      ? null
                      : () => setState(() {
                          zoom = 1;
                          timelineOffset = 0;
                          timelineBaseScale = null;
                        }),
                  child: Text(s.timelineFit),
                ),
                IconButton(
                  tooltip: s.timelineZoomIn,
                  onPressed: editing || zoom >= 16
                      ? null
                      : () => setState(() => zoom *= 2),
                  icon: const Icon(Icons.zoom_in),
                ),
                IconButton(
                  tooltip: s.timelineLater,
                  onPressed: editing
                      ? null
                      : () => setState(() => timelineOffset += .5),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (showTimeline)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s.timelineDragHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (showTimeline)
            Text(
              s.timelineConnectionLegend,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (showTimeline)
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: selectedStage == null
                    ? const SizedBox.shrink()
                    : Text(
                        selectionLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
              ),
            ),
          stageTable(
            bake,
            constraints.maxWidth,
            showDetails: showDetails,
            showTimeline: showTimeline,
          ),
          timingDetails(bake, now),
        ],
      );
    },
  );

  Widget timingDetails(BakingSession bake, DateTime now) {
    final s = AppLocalizations.of(context)!;
    final timings = bake.dependencyTimings(now);
    final warnings = timings.where((timing) => timing.needsReview).toList();
    final waits = timings
        .where((timing) => timing.condition == BakeDependencyCondition.waiting)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (warnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.timingWarningsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final timing in warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color:
                              timing.condition ==
                                  BakeDependencyCondition.conflict
                              ? Theme.of(context).colorScheme.error
                              : bakeWarningColor(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dependencyTimingText(s, bake, timing),
                            key: ValueKey(
                              'timing-warning-${timing.predecessorId}-${timing.successorId}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (waits.isNotEmpty)
          ExpansionTile(
            title: Text(s.timingWaitingTitle),
            children: [
              for (final timing in waits)
                ListTile(
                  dense: true,
                  title: Text(dependencyTimingText(s, bake, timing)),
                ),
            ],
          ),
      ],
    );
  }

  Widget stageTable(
    BakingSession bake,
    double availableWidth, {
    required bool showDetails,
    required bool showTimeline,
  }) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = drag?.now ?? clock();
    final windows = bake.schedule(now);
    final timings = bake.dependencyTimings(now);
    final affected = preview != null && session != null
        ? bake.changedStagesFrom(session!, now)
        : <int>{};
    String warningFor(int id) => timings
        .where((timing) => timing.needsReview && timing.touches(id))
        .map((timing) => dependencyTimingText(s, bake, timing))
        .join('\n');
    bool conflictFor(int id) => timings.any(
      (timing) =>
          timing.condition == BakeDependencyCondition.conflict &&
          timing.touches(id),
    );
    final labels = {
      for (final i in bake.recipe.ingredients) i.id: i.name,
      for (final stage in bake.recipe.stages) stage.id: stage.name,
    };
    final units = {for (final i in bake.recipe.ingredients) i.id: i.unit};
    final timelineWidth = showTimeline
        ? (showDetails
              ? math.max(480.0, availableWidth * .36)
              : math.max(400.0, availableWidth - 150))
        : 0.0;
    final detailsWidth = showDetails
        ? (showTimeline
              ? math.max(940.0, availableWidth - timelineWidth)
              : math.max(1180.0, availableWidth))
        : 150.0;
    if (showTimeline) {
      timelineBaseScale ??= BakingTimelineScale.fit(
        session ?? bake,
        now,
        timelineWidth,
      );
    }
    final scale =
        drag?.scale ??
        (timelineBaseScale ?? BakingTimelineScale.fit(bake, now, timelineWidth))
            .viewport(width: timelineWidth, zoom: zoom, offset: timelineOffset);
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: child,
    );
    Widget header(String label) =>
        cell(Text(label, style: theme.textTheme.titleSmall));
    Widget nameCell(RecipeStage stage) => InkWell(
      onTap: () => setState(() => selectedStage = stage.id),
      child: cell(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bake.componentFor(stage.id) case final component?) ...[
                Tooltip(
                  message: component.label,
                  child: Text(
                    component.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                stage.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stepStatusText(s, bake.progress[stage.id]!.status),
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    height: 28,
                    child: warningFor(stage.id).isEmpty
                        ? null
                        : Tooltip(
                            message: warningFor(stage.id),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              key: ValueKey('timing-alert-${stage.id}'),
                              size: 16,
                              color: conflictFor(stage.id)
                                  ? theme.colorScheme.error
                                  : bakeWarningColor(context),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final table = Table(
      columnWidths: showDetails
          ? {
              0: const FixedColumnWidth(130),
              1: const FlexColumnWidth(),
              2: const FixedColumnWidth(125),
              3: const FixedColumnWidth(170),
              4: const FixedColumnWidth(115),
              5: const FixedColumnWidth(140),
              if (showTimeline) 6: FixedColumnWidth(timelineWidth),
            }
          : {
              0: const FixedColumnWidth(150),
              1: FixedColumnWidth(timelineWidth),
            },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
          ),
          children: [
            header(s.stageColumn),
            if (showDetails) ...[
              header(s.preparationColumn),
              header(s.durationTemperature),
              header(s.scheduleColumn),
              header(s.remainingTime),
              header(s.actionsColumn),
            ],
            if (showTimeline) TimelineAxis(scale: scale),
          ],
        ),
        for (final stage in bake.recipe.stages)
          TableRow(
            key: ValueKey('baking-row-${stage.id}'),
            decoration: selectedStage == stage.id
                ? BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: .3,
                    ),
                  )
                : affected.contains(stage.id)
                ? BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: .12,
                    ),
                  )
                : null,
            children: [
              nameCell(stage),
              if (showDetails) ...[
                cell(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final ref in stage.ingredients)
                        Text(
                          [
                            if (ref.amount != null) '${ref.amount}',
                            if (ref.amount != null) units[ref.id] ?? '',
                            labels[ref.id] ?? '#${ref.id}',
                            ref.condition,
                          ].where((e) => e.isNotEmpty).join(' '),
                        ),
                      if (stage.ingredients.isNotEmpty)
                        const SizedBox(height: 8),
                      Text(stage.description),
                    ],
                  ),
                ),
                cell(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bakeDurationRange(
                          stage.durationMin!,
                          stage.durationMax!,
                        ),
                      ),
                      if (stage.temperatureMin != null ||
                          stage.temperatureMax != null)
                        Text(
                          stage.temperatureMin == stage.temperatureMax
                              ? '${stage.temperatureMin} °C'
                              : '${stage.temperatureMin ?? '—'}–${stage.temperatureMax ?? '—'} °C',
                        ),
                      if (bake.progress[stage.id]!.status ==
                              BakeStepStatus.pending &&
                          stage.durationMin != stage.durationMax)
                        Tooltip(
                          message: s.chooseDuration,
                          child: TextButton(
                            key: ValueKey('duration-${stage.id}'),
                            onPressed: editing
                                ? null
                                : () => chooseDuration(stage),
                            child: Text(
                              bakeMinutes(
                                bake.progress[stage.id]!.durationMinutes,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                cell(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bakeTime(context, windows[stage.id]!.start)),
                      Text(bakeTime(context, windows[stage.id]!.end)),
                      if (bake.progress[stage.id]!.status ==
                          BakeStepStatus.pending)
                        TextButton(
                          onPressed: editing ? null : () => startTime(stage.id),
                          child: Text(s.changeStart),
                        ),
                    ],
                  ),
                ),
                cell(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countdown(bake.progress[stage.id]!.remaining(now)),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (bake.progress[stage.id]!.remaining(now).isNegative &&
                          bake.progress[stage.id]!.status !=
                              BakeStepStatus.completed)
                        Text(
                          s.overdue,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
                cell(actions(bake, stage.id)),
              ],
              if (showTimeline)
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.fill,
                  child: TimelineStage(
                    key: timelineRowKeys.putIfAbsent(
                      stage.id,
                      () => GlobalKey(),
                    ),
                    stage: stage,
                    session: bake,
                    window: windows[stage.id]!,
                    scale: scale,
                    selected: selectedStage == stage.id,
                    affected: affected.contains(stage.id),
                    timingWarning: warningFor(stage.id),
                    timingDescription: timings
                        .where(
                          (timing) =>
                              timing.condition !=
                                  BakeDependencyCondition.synchronized &&
                              timing.touches(stage.id),
                        )
                        .map((timing) => dependencyTimingText(s, bake, timing))
                        .join('\n'),
                    hasTimingConflict: conflictFor(stage.id),
                    enabled: !busy,
                    onSelect: () => setState(() => selectedStage = stage.id),
                    onMoveStart: () => beginDrag(stage.id, false, scale),
                    onResizeStart: () => beginDrag(stage.id, true, scale),
                    onUpdate: (dx) => updateDrag(stage.id, dx),
                    onEnd: () => endDrag(stage.id),
                    onCancel: cancelDrag,
                    onEditStart: () => startTime(stage.id),
                    onEditDuration: () => chooseDuration(stage),
                  ),
                ),
            ],
          ),
      ],
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: detailsWidth + timelineWidth,
        child: AppSurface(
          child: Stack(
            children: [
              table,
              if (showTimeline)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: timelineSurfaceKey,
                      painter: TimelineDependencies(
                        session: bake,
                        scale: scale,
                        now: now,
                        rowKeys: timelineRowKeys,
                        surfaceKey: timelineSurfaceKey,
                        color: theme.colorScheme.primary,
                        selectedId: selectedStage,
                        affectedStages: affected,
                        warningColor: bakeWarningColor(context),
                        errorColor: theme.colorScheme.error,
                        surfaceColor: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget actions(BakingSession bake, int id) {
    final s = AppLocalizations.of(context)!;
    final status = bake.progress[id]!.status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == BakeStepStatus.pending)
          Tooltip(
            message: bake.canStart(id) ? s.startStep : s.waitingDependencies,
            child: FilledButton(
              key: ValueKey('start-$id'),
              onPressed: editing || !bake.canStart(id)
                  ? null
                  : () => change((b) => b.start(id, clock())),
              child: Text(s.startStep),
            ),
          ),
        if (status == BakeStepStatus.running)
          OutlinedButton(
            key: ValueKey('pause-$id'),
            onPressed: editing
                ? null
                : () => change((b) => b.pause(id, clock())),
            child: Text(s.pauseStep),
          ),
        if (status == BakeStepStatus.paused)
          FilledButton(
            key: ValueKey('resume-$id'),
            onPressed: editing
                ? null
                : () => change((b) => b.resume(id, clock())),
            child: Text(s.resumeStep),
          ),
        if (status == BakeStepStatus.running || status == BakeStepStatus.paused)
          TextButton(
            key: ValueKey('done-$id'),
            onPressed: editing
                ? null
                : () => change((b) => b.complete(id, clock())),
            child: Text(s.completeStep),
          ),
      ],
    );
  }
}
