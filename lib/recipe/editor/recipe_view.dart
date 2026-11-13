import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../baking/baking_view.dart';
import '../data/recipe_data.dart';
import '../data/recipe_family.dart';
import 'recipe_notes.dart';
import 'recipe_preparations.dart';
import 'recipe_history.dart';
import '../data/recipe_repository.dart';
import 'recipe_editor.dart';
import 'recipe_image.dart';
import 'recipe_messages.dart';
import '../../theme/app_components.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({
    super.key,
    required this.id,
    this.baking = false,
    this.repository,
    this.preview,
    this.previewActions = const [],
  });
  final int id;
  final RecipeData? preview;
  final List<Widget> previewActions;
  final bool baking;
  final RecipeRepository? repository;
  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  late final repository = widget.repository ?? RecipeRepository();
  late Future<RecipeRecord> recipe;
  late int selectedId = widget.id;
  bool managing = false;
  bool variantsExpanded = false;
  RecipeRecord? current;
  Future<RecipeRecord> read() => widget.preview != null
      ? Future.value(RecipeRecord(id: selectedId, recipe: widget.preview!))
      : repository.loadRecord(selectedId);
  void refresh() => setState(() {
    recipe = read();
  });
  @override
  void initState() {
    super.initState();
    recipe = read();
  }

  Future<void> edit(RecipeData data) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecipeEditor(recipe: data, id: selectedId, repository: repository),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        recipe = read();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return FutureBuilder<RecipeRecord>(
      future: recipe,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            widget.baking &&
            snapshot.data!.recipe.bakingReady) {
          final record = snapshot.data!;
          return BakingEntry(
            recipeId: selectedId,
            recipe: record.recipe,
            recipeRepository: repository,
            familyName: record.family?.name,
            variantName: record.variant?.name,
            sharedNotes: record.family?.notes ?? const [],
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.preview != null
                  ? s.revisionPreview
                  : snapshot.data?.family?.name ??
                        snapshot.data?.recipe.name ??
                        s.recipes,
            ),
            actions: [
              ...widget.previewActions,
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  widget.preview == null)
                IconButton(
                  tooltip: s.editRecipe,
                  onPressed: managing
                      ? null
                      : () => edit(snapshot.data!.recipe),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.missingRecipe),
                      TextButton(
                        onPressed: () => setState(() {
                          recipe = read();
                        }),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : content(snapshot.data!),
        );
      },
    );
  }

  Future<void> history({bool shared = false}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeHistory(
          ownerId: shared ? current!.family!.id : selectedId,
          sharedNotes: shared,
          repository: repository,
        ),
      ),
    );
    if (mounted) refresh();
  }

  Future<void> prompt(
    String title,
    String initial,
    Future<void> Function(String) save, {
    bool variant = false,
  }) async {
    final s = AppLocalizations.of(context)!;
    var value = initial;
    final form = GlobalKey<FormState>();
    bool busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !busy,
          child: AlertDialog(
            title: Text(title),
            content: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: initial,
                    onChanged: (v) => value = v,
                    autofocus: true,
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: variant ? s.variantName : s.familyName,
                      hintText: variant ? s.variantNameHint : null,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? s.nameRequired : null,
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        update(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await save(value);
                          if (context.mounted) Navigator.pop(context);
                        } on FormatException {
                          if (context.mounted) {
                            update(() {
                              busy = false;
                              error = variant
                                  ? s.duplicateVariant
                                  : s.nameRequired;
                            });
                          }
                        } catch (_) {
                          if (context.mounted) {
                            update(() {
                              busy = false;
                              error = s.saveError;
                            });
                          }
                        }
                      },
                child: Text(variant ? s.create : s.saveRecipe),
              ),
            ],
          ),
        ),
      ),
    );
    // Dialog dismissal animates after its future completes.
    if (mounted) refresh();
  }

  Widget familyControls(RecipeRecord record) {
    final s = AppLocalizations.of(context)!;
    final family = record.family!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(selectedId),
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(labelText: s.variantLabel),
          items: [
            for (final v in family.variants)
              DropdownMenuItem(
                value: v.id,
                child: Text(
                  '${v.name}${v.id == family.mainRecipeId ? ' · ${s.mainVariant}' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: managing
              ? null
              : (id) {
                  if (id != null) {
                    setState(() {
                      selectedId = id;
                      recipe = read();
                    });
                  }
                },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: managing
                  ? null
                  : () => prompt(s.newVariant, '', (name) async {
                      final id = await repository.createVariant(
                        selectedId,
                        name,
                      );
                      if (mounted) selectedId = id;
                    }, variant: true),
              icon: const Icon(Icons.copy_outlined),
              label: Text(s.newVariant),
            ),
            if (selectedId != family.mainRecipeId)
              TextButton.icon(
                onPressed: managing
                    ? null
                    : () async {
                        setState(() => managing = true);
                        try {
                          await repository.setMainVariant(
                            family.id,
                            selectedId,
                          );
                          if (mounted) refresh();
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.saveError)),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => managing = false);
                        }
                      },
                icon: const Icon(Icons.star_outline),
                label: Text(s.makeMainVariant),
              ),
            TextButton.icon(
              onPressed: managing ? null : () => history(),
              icon: const Icon(Icons.history),
              label: Text(s.history),
            ),
            TextButton(
              onPressed: managing
                  ? null
                  : () => prompt(
                      s.renameFamily,
                      family.name,
                      (name) => repository.renameFamily(family.id, name),
                    ),
              child: Text(s.renameFamily),
            ),
          ],
        ),
      ],
    );
  }

  Widget content(RecipeRecord record) {
    current = record;
    final data = record.recipe;
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.name, style: theme.textTheme.headlineMedium),
                      if (data.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          data.description,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  );
                  if (data.image != null && constraints.maxWidth >= 760) {
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: RecipeImage(
                            image: data.image,
                            width: 300,
                            height: 220,
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(child: heading),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (data.image != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: RecipeImage(image: data.image, height: 200),
                        ),
                        const SizedBox(height: 20),
                      ],
                      heading,
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              if (record.family != null) ...[
                AppSurface(
                  child: ExpansionTile(
                    key: const ValueKey('recipe-variants'),
                    initiallyExpanded: variantsExpanded,
                    onExpansionChanged: (expanded) =>
                        setState(() => variantsExpanded = expanded),
                    leading: const Icon(Icons.layers_outlined),
                    title: Text(s.variantsLabel),
                    subtitle: Text(record.variant!.name),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    childrenPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [familyControls(record)],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (record.family != null || data.preparations.isNotEmpty) ...[
                RecipePreparationsSection(
                  recipe: data,
                  repository: repository,
                  onEdit: widget.preview != null || managing
                      ? null
                      : () => edit(data),
                  onOpen: widget.preview != null
                      ? null
                      : (id) async {
                          await Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeView(id: id, repository: repository),
                            ),
                          );
                          if (mounted) refresh();
                        },
                ),
                const SizedBox(height: 12),
              ],
              RecipeNotesSection(
                notes: data.notes,
                showShared: widget.preview == null,
                shared: record.family?.notes ?? const [],
                onEditVariant: widget.preview != null || managing
                    ? null
                    : () => edit(data),
                onEditShared: record.family == null || managing
                    ? null
                    : () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharedNotesEditor(
                              familyId: record.family!.id,
                              notes: record.family!.notes,
                              repository: repository,
                            ),
                          ),
                        );
                        if (mounted) refresh();
                      },
                onSharedHistory: record.family == null || managing
                    ? null
                    : () => history(shared: true),
              ),
              if (!data.bakingReady) ...[
                const SizedBox(height: 16),
                Text(s.draftNotice),
                for (final issue in data.validate())
                  Text(recipeIssueText(s, issue)),
              ],
              const SizedBox(height: 28),
              Text(s.ingredientsLabel, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (data.ingredients.isEmpty) Text(s.missingIngredients),
              for (final ingredient in data.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    [
                      if (ingredient.amount != null) '${ingredient.amount}',
                      ingredient.unit,
                      ingredient.name,
                      ingredient.condition,
                    ].where((e) => e.isNotEmpty).join(' '),
                  ),
                ),
              const SizedBox(height: 28),
              Text(s.stagesLabel, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (data.stages.isEmpty) Text(s.missingStages),
              if (data.stages.isNotEmpty) stageTable(data),
              if (!widget.baking && widget.preview == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: data.bakingReady
                          ? () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeView(
                                  id: selectedId,
                                  baking: true,
                                  repository: repository,
                                ),
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(s.startBaking),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget stageTable(RecipeData data) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labels = <int, String>{
      for (final ingredient in data.ingredients) ingredient.id: ingredient.name,
      for (final stage in data.stages) stage.id: stage.name,
    };
    final units = {
      for (final ingredient in data.ingredients) ingredient.id: ingredient.unit,
    };
    String duration(int minutes) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      return [
        if (hours != 0) '$hours h',
        if (rest != 0 || hours == 0) '$rest min',
      ].join(' ');
    }

    String range(int? lower, int? upper, String Function(int) format) {
      if (lower == null && upper == null) return '—';
      if (lower == upper) return format(lower!);
      return '${lower == null ? '—' : format(lower)} – ${upper == null ? '—' : format(upper)}';
    }

    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: child,
    );
    Widget heading(String label) =>
        cell(Text(label, style: theme.textTheme.titleSmall));

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 680 ? 680 : constraints.maxWidth,
          child: AppSurface(
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(160),
                1: FlexColumnWidth(3),
                2: FixedColumnWidth(150),
                3: FixedColumnWidth(120),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                  ),
                  children: [
                    heading(s.stageColumn),
                    heading(s.preparationColumn),
                    heading(s.durationColumn),
                    heading(s.temperatureColumn),
                  ],
                ),
                for (final stage in data.stages)
                  TableRow(
                    children: [
                      cell(
                        Text(
                          stage.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      cell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final ref in stage.ingredients)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  [
                                    if (ref.amount != null)
                                      ref.amount! % 1 == 0
                                          ? '${ref.amount!.toInt()}'
                                          : '${ref.amount}',
                                    if (ref.amount != null) units[ref.id] ?? '',
                                    labels[ref.id] ?? '#${ref.id}',
                                    ref.condition,
                                  ].where((part) => part.isNotEmpty).join(' '),
                                ),
                              ),
                            if (stage.ingredients.isNotEmpty &&
                                stage.description.isNotEmpty)
                              const SizedBox(height: 8),
                            if (stage.description.isNotEmpty)
                              Text(stage.description),
                          ],
                        ),
                      ),
                      cell(
                        Text(
                          range(stage.durationMin, stage.durationMax, duration),
                        ),
                      ),
                      cell(
                        Text(
                          range(
                            stage.temperatureMin,
                            stage.temperatureMax,
                            (value) => '$value °C',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
