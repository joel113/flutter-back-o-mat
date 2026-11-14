import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/recipe_data.dart';

const recipeFileLimit = 2 * 1024 * 1024;

Future<List<RecipeData>> readRecipeFile(XFile file) async {
  if (await file.length() > recipeFileLimit) {
    throw const FormatException('size');
  }
  final bytes = await file.readAsBytes();
  if (bytes.length > recipeFileLimit) throw const FormatException('size');
  final recipes = RecipeImport.parse(utf8.decode(bytes));
  for (final recipe in recipes) {
    // Imported files cannot claim an image owned by this installation.
    if (recipe.image?.startsWith('local:') ?? false) recipe.image = null;
  }
  return recipes;
}

Future<RecipeData?> importRecipeFile(
  BuildContext context, {
  Future<XFile?> Function()? pickFile,
}) async {
  final s = AppLocalizations.of(context)!;
  try {
    final file =
        await (pickFile ??
            () => openFile(
              acceptedTypeGroups: [
                const XTypeGroup(
                  extensions: ['json', 'jsonld'],
                  uniformTypeIdentifiers: ['public.json'],
                ),
              ],
            ))();
    if (file == null || !context.mounted) return null;
    final recipes = await readRecipeFile(file);
    if (!context.mounted) return null;
    if (recipes.length == 1) return recipes.single;
    return await showDialog<RecipeData>(
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
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.importError)));
    }
    return null;
  }
}

String recipeImportNotice(AppLocalizations s, RecipeData recipe) => [
  s.jsonReview,
  if (recipe.importedPreparationsRemoved) s.preparationsImportRemoved,
].join('\n\n');
