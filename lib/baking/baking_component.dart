import '../recipe/data/recipe_data.dart';

/// Immutable-in-use provenance for one recipe inside a composed baking session.
class BakingComponent {
  BakingComponent({
    required this.recipeId,
    required this.name,
    required this.variantName,
    required RecipeData recipe,
    required Map<int, int> ids,
    List<RecipeNote> sharedNotes = const [],
  }) : recipe = recipe.copy(),
       ids = Map.of(ids),
       sharedNotes = sharedNotes.map((n) => n.copy()).toList();
  final int recipeId;
  final String name;
  final String variantName;
  final RecipeData recipe;
  final Map<int, int> ids;
  final List<RecipeNote> sharedNotes;
  String get label => variantName.isEmpty ? name : '$name · $variantName';
  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'name': name,
    'variantName': variantName,
    'recipe': recipe.toJson(),
    'ids': {for (final e in ids.entries) '${e.key}': e.value},
    'sharedNotes': sharedNotes.map((n) => n.toJson()).toList(),
  };
  factory BakingComponent.fromJson(Map<String, dynamic> json) =>
      BakingComponent(
        recipeId: json['recipeId'] as int,
        name: json['name'] as String,
        variantName: json['variantName'] as String,
        recipe: RecipeData.fromJson(
          Map<String, dynamic>.from(json['recipe'] as Map),
        ),
        ids: {
          for (final e in (json['ids'] as Map).entries)
            int.parse(e.key as String): e.value as int,
        },
        sharedNotes: (json['sharedNotes'] as List? ?? [])
            .map(
              (n) => RecipeNote.fromJson(Map<String, dynamic>.from(n as Map)),
            )
            .toList(),
      );
}
