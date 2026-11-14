import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/recipe_data.dart';
import 'recipe_editor.dart';
import 'scan_recipe.dart';
import 'recipe_file_import.dart';

Future<int?> addRecipe(BuildContext context) async {
  final s = AppLocalizations.of(context)!;
  final choice = await showModalBottomSheet<int>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(s.manualRecipe),
            onTap: () => Navigator.pop(context, 0),
          ),
          ListTile(
            leading: const Icon(Icons.file_open),
            title: Text(s.importJson),
            onTap: () => Navigator.pop(context, 1),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: Text(s.scanRecipe),
            onTap: () => Navigator.pop(context, 2),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice == 2) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const ScanRecipe()),
    );
  }
  var recipe = RecipeData();
  try {
    if (choice == 1) {
      final imported = await importRecipeFile(context);
      if (imported == null || !context.mounted) return null;
      recipe = imported;
    }
    if (!context.mounted) return null;
    return await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeEditor(
          recipe: recipe,
          notice: choice == 1 ? recipeImportNotice(s, recipe) : null,
        ),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.importError)));
    }
    return null;
  }
}
