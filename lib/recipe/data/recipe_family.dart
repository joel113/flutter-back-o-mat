import 'recipe_data.dart';

class RecipeVariant {
  const RecipeVariant({
    required this.id,
    required this.name,
    required this.recipe,
  });
  final int id;
  final String name;
  final RecipeData recipe;
}

class RecipeFamily {
  const RecipeFamily({
    required this.id,
    required this.name,
    required this.mainRecipeId,
    required this.notes,
    required this.variants,
  });
  final int id;
  final String name;
  final int mainRecipeId;
  final List<RecipeNote> notes;
  final List<RecipeVariant> variants;
}

class RecipeRecord {
  const RecipeRecord({required this.id, required this.recipe, this.family});
  final int id;
  final RecipeData recipe;
  final RecipeFamily? family;
  RecipeVariant? get variant =>
      family?.variants.where((v) => v.id == id).firstOrNull;
}

class RecipeRevision {
  const RecipeRevision({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.content,
  });
  final int id;
  final DateTime createdAt;
  final String description;
  final String content;
}
