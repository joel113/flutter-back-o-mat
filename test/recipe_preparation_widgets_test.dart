import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_family.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_preparations.dart';
import 'package:flutter_back_o_mat/baking/preparation_selection.dart';
import 'package:flutter_back_o_mat/baking/baking_view.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_component.dart';
import 'package:flutter_back_o_mat/planner/planner.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';

import 'app_style_test.dart' show styledApp;
import 'recipe_family_widgets_test.dart' show FamilyRecipes, route;
import 'recipe_preparation_test.dart' show starterRecipe;
import 'baking_view_test.dart' show MemoryBakes;
import 'baking_session_test.dart' show bakingRecipe;

class PreparationRecipes extends FamilyRecipes {
  PreparationRecipes() {
    data[1]!.preparations.add(RecipePreparation(recipeId: 2, stageId: 4));
    data[2] = starterRecipe();
    names[2] = 'Refresh';
  }
  bool loadFails = false;
  @override
  Future<RecipeRecord> loadRecord(int id) async {
    if (loadFails) throw Exception('database');
    if (!data.containsKey(id)) throw StateError('missing');
    return super.loadRecord(id);
  }

  @override
  Future<List<RecipeJsonEntry>> listFamilyEntries() async => [
    RecipeJsonEntry(
      id: 1,
      familyId: 1,
      variantCount: data.length,
      name: familyName,
      jsonData: jsonEncode(data[1]!.toJson()),
      lastModified: DateTime(2026),
    ),
  ];
  @override
  Future<List<RecipeRecord>> loadBakingRecords(
    int rootId,
    Set<int> selected,
  ) async => [
    await loadRecord(rootId),
    for (final id in selected) await loadRecord(id),
  ];
}

class PreparedBakes extends MemoryBakes {
  @override
  Future<BakingSession> openForRecipe(
    int recipeId,
    RecipeData recipe,
    DateTime start, {
    String? familyName,
    String? variantName,
    List<RecipeNote> sharedNotes = const [],
    Map<int, Set<int>> extraDependencies = const {},
    List<BakingComponent> components = const [],
  }) async =>
      await activeForRecipe(recipeId) ??
      await save(
        BakingSession(
          recipeId: recipeId,
          recipe: recipe,
          plannedStart: start,
          familyName: familyName,
          variantName: variantName,
          sharedNotes: sharedNotes,
          extraDependencies: extraDependencies,
          components: components,
        ),
      );
}

