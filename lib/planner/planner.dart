import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../baking/baking_labels.dart';
import '../baking/baking_repository.dart';
import '../baking/baking_session.dart';
import '../baking/baking_view.dart';
import '../baking/baking_composer.dart';
import '../baking/preparation_selection.dart';
import '../l10n/app_localizations.dart';
import '../recipe/data/recipe_data.dart';
import '../recipe/data/recipe_family.dart';
import '../recipe/data/recipe_repository.dart';
import '../util/db/db.dart';
import '../theme/app_components.dart';

class BackomatPlanner extends StatefulWidget {
  const BackomatPlanner({
    super.key,
    this.repository,
    this.loadRecipes,
    this.recipeRepository,
  });
  final BakingRepository? repository;
  final RecipeRepository? recipeRepository;
  final Future<List<RecipeJsonEntry>> Function()? loadRecipes;
  @override
  State<BackomatPlanner> createState() => _BackomatPlannerState();
}

class _BackomatPlannerState extends State<BackomatPlanner> {
  late final recipes = widget.recipeRepository ?? RecipeRepository();
  late final repository = widget.repository ?? BakingRepository();
  late Future<List<BakingSession>> sessions;
  Timer? ticker;
  bool adding = false;
  String? error;
  @override
  void initState() {
    super.initState();
    sessions = repository.list();
  }

  bool? sectionVisible;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (sectionVisible == visible) return;
    final previous = sectionVisible;
    sectionVisible = visible;
    ticker?.cancel();
    ticker = null;
    if (visible) {
      if (previous == false) sessions = repository.list();
      ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void refresh() => setState(() {
    sessions = repository.list();
  });
  Future<void> add() async {
    final s = AppLocalizations.of(context)!;
    setState(() {
      adding = true;
      error = null;
    });
    try {
      final entries = await (widget.loadRecipes ?? recipes.listFamilyEntries)();
      final available = <int, RecipeData>{};
      final families = <int, RecipeFamily>{};
      final names = <int, String>{};
      for (final entry in entries) {
        try {
          final recipe = RecipeData.fromJson(
            jsonDecode(entry.jsonData) as Map<String, dynamic>,
          );
          if (entry.familyId != null) {
            final family = await recipes.loadFamily(entry.familyId!);
            if (family.variants.any((v) => v.recipe.bakingReady)) {
              families[entry.id] = family;
              available[entry.id] = recipe;
              names[entry.id] = family.name;
            }
          } else if (recipe.bakingReady) {
            available[entry.id] = recipe;
            names[entry.id] = recipe.name;
          }
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
      if (!mounted) return;
      if (available.isEmpty) {
        setState(() => error = s.noReadyRecipes);
        return;
      }
      var recipeId = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(s.chooseBakingRecipe),
          children: [
            for (final entry in available.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Text(names[entry.key]!),
              ),
          ],
        ),
      );
      if (recipeId == null || !mounted) return;
      final family = families[recipeId];
      RecipeVariant? variant;
      if (family != null) {
        final choices = family.variants
            .where((v) => v.recipe.bakingReady)
            .toList();
        var selected =
            choices.where((v) => v.id == family.mainRecipeId).firstOrNull ??
            choices.first;
        if (choices.length > 1) {
          final chosen = await showDialog<RecipeVariant>(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                title: Text(family.name),
                content: DropdownButtonFormField<int>(
                  initialValue: selected.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.variantLabel),
                  items: [
                    for (final v in choices)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text(
                          '${v.name}${v.id == family.mainRecipeId ? ' · ${s.mainVariant}' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    if (id != null) {
                      update(
                        () => selected = choices.firstWhere((v) => v.id == id),
                      );
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: Text(s.planBake),
                  ),
                ],
              ),
            ),
          );
          if (chosen == null || !mounted) return;
          selected = chosen;
        }
        variant = selected;
        recipeId = selected.id;
      }
      if (!mounted) return;
      final rootRecipe = variant?.recipe ?? available[recipeId]!;
      final selectedPreparations = await selectPreparations(
        context,
        rootRecipe,
        recipes,
      );
      if (selectedPreparations == null || !mounted) return;
      final composition = await BakingComposer(recipes).resolve(
        RecipeRecord(id: recipeId, recipe: rootRecipe, family: family),
        selectedPreparations,
      );
      if (!mounted) return;
      final start = await pickBakeTime(context, DateTime.now());
      if (start == null || !mounted) return;
      final saved = await repository.save(
        BakingSession(
          recipeId: recipeId,
          recipe: composition.recipe,
          extraDependencies: composition.dependencies,
          components: composition.components,
          familyName: composition.root.family?.name,
          variantName: composition.root.variant?.name ?? variant?.name,
          sharedNotes: composition.root.family?.notes ?? const [],
          plannedStart: start,
        ),
      );
      if (!mounted) return;
      setState(() {
        adding = false;
        sessions = repository.list();
      });
      await open(saved.id!);
    } catch (_) {
      if (mounted) setState(() => error = s.sessionSaveError);
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  Future<void> open(int id) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BakingView(sessionId: id, repository: repository),
      ),
    );
    if (mounted) refresh();
  }

  Future<void> remove(BakingSession session) async {
    final s = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.removeBakeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.removeBake),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await repository.delete(session.id!);
      if (mounted) refresh();
    } catch (_) {
      if (mounted) setState(() => error = s.sessionSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AppPage(
      title: s.planer,
      subtitle: s.plannerSubtitle,
      actions: [
        FilledButton.icon(
          onPressed: adding ? null : add,
          icon: const Icon(Icons.add),
          label: Text(s.planBake),
        ),
        IconButton(
          onPressed: refresh,
          tooltip: s.retry,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<BakingSession>>(
              future: sessions,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.sessionLoadError),
                        TextButton(onPressed: refresh, child: Text(s.retry)),
                      ],
                    ),
                  );
                }
                final list = snapshot.data!;
                if (list.isEmpty) return Center(child: Text(s.noBakes));
                return LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: constraints.maxWidth < 900
                            ? 900
                            : constraints.maxWidth,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(s.recipes)),
                            DataColumn(label: Text(s.plannedStart)),
                            DataColumn(label: Text(s.readyBetween)),
                            DataColumn(label: Text(s.sessionStatus)),
                            DataColumn(label: Text(s.actionsColumn)),
                          ],
                          rows: [for (final bake in list) row(bake)],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow row(BakingSession bake) {
    final s = AppLocalizations.of(context)!;
    final ready = bake.completionWindow(DateTime.now());
    return DataRow(
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              [
                bake.familyName ?? bake.recipe.name,
                if (bake.variantName != null) bake.variantName!,
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () => open(bake.id!),
        ),
        DataCell(Text(bakeTime(context, bake.plannedStart))),
        DataCell(
          Text(
            ready.earliestEnd == ready.latestEnd
                ? bakeTime(context, ready.earliestEnd)
                : '${bakeTime(context, ready.earliestEnd)}\n${bakeTime(context, ready.latestEnd)}',
          ),
        ),
        DataCell(
          AppStatusBadge(
            label: sessionStatusText(s, bake.status),
            tone: sessionStatusTone(bake.status),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: s.openBake,
                onPressed: () => open(bake.id!),
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: s.removeBake,
                onPressed: () => remove(bake),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
