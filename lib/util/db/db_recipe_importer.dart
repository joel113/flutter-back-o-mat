import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'db.dart';

class RecipeJsonImporter {
  final dbHelper = DatabaseHelperJson();

  Future<void> importRecipesFromAssets() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final recipeFiles = manifestMap.keys
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
        int id = tempJson['id'];
        String recipeName = tempJson['name'];

        // Check if recipe already exists
        RecipeJsonEntry? existing = await dbHelper.getRecipeJsonByName(recipeName);
        if (existing == null) {
          print("Importing $recipeName (JSON)...");
          await dbHelper.insertRecipeJson(id, recipeName, jsonString);
          print("$recipeName (JSON) imported successfully.");
        } else {
          print("$recipeName (JSON) already exists. Skipping or implement update logic.");
          // Optionally, update if the file is newer, etc.
          // await dbHelper.updateRecipeJson(existing.id!, recipeName, jsonString);
        }

      } catch (e) {
        print("Error importing recipe (JSON) from $filePath: $e");
      }
    }
    print("All JSON recipes processed.");
  }
}