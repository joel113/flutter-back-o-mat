import 'package:flutter/material.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_family.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_view.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRecipes extends RecipeRepository {
  RecipeData? saved;
  bool fail = false;
  bool duplicate = false;
  bool missing = false;
  int? updatedId;
  @override
  Future<RecipeData> load(int id) async {
    if (missing) throw StateError('missing');
    return saved?.copy() ?? RecipeData(name: 'Incomplete bread');
  }

  @override
  Future<RecipeRecord> loadRecord(int id) async =>
      RecipeRecord(id: id, recipe: await load(id));

  @override
  Future<bool> hasDuplicateName(String name, {int? exceptId}) async =>
      duplicate;
  @override
  Future<int> save(
    RecipeData recipe, {
    int? id,
    String changeDescription = '',
  }) async {
    if (fail) throw StateError('disk full');
    saved = recipe.copy();
    updatedId = id;
    return id ?? 42;
  }
}

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: home,
);
Widget editorApp(MemoryRecipes repository, {RecipeData? recipe, int? id}) =>
    app(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeEditor(
                  recipe: recipe ?? RecipeData(),
                  id: id,
                  repository: repository,
                ),
              ),
            ),
            child: const Text('Open editor'),
          ),
        ),
      ),
    );
Future<void> open(
  WidgetTester tester,
  MemoryRecipes repository, {
  RecipeData? recipe,
  int? id,
}) async {
  await tester.pumpWidget(editorApp(repository, recipe: recipe, id: id));
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('manual recipe requires name, then saves a draft', (
    tester,
  ) async {
    final repository = MemoryRecipes();
    await open(tester, repository);
    await tester.tap(find.byKey(const ValueKey('saveRecipe')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a recipe name.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'New bread');
    await tester.tap(find.byKey(const ValueKey('saveRecipe')));
    await tester.pumpAndSettle();
    expect(repository.saved!.name, 'New bread');
    expect(repository.saved!.bakingReady, isFalse);
    expect(find.text('Open editor'), findsOneWidget);
  });
  testWidgets('save failure preserves edits and succeeds on retry', (
    tester,
  ) async {
    final repository = MemoryRecipes()..fail = true;
    await open(tester, repository);
    await tester.enterText(find.byType(TextFormField).first, 'Keep me');
    await tester.tap(find.byKey(const ValueKey('saveRecipe')));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save the recipe. Your changes are still here.'),
      findsOneWidget,
    );
    expect(find.text('Keep me'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.byKey(const ValueKey('saveRecipe')));
    await tester.pumpAndSettle();
    expect(repository.saved!.name, 'Keep me');
  });
  testWidgets(
    'editing uses existing ID and copies rather than mutates source',
    (tester) async {
      final repository = MemoryRecipes();
      final source = RecipeData(name: 'Old name');
      await open(tester, repository, recipe: source, id: 7);
      await tester.enterText(find.byType(TextFormField).first, 'Edited');
      expect(source.name, 'Old name');
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repository.updatedId, 7);
      expect(repository.saved!.name, 'Edited');
    },
  );
  testWidgets(
    'duplicate-name warning and unsaved-change confirmation preserve work',
    (tester) async {
      final repository = MemoryRecipes()..duplicate = true;
      await open(tester, repository);
      await tester.enterText(find.byType(TextFormField).first, 'Bread');
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Save another'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.saved, isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open editor'), findsOneWidget);
    },
  );
  testWidgets(
    'incomplete recipe opens in detail and baking views without exception',
    (tester) async {
      for (final baking in [false, true]) {
        await tester.pumpWidget(
          app(
            RecipeView(
              key: ValueKey(baking),
              id: 2,
              baking: baking,
              repository: MemoryRecipes(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No ingredients entered yet.'), findsOneWidget);
        expect(find.text('No baking stages entered yet.'), findsOneWidget);
        expect(find.byTooltip('Edit recipe'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('missing recipe has a retry state', (tester) async {
    final repository = MemoryRecipes()..missing = true;
    await tester.pumpWidget(app(RecipeView(id: 55, repository: repository)));
    await tester.pumpAndSettle();
    expect(
      find.text('The recipe could not be found or loaded.'),
      findsOneWidget,
    );
    repository.missing = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Incomplete bread'), findsNWidgets(2));
  });
  testWidgets(
    'removing a referenced ingredient shows validation instead of crashing',
    (tester) async {
      final repository = MemoryRecipes();
      final data = RecipeData(
        name: 'Bread',
        ingredients: [RecipeIngredient(id: 1, name: 'Flour')],
        stages: [
          RecipeStage(
            id: 2,
            name: 'Mix',
            ingredients: [IngredientReference(id: 1)],
          ),
        ],
      );
      await open(tester, repository, recipe: data);
      final remove = find.byTooltip('Remove').first;
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repository.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('imported drafts prompt before being discarded', (tester) async {
    await open(
      tester,
      MemoryRecipes(),
      recipe: RecipeData(name: 'Imported draft'),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
  });
}
