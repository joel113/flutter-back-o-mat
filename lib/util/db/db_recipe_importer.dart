import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'db.dart';
import '../../recipe/data/recipe_data.dart';
import '../../recipe/data/recipe_repository.dart';

class RecipeJsonImporter {
  final dbHelper = DatabaseHelperJson();

  Future<void> importRecipesFromAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final recipeFiles = manifest
        .listAssets()
        .where((String key) => key.startsWith('assets/recipes/'))
        .where((String key) => key.endsWith('.json'))
        .toList();

    if (recipeFiles.isEmpty) {
      print("No recipe JSON files found in assets/recipes/");
      return;
    }

    for (String filePath in recipeFiles) {
      try {
        String jsonString = await rootBundle.loadString(filePath);
        Map<String, dynamic> tempJson = json.decode(jsonString);
        String recipeName = tempJson['name'];

        // Check if recipe already exists
        RecipeJsonEntry? existing = await dbHelper.getRecipeJsonByName(
          recipeName,
        );
        if (existing == null) {
          print("Importing $recipeName (JSON)...");
          await RecipeRepository().save(RecipeData.fromExternalJson(tempJson));
          print("$recipeName (JSON) imported successfully.");
        } else {
          print(
            "$recipeName (JSON) already exists. Skipping or implement update logic.",
          );
          // Optionally, update if the file is newer, etc.
        }
      } catch (e) {
        print("Error importing recipe (JSON) from $filePath: $e");
      }
    }
    print("All JSON recipes processed.");
  }
}