void main() {
  testWidgets(
    'editor attaches a specific variant to a consuming step and persists it',
    (tester) async {
      final repo = PreparationRecipes();
      final root = repo.data[1]!.copy()..preparations.clear();
      await tester.pumpWidget(
        styledApp(route(RecipeEditor(recipe: root, id: 1, repository: repo))),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final fields = find.byType(RecipePreparationsFields);
      await tester.ensureVisible(fields);
      await tester.tap(find.text('Attach preparation recipe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My sourdough · Refresh'));
      await tester.pumpAndSettle();
      final dropdown = find.descendant(
        of: fields,
        matching: find.byType(DropdownButtonFormField<int>),
      );
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dough').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repo.data[1]!.preparations.single.recipeId, 2);
      expect(repo.data[1]!.preparations.single.stageId, 4);
      expect(root.preparations, isEmpty);
    },
  );

  testWidgets(
    'removing the consuming step produces a repairable validation error',
    (tester) async {
      final repo = PreparationRecipes();
      final recipe = repo.data[1]!.copy()..stages.removeWhere((s) => s.id == 4);
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        styledApp(
          Scaffold(
            body: Form(
              key: form,
              child: RecipePreparationsFields(
                recipe: recipe,
                recipeId: 1,
                repository: repo,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.textContaining('Check preparation links:'), findsOneWidget);
    },
  );

  testWidgets(
    'choices default off, drafts and missing recipes are disabled, nested scope is explicit',
    (tester) async {
      final repo = PreparationRecipes();
      repo.data[3] = RecipeData(name: 'Draft');
      repo.names[3] = 'Draft';
      repo.data[1]!.preparations.addAll([
        RecipePreparation(recipeId: 3, stageId: 2),
        RecipePreparation(recipeId: 999, stageId: 2),
      ]);
      repo.data[2]!.preparations.add(
        RecipePreparation(recipeId: 3, stageId: 2),
      );
      Set<int>? result;
      await tester.pumpWidget(
        styledApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await selectPreparations(
                    context,
                    repo.data[1]!,
                    repo,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final ready = find.byKey(const ValueKey('preparation-2'));
      expect(tester.widget<CheckboxListTile>(ready).value, isFalse);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('preparation-3')),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('preparation-999')),
            )
            .onChanged,
        isNull,
      );
      expect(find.textContaining('Those are not included'), findsOneWidget);
      await tester.tap(ready);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(result, {2});
    },
  );

  testWidgets(
    'planner creates a composed session and cancellation creates none',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = PreparationRecipes(), bakes = MemoryBakes();
      await tester.pumpWidget(
        styledApp(
          BackomatPlanner(
            repository: bakes,
            recipeRepository: repo,
            loadRecipes: () async => [
              RecipeJsonEntry(
                id: 1,
                name: 'Bread',
                jsonData: jsonEncode(repo.data[1]!.toJson()),
                lastModified: DateTime(2026),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> begin() async {
        await tester.tap(find.text('Plan a bake'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bread'));
        await tester.pumpAndSettle();
      }

      await begin();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(await bakes.list(), isEmpty);
      await begin();
      await tester.tap(find.byKey(const ValueKey('preparation-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final saved = (await bakes.list()).single;
      expect(saved.components.length, 2);
      expect(saved.extraDependencies, isNotEmpty);
      final consumer = saved.components.last.ids[4]!;
      expect(
        tester
            .widget<FilledButton>(find.byKey(ValueKey('start-$consumer')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Refresh'), findsWidgets);
      expect(find.byType(Table), findsOneWidget);
    },
  );

  testWidgets(
    'direct baking setup composes only selected preparations and cancellation leaves no bake',
    (tester) async {
      final repo = PreparationRecipes(), bakes = PreparedBakes();
      await tester.pumpWidget(
        styledApp(
          route(
            BakingEntry(
              recipeId: 1,
              recipe: repo.data[1]!,
              repository: bakes,
              recipeRepository: repo,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(PreparationSelection), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(await bakes.list(), isEmpty);
      expect(find.text('Open'), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('preparation-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(BakingView), findsOneWidget);
      expect((await bakes.list()).single.components.length, 2);
    },
  );

  testWidgets('opening an unfinished bake resumes its snapshot without setup', (
    tester,
  ) async {
    final repo = PreparationRecipes(), bakes = MemoryBakes();
    await bakes.save(
      BakingSession(
        recipeId: 1,
        recipe: bakingRecipe(),
        plannedStart: DateTime(2026),
      ),
    );
    await tester.pumpWidget(
      styledApp(
        BakingEntry(
          recipeId: 1,
          recipe: repo.data[1]!,
          repository: bakes,
          recipeRepository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PreparationSelection), findsNothing);
    expect(find.byType(BakingView), findsOneWidget);
    expect((await bakes.list()).length, 1);
  });

  testWidgets('setup load failure offers retry without creating a session', (
    tester,
  ) async {
    final repo = PreparationRecipes()..loadFails = true;
    await tester.pumpWidget(
      styledApp(PreparationSelection(recipe: repo.data[1]!, repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load preparation recipes.'), findsOneWidget);
    repo.loadFails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preparation-2')), findsOneWidget);
  });

  for (final locale in ['en', 'de']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('preparation UI fits narrow $locale $mode', (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = PreparationRecipes();
        await tester.pumpWidget(
          styledApp(
            PreparationSelection(recipe: repo.data[1]!, repository: repo),
            locale: Locale(locale),
            mode: mode,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('preparation-2')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          styledApp(
            RecipeEditor(recipe: repo.data[1]!, id: 1, repository: repo),
            locale: Locale(locale),
            mode: mode,
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(RecipePreparationsFields));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
