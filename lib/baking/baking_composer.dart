import '../recipe/data/recipe_data.dart';
import '../recipe/data/recipe_family.dart';
import '../recipe/data/recipe_repository.dart';
import 'baking_component.dart';

class PreparationOption {
  const PreparationOption({required this.link, this.record});
  final RecipePreparation link;
  final RecipeRecord? record;
  bool get available => record?.recipe.bakingReady ?? false;
  String get label => record == null
      ? '#${link.recipeId}'
      : '${record!.family?.name ?? record!.recipe.name}${record!.variant == null ? '' : ' · ${record!.variant!.name}'}';
}

class BakingComposition {
  const BakingComposition({
    required this.recipe,
    required this.root,
    this.components = const [],
    this.dependencies = const {},
  });
  final RecipeData recipe;
  final RecipeRecord root;
  final List<BakingComponent> components;
  final Map<int, Set<int>> dependencies;
}

class BakingComposer {
  BakingComposer(this.repository);
  final RecipeRepository repository;
  Future<List<PreparationOption>> options(RecipeData recipe) async {
    final result = <PreparationOption>[];
    for (final link in recipe.preparations) {
      try {
        result.add(
          PreparationOption(
            link: link,
            record: await repository.loadRecord(link.recipeId),
          ),
        );
      } on StateError {
        result.add(PreparationOption(link: link));
      } on FormatException {
        result.add(PreparationOption(link: link));
      } on TypeError {
        result.add(PreparationOption(link: link));
      }
    }
    return result;
  }

  Future<BakingComposition> resolve(
    RecipeRecord root,
    Set<int> selected,
  ) async {
    if (selected.isEmpty) return compile(root, const []);
    final records = await repository.loadBakingRecords(root.id, selected);
    return compile(records.first, records.skip(1).toList());
  }

  static BakingComposition compile(
    RecipeRecord root,
    List<RecipeRecord> preparations,
  ) {
    if (!root.recipe.bakingReady) throw const FormatException('preparations');
    if (preparations.isEmpty) {
      return BakingComposition(
        recipe: root.recipe.copy()..preparations.clear(),
        root: root,
      );
    }
    final byId = {for (final r in preparations) r.id: r};
    final selectedLinks = root.recipe.preparations
        .where((p) => byId.containsKey(p.recipeId))
        .toList();
    if (byId.length != preparations.length ||
        selectedLinks.length != preparations.length ||
        byId.containsKey(root.id)) {
      throw const FormatException('preparations');
    }
    final sources = [
      for (final link in selectedLinks) byId[link.recipeId]!,
      root,
    ];
    final compiled = RecipeData(
      name: root.recipe.name,
      description: root.recipe.description,
      image: root.recipe.image,
      notes: root.recipe.notes.map((n) => n.copy()).toList(),
    );
    final components = <BakingComponent>[];
    var next = 1;
    for (final record in sources) {
      if (!record.recipe.bakingReady) {
        throw const FormatException('preparations');
      }
      final ids = {
        for (final id in [
          ...record.recipe.ingredients.map((i) => i.id),
          ...record.recipe.stages.map((s) => s.id),
        ])
          id: next++,
      };
      final copy = record.recipe.copy();
      for (final ingredient in copy.ingredients) {
        ingredient.id = ids[ingredient.id]!;
      }
      for (final stage in copy.stages) {
        stage.id = ids[stage.id]!;
        for (final ref in stage.ingredients) {
          ref.id = ids[ref.id]!;
        }
      }
      compiled.ingredients.addAll(copy.ingredients);
      compiled.stages.addAll(copy.stages);
      components.add(
        BakingComponent(
          recipeId: record.id,
          name: record.family?.name ?? record.recipe.name,
          variantName: record.variant?.name ?? '',
          recipe: record.recipe,
          ids: ids,
          sharedNotes: record.family?.notes ?? const [],
        ),
      );
    }
    final dependencies = <int, Set<int>>{};
    final mainIds = components.last.ids;
    for (var i = 0; i < selectedLinks.length; i++) {
      final component = components[i];
      final used = component.recipe.stages
          .expand((s) => s.ingredients)
          .map((r) => r.id)
          .toSet();
      final terminals = component.recipe.stages
          .where((s) => !used.contains(s.id))
          .map((s) => component.ids[s.id]!);
      dependencies
          .putIfAbsent(mainIds[selectedLinks[i].stageId]!, () => {})
          .addAll(terminals);
    }
    return BakingComposition(
      recipe: compiled,
      root: root,
      components: components,
      dependencies: dependencies,
    );
  }
}
