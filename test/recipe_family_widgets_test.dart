import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_family.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_view.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_notes.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_history.dart';
import 'package:flutter_back_o_mat/planner/planner.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';

import 'app_style_test.dart' show styledApp;
import 'baking_session_test.dart' show bakingRecipe;
import 'baking_view_test.dart' show MemoryBakes;

class FamilyRecipes extends RecipeRepository {
  final data = <int, RecipeData>{1: bakingRecipe(), 2: bakingRecipe()};
  final names = <int, String>{1: 'Standard', 2: 'Overnight'};
  int main = 1;
  bool fail = false;
  String familyName = 'My sourdough';
  List<RecipeNote> shared = [RecipeNote(title: 'Handling', body: 'Wet hands')];
  int restores = 0;
  @override
  Future<RecipeData> load(int id) async => data[id]!.copy();
  @override
  Future<RecipeFamily> loadFamily(int id) async => RecipeFamily(
    id: 1,
    name: familyName,
    mainRecipeId: main,
    notes: shared.map((n) => n.copy()).toList(),
    variants: [
      for (final e in data.entries)
        RecipeVariant(id: e.key, name: names[e.key]!, recipe: e.value.copy()),
    ],
  );
  @override
  Future<RecipeRecord> loadRecord(int id) async =>
      RecipeRecord(id: id, recipe: await load(id), family: await loadFamily(1));
  @override
  Future<bool> hasDuplicateName(String name, {int? exceptId}) async => false;
  @override
  Future<int> save(
    RecipeData recipe, {
    int? id,
    String changeDescription = '',
  }) async {
    if (fail) throw StateError('disk');
    final key = id ?? 3;
    data[key] = recipe.copy();
    return key;
  }

  @override
  Future<int> createVariant(int sourceId, String name) async {
    if (names.values.any((n) => n.toLowerCase() == name.trim().toLowerCase())) {
      throw const FormatException();
    }
    final id = data.length + 1;
    data[id] = data[sourceId]!.copy();
    names[id] = name.trim();
    return id;
  }

  @override
  Future<void> setMainVariant(int familyId, int recipeId) async =>
      main = recipeId;
  @override
  Future<void> renameFamily(int familyId, String name) async =>
      familyName = name;
  @override
  Future<void> saveSharedNotes(
    int familyId,
    List<RecipeNote> notes, {
    String changeDescription = '',
  }) async {
    if (fail) throw StateError('disk');
    shared = notes.map((n) => n.copy()).toList();
  }

  @override
  Future<List<RecipeRevision>> revisions(
    int ownerId, {
    bool sharedNotes = false,
  }) async => [
    RecipeRevision(
      id: 1,
      createdAt: DateTime(2026, 11, 12),
      description: 'Earlier recipe',
      content: sharedNotes
          ? jsonEncode(shared.map((n) => n.toJson()).toList())
          : jsonEncode(data[ownerId]!.toJson()),
    ),
  ];
  @override
  Future<void> restore(
    int ownerId,
    int revisionId, {
    bool sharedNotes = false,
    String changeDescription = '',
  }) async {
    if (fail) throw StateError('disk');
    restores++;
  }
}

Widget route(Widget child) => Scaffold(
  body: Builder(
    builder: (context) => TextButton(
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => child),
      ),
      child: const Text('Open'),
    ),
  ),
);

