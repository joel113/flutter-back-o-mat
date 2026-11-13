import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../util/db/db.dart';
import '../recipe/data/recipe_repository.dart';
import 'item.dart';
import 'recipe_summary.dart';
import '../recipe/editor/add_recipe.dart';
import '../theme/app_components.dart';

class BackomatRecipes extends StatefulWidget {
  const BackomatRecipes({super.key, this.loadRecipes, this.saveOrder});

  final Future<List<RecipeJsonEntry>> Function()? loadRecipes;
  final Future<void> Function(List<int> familyIds)? saveOrder;

  @override
  State<BackomatRecipes> createState() => _BackomatRecipesState();
}

class _BackomatRecipesState extends State<BackomatRecipes> {
  late Future<List<RecipeSummary>> _recipes;
  final repository = RecipeRepository();
  bool savingOrder = false;

  @override
  void initState() {
    super.initState();
    _recipes = _loadRecipes();
  }

  Future<List<RecipeSummary>> _loadRecipes() async {
    final entries =
        await (widget.loadRecipes ?? repository.listFamilyEntries)();
    return entries.map(RecipeSummary.fromEntry).toList();
  }

  Future<void> reorder(
    List<RecipeSummary> recipes,
    int oldIndex,
    int newIndex,
  ) async {
    if (savingOrder || oldIndex == newIndex) return;
    final previous = List<RecipeSummary>.of(recipes);
    setState(() {
      recipes.insert(newIndex, recipes.removeAt(oldIndex));
      savingOrder = true;
    });
    try {
      await (widget.saveOrder ?? repository.saveFamilyOrder)(
        recipes.map((recipe) => recipe.familyId ?? recipe.id).toList(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        recipes
          ..clear()
          ..addAll(previous);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.recipeOrderSaveError),
        ),
      );
    } finally {
      if (mounted) setState(() => savingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AppPage(
      title: strings.recipes,
      subtitle: strings.recipesSubtitle,
      actions: [
        FilledButton.icon(
          onPressed: savingOrder
              ? null
              : () async {
                  final id = await addRecipe(context);
                  if (id != null && mounted) {
                    setState(() {
                      _recipes = _loadRecipes();
                    });
                  }
                },
          icon: const Icon(Icons.add),
          label: Text(strings.addRecipe),
        ),
      ],
      child: FutureBuilder<List<RecipeSummary>>(
        future: _recipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.recipesLoadError),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => setState(() {
                      _recipes = _loadRecipes();
                    }),
                    child: Text(strings.retry),
                  ),
                ],
              ),
            );
          }
          final recipes = snapshot.data!;
          if (recipes.isEmpty) {
            return Center(child: Text(strings.noRecipes));
          }
          return AbsorbPointer(
            absorbing: savingOrder,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: recipes.length,
              onReorderItem: (oldIndex, newIndex) =>
                  reorder(recipes, oldIndex, newIndex),
              itemBuilder: (context, index) => Column(
                key: ValueKey(recipes[index].familyId ?? recipes[index].id),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Item(
                          recipe: recipes[index],
                          onChanged: () {
                            if (mounted) {
                              setState(() {
                                _recipes = _loadRecipes();
                              });
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Tooltip(
                          message: strings.reorderRecipes,
                          child: ReorderableDragStartListener(
                            key: ValueKey(
                              'reorder-${recipes[index].familyId ?? recipes[index].id}',
                            ),
                            index: index,
                            enabled: !savingOrder && recipes.length > 1,
                            child: SizedBox(
                              width: 32,
                              height: 48,
                              child: Icon(
                                Icons.drag_handle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (index < recipes.length - 1) const Divider(height: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
