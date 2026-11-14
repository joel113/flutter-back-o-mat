import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_file_import.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_view.dart';

import 'app_style_test.dart' show styledApp;
import 'recipe_family_widgets_test.dart' show FamilyRecipes;

class ManagingRecipes extends FamilyRecipes {
  int imported = 0;
  int deleted = 0;
  bool blocked = false;
  @override
  Future<int> importVariant(
    int familyId,
    String name,
    RecipeData recipe,
  ) async {
    if (names.values.any((n) => n.toLowerCase() == name.trim().toLowerCase())) {
      throw const FormatException('duplicateVariant');
    }
    if (this.fail) throw StateError('disk');
    final id = data.length + 1;
    data[id] = recipe.copy();
    names[id] = name.trim();
    imported++;
    return id;
  }

  @override
  Future<int> deleteVariant(int recipeId, {int? replacementId}) async {
    if (blocked) throw const VariantDeletionBlocked(['Bread needing starter']);
    if (this.fail) throw StateError('disk');
    data.remove(recipeId);
    names.remove(recipeId);
    if (this.main == recipeId) this.main = replacementId!;
    deleted++;
    return this.main;
  }
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> openVariants(
  WidgetTester tester,
  ManagingRecipes repo, {
  RecipeData? imported,
}) async {
  await tester.pumpWidget(
    styledApp(
      RecipeView(id: 1, repository: repo, importFile: (_) async => imported),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Variants'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'file variant is reviewed before saving and duplicate names can be corrected',
    (tester) async {
      final repo = ManagingRecipes();
      await openVariants(
        tester,
        repo,
        imported: RecipeData(name: 'Imported bread'),
      );
      await tester.tap(find.text('Import variant from file'));
      await tester.pumpAndSettle();
      expect(find.byType(RecipeEditor), findsOneWidget);
      expect(repo.imported, 0);
      await tester.enterText(field('Variant name'), 'Standard');
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Choose a non-empty variant name that is unique within this bread.',
        ),
        findsOneWidget,
      );
      expect(repo.imported, 0);
      await tester.enterText(field('Variant name'), 'File version');
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repo.imported, 1);
      expect(repo.main, 1);
      expect(repo.names[3], 'File version');
      expect(repo.data[1]!.name, 'Bread');
      expect(repo.data[3]!.name, 'Imported bread');
    },
  );

  testWidgets(
    'file picker cancellation and discarding an imported draft create no variant',
    (tester) async {
      final repo = ManagingRecipes();
      await openVariants(tester, repo);
      await tester.tap(find.text('Import variant from file'));
      await tester.pumpAndSettle();
      expect(find.byType(RecipeEditor), findsNothing);
      expect(repo.imported, 0);
      await tester.pumpWidget(const SizedBox());
      await openVariants(
        tester,
        repo,
        imported: RecipeData(name: 'Discard me'),
      );
      await tester.tap(find.text('Import variant from file'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(repo.imported, 0);
      expect(repo.data.length, 2);
    },
  );

  testWidgets('deleting a secondary variant requires confirmation', (
    tester,
  ) async {
    final repo = ManagingRecipes();
    await openVariants(tester, repo);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overnight').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete variant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.deleted, 0);
    await tester.tap(find.widgetWithText(TextButton, 'Delete variant'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete variant'));
    await tester.pumpAndSettle();
    expect(repo.deleted, 1);
    expect(repo.main, 1);
    expect(repo.names.containsKey(2), isFalse);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Delete variant'))
          .onPressed,
      isNull,
    );
    expect(
      find.byTooltip('At least one variant must remain in this bread family.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'main deletion selects a replacement; referenced variants explain the blocker',
    (tester) async {
      final repo = ManagingRecipes()..blocked = true;
      await openVariants(tester, repo);
      await tester.tap(find.widgetWithText(TextButton, 'Delete variant'));
      await tester.pumpAndSettle();
      expect(find.text('New main variant'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete variant'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bread needing starter'), findsOneWidget);
      expect(repo.deleted, 0);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      repo.blocked = false;
      await tester.tap(find.widgetWithText(TextButton, 'Delete variant'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete variant'));
      await tester.pumpAndSettle();
      expect(repo.main, 2);
      expect(repo.deleted, 1);
      expect(repo.names.containsKey(1), isFalse);
    },
  );

  testWidgets('delete failure retains the selected variant and permits retry', (
    tester,
  ) async {
    final repo = ManagingRecipes()..fail = true;
    await openVariants(tester, repo);
    await tester.tap(find.widgetWithText(TextButton, 'Delete variant'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete variant'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not delete the variant. Nothing was changed.'),
      findsOneWidget,
    );
    expect(repo.names.length, 2);
    expect(repo.main, 1);
  });

  testWidgets(
    'shared file chooser supports selecting a recipe from a multi-recipe file',
    (tester) async {
      RecipeData? result;
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode('[{"name":"First"},{"name":"Second"}]')),
        name: 'recipes.json',
      );
      await tester.pumpWidget(
        styledApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await importRecipeFile(
                    context,
                    pickFile: () async => file,
                  );
                },
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(result!.name, 'Second');
    },
  );

  for (final locale in ['en', 'de']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'variant actions and deletion dialog fit narrow $locale $mode',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = ManagingRecipes();
          await tester.pumpWidget(
            styledApp(
              RecipeView(id: 1, repository: repo),
              locale: Locale(locale),
              mode: mode,
            ),
          );
          await tester.pumpAndSettle();
          final s = AppLocalizations.of(
            tester.element(find.byType(RecipeView)),
          )!;
          await tester.tap(find.text(s.variantsLabel));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.widgetWithText(TextButton, s.deleteVariant),
          );
          await tester.tap(find.widgetWithText(TextButton, s.deleteVariant));
          await tester.pumpAndSettle();
          expect(find.text(s.newMainVariant), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
