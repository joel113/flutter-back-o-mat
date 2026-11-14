import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'package:flutter/foundation.dart' show debugPrint;

import '../../recipe/data/recipe_data.dart';
import '../../recipe/data/recipe_repository.dart';

class RecipeJsonImporter {
  RecipeJsonImporter({RecipeRepository? repository})
    : repository = repository ?? RecipeRepository();
  final RecipeRepository repository;

  Future<void> importRecipesFromAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final recipeFiles = manifest
        .listAssets()
        .where((String key) => key.startsWith('assets/recipes/'))
        .where((String key) => key.endsWith('.json'))
        .toList();

    if (recipeFiles.isEmpty) {
      debugPrint("No recipe JSON files found in assets/recipes/");
      return;
    }

    for (String filePath in recipeFiles) {
      try {
        String jsonString = await rootBundle.loadString(filePath);
        Map<String, dynamic> tempJson = json.decode(jsonString);
        String recipeName = tempJson['name'];

        final imported = await repository.importBundled(
          filePath,
          RecipeData.fromExternalJson(tempJson),
        );
        debugPrint(
          imported
              ? '$recipeName imported.'
              : '$recipeName already processed; skipping.',
        );
      } catch (e) {
        debugPrint("Error importing recipe (JSON) from $filePath: $e");
      }
    }
    debugPrint("All JSON recipes processed.");
  }
}