void main() {
  testWidgets(
    'family switches, duplicate creation stays editable, and main selection persists',
    (tester) async {
      final repo = FamilyRecipes();
      await tester.pumpWidget(styledApp(RecipeView(id: 1, repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Create variant').hitTestable(), findsNothing);
      final variants = find.byKey(const ValueKey('recipe-variants'));
      expect(
        tester.getTopLeft(find.text('Bread')).dy,
        lessThan(tester.getTopLeft(variants).dy),
      );
      expect(
        tester.getBottomRight(variants).dy,
        lessThan(tester.getTopLeft(find.text('Notes')).dy),
      );
      await tester.tap(find.text('Variants'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Overnight').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use as main variant'));
      await tester.pumpAndSettle();
      expect(repo.main, 2);
      await tester.tap(find.text('Create variant'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Standard');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Choose a non-empty variant name that is unique within this bread.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField), 'Less yeast');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(repo.names[3], 'Less yeast');
      expect(find.text('Less yeast'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'variant notes reorder with their text and save without changing the source',
    (tester) async {
      final repo = FamilyRecipes();
      final source = RecipeData(
        name: 'Draft',
        notes: [
          RecipeNote(title: 'A', body: 'First'),
          RecipeNote(title: 'B', body: 'Second'),
        ],
      );
      await tester.pumpWidget(
        styledApp(route(RecipeEditor(recipe: source, id: 1, repository: repo))),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final fields = find.byType(RecipeNotesFields);
      await tester.ensureVisible(fields);
      await tester.tap(
        find
            .descendant(of: fields, matching: find.byTooltip('Move down'))
            .first,
      );
      await tester.pumpAndSettle();
      final body = find
          .descendant(of: fields, matching: find.byType(TextFormField))
          .at(1);
      await tester.ensureVisible(body);
      await tester.enterText(body, 'Changed second');
      expect(source.notes.first.title, 'A');
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repo.data[1]!.notes.first.title, 'B');
      expect(repo.data[1]!.notes.first.body, 'Changed second');
    },
  );

  testWidgets(
    'shared note save failure and discard confirmation preserve edits',
    (tester) async {
      final repo = FamilyRecipes()..fail = true;
      await tester.pumpWidget(
        styledApp(
          route(
            SharedNotesEditor(
              familyId: 1,
              notes: repo.shared,
              repository: repo,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Use oil');
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save the recipe. Your changes are still here.'),
        findsOneWidget,
      );
      expect(repo.shared.single.body, 'Wet hands');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Use oil'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Save notes'));
      await tester.pumpAndSettle();
      expect(repo.shared.single.body, 'Use oil');
    },
  );

  testWidgets(
    'revision preview is read only, confirms restore, and handles write errors',
    (tester) async {
      final repo = FamilyRecipes()..fail = true;
      await tester.pumpWidget(
        styledApp(RecipeHistory(ownerId: 1, repository: repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Earlier recipe'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Edit recipe'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Baking stages'), findsOneWidget);
      await tester.tap(find.text('Restore revision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.restores, 0);
      await tester.tap(find.text('Restore revision'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Restore revision'));
      await tester.pumpAndSettle();
      expect(find.text('Revision preview'), findsOneWidget);
      expect(repo.restores, 0);
      repo.fail = false;
      await tester.tap(find.widgetWithText(TextButton, 'Restore revision'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Restore revision'));
      await tester.pumpAndSettle();
      expect(repo.restores, 1);
      expect(find.text('Revision history'), findsOneWidget);
    },
  );

  testWidgets(
    'planner defaults to main and saves the chosen variant and shared notes',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FamilyRecipes();
      final bakes = MemoryBakes();
      await tester.pumpWidget(
        styledApp(
          BackomatPlanner(
            repository: bakes,
            recipeRepository: repo,
            loadRecipes: () async => [
              RecipeJsonEntry(
                id: 1,
                name: 'My sourdough',
                jsonData: jsonEncode(repo.data[1]!.toJson()),
                lastModified: DateTime(2026),
                familyId: 1,
                variantCount: 2,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan a bake'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My sourdough'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .value,
        1,
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Overnight').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Plan a bake').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final saved = (await bakes.list()).single;
      expect(saved.recipeId, 2);
      expect(saved.variantName, 'Overnight');
      expect(saved.familyName, 'My sourdough');
      expect(saved.sharedNotes.single.body, 'Wet hands');
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.text('Wet hands'), findsOneWidget);
      expect(find.text('Edit shared notes'), findsNothing);
    },
  );

  for (final locale in ['en', 'de']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('narrow $locale $mode family and notes layouts', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FamilyRecipes();
        await tester.pumpWidget(
          styledApp(
            RecipeView(id: 1, repository: repo),
            locale: Locale(locale),
            mode: mode,
          ),
        );
        await tester.pumpAndSettle();
        final s = AppLocalizations.of(tester.element(find.byType(RecipeView)))!;
        await tester.ensureVisible(find.text(s.notesLabel));
        await tester.tap(find.text(s.notesLabel));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(s.editSharedNotes));
        await tester.tap(find.text(s.editSharedNotes));
        await tester.pumpAndSettle();
        expect(find.byType(SharedNotesEditor), findsOneWidget);
        expect(find.text('Wet hands'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
