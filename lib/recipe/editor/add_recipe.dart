import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/recipe_data.dart';
import 'recipe_editor.dart';
import 'scan_recipe.dart';

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
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            extensions: ['json', 'jsonld'],
            uniformTypeIdentifiers: ['public.json'],
          ),
        ],
      );
      if (file == null || !context.mounted) return null;
      if (await file.length() > 2 * 1024 * 1024) {
        throw const FormatException('size');
      }
      final recipes = RecipeImport.parse(await file.readAsString());
      if (!context.mounted) return null;
      if (recipes.length == 1) {
        recipe = recipes.single;
      } else {
        final selected = await showDialog<RecipeData>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(s.selectRecipe),
            children: [
              for (final recipe in recipes)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, recipe),
                  child: Text(recipe.name),
                ),
            ],
          ),
        );
        if (selected == null || !context.mounted) return null;
        recipe = selected;
      }
      // Local images belong to this installation and cannot be imported by name.
      if (recipe.image?.startsWith('local:') ?? false) recipe.image = null;
    }
    if (!context.mounted) return null;
    return await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeEditor(
          recipe: recipe,
          notice: choice == 1
              ? [
                  s.jsonReview,
                  if (recipe.importedPreparationsRemoved)
                    s.preparationsImportRemoved,
                ].join('\n\n')
              : null,
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
