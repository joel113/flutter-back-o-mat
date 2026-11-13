import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_repository.dart';
import 'package:flutter_back_o_mat/baking/baking_view.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/planner/planner.dart';
import 'package:flutter_back_o_mat/recipe/stage/stage_date.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';

import 'baking_session_test.dart' show bakingRecipe;

class MemoryBakes extends BakingRepository {
  final sessions = <int, BakingSession>{};
  int nextId = 1;
  bool failSave = false;
  bool failLoad = false;
  @override
  Future<List<BakingSession>> list() async {
    if (failLoad) throw StateError('unavailable');
    return sessions.values.map((s) => s.copy()).toList();
  }

  @override
  Future<BakingSession> load(int id) async {
    if (failLoad || !sessions.containsKey(id)) throw StateError('unavailable');
    return sessions[id]!.copy();
  }

  @override
  Future<BakingSession> save(BakingSession session) async {
    if (failSave) throw StateError('disk full');
    final copy = session.copy()..id = session.id ?? nextId++;
    sessions[copy.id!] = copy;
    return copy.copy();
  }

  @override
  Future<void> delete(int id) async {
    sessions.remove(id);
  }
}

Widget app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
void largeWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'countdown persists on exit, reopens accurately, pauses and unlocks stages',
    (tester) async {
      largeWindow(tester);
      final repository = MemoryBakes();
      var now = DateTime(2026, 11, 7, 8);
      final saved = await repository.save(
        BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now),
      );
      await tester.pumpWidget(
        app(
          BakingView(
            sessionId: saved.id!,
            repository: repository,
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('start-4')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('start-2')));
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:50:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      now = now.add(const Duration(minutes: 10));
      await tester.pumpWidget(
        app(
          BakingView(
            sessionId: saved.id!,
            repository: repository,
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('00:40:00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause-2')));
      await tester.pumpAndSettle();
      now = now.add(const Duration(hours: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:40:00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('resume-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('done-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('done-3')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('start-4')))
            .onPressed,
        isNotNull,
      );
      expect(
        (await repository.load(saved.id!)).progress[2]!.status,
        BakeStepStatus.completed,
      );
      await tester.pumpWidget(
        const SizedBox(),
      ); // cancels the view's repaint timer
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed progress save retains previous saved state and allows retry',
    (tester) async {
      largeWindow(tester);
      final repository = MemoryBakes();
      final now = DateTime(2026, 11, 7, 8);
      final saved = await repository.save(
        BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now),
      );
      repository.failSave = true;
      await tester.pumpWidget(
        app(
          BakingView(
            sessionId: saved.id!,
            repository: repository,
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-2')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save the baking session.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('start-2')), findsOneWidget);
      repository.failSave = false;
      await tester.tap(find.byKey(const ValueKey('start-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pause-2')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'planner shows persisted sessions and safely removes only a session',
    (tester) async {
      largeWindow(tester);
      final repository = MemoryBakes();
      final now = DateTime(2026, 11, 7, 8);
      await repository.save(
        BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now),
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: BackomatPlanner(
              repository: repository,
              loadRecipes: () async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove baking session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repository.list()).length, 1);
      await tester.tap(find.byTooltip('Remove baking session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove baking session'));
      await tester.pumpAndSettle();
      expect(await repository.list(), isEmpty);
      expect(find.textContaining('No baking sessions yet.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'planner selects a real recipe and cancels planning without creating a session',
    (tester) async {
      largeWindow(tester);
      final repository = MemoryBakes();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: BackomatPlanner(
              repository: repository,
              loadRecipes: () async => [
                RecipeJsonEntry(
                  id: 7,
                  name: 'Bread',
                  jsonData: jsonEncode(bakingRecipe().toJson()),
                  lastModified: DateTime(2026),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan a bake'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a recipe'), findsOneWidget);
      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repository.list(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'legacy date picker opens with the saved date without a null cast',
    (tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StageDate(initialDateTime: DateTime(2026, 11, 7, 10, 30)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'planner creates a separate saved bake after date and time selection',
    (tester) async {
      largeWindow(tester);
      final repository = MemoryBakes();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: BackomatPlanner(
              repository: repository,
              loadRecipes: () async => [
                RecipeJsonEntry(
                  id: 7,
                  name: 'Bread',
                  jsonData: jsonEncode(bakingRecipe().toJson()),
                  lastModified: DateTime(2026),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan a bake'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(BakingView), findsOneWidget);
      expect((await repository.list()).single.recipe.name, 'Bread');
      expect(find.byType(Table), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('chosen duration is range-checked and saved for this bake only', (
    tester,
  ) async {
    largeWindow(tester);
    final repository = MemoryBakes();
    final now = DateTime(2026, 11, 7, 8);
    final saved = await repository.save(
      BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now),
    );
    await tester.pumpWidget(
      app(
        BakingView(
          sessionId: saved.id!,
          repository: repository,
          clock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('duration-2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose whole minutes within the recipe’s duration range.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '90');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final updated = await repository.load(saved.id!);
    expect(updated.progress[2]!.durationMinutes, 90);
    expect(updated.recipe.stages.first.durationMin, 60);
    expect(
      updated.schedule(now)[4]!.start,
      now.add(const Duration(minutes: 90)),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
