import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_view.dart';

import 'baking_session_test.dart' show bakingRecipe;
import 'baking_view_test.dart' show MemoryBakes;
import 'app_style_test.dart' show styledApp;

void main() {
  final planned = DateTime(2026, 11, 14, 8);
  test('planned start immediately credits elapsed time and survives reopening and pause', () {
    final bake = BakingSession(
      recipeId: 1,
      recipe: bakingRecipe(),
      plannedStart: planned,
    );
    final now = planned.add(const Duration(minutes: 20));
    bake.startPlanned(2, now);
    expect(bake.progress[2]!.startedAt, planned);
    expect(bake.progress[2]!.deadline, planned.add(const Duration(hours: 1)));
    expect(
      bake.copy().progress[2]!.remaining(now),
      const Duration(minutes: 40),
    );
    bake.pause(2, now);
    final later = now.add(const Duration(hours: 2));
    bake.resume(2, later);
    expect(bake.progress[2]!.remaining(later), const Duration(minutes: 40));
    expect(bake.progress[2]!.startedAt, planned);
  });

  test('per-step start overrides and selected durations are respected', () {
    final bake = BakingSession(
      recipeId: 1,
      recipe: bakingRecipe(),
      plannedStart: planned,
    );
    bake.setDuration(2, 90);
    bake.setStepStart(2, planned.add(const Duration(minutes: 10)));
    final now = planned.add(const Duration(minutes: 30));
    bake.startPlanned(2, now);
    expect(bake.progress[2]!.remaining(now), const Duration(minutes: 70));
    expect(
      bake.progress[2]!.startedAt,
      planned.add(const Duration(minutes: 10)),
    );
  });

  test('future plans start now when explicitly started early', () {
    final bake = BakingSession(
      recipeId: 1,
      recipe: bakingRecipe(),
      plannedStart: planned.add(const Duration(hours: 2)),
    );
    bake.startPlanned(2, planned);
    expect(bake.progress[2]!.startedAt, planned);
    expect(bake.progress[2]!.remaining(planned), const Duration(hours: 1));
  });

  test(
    'elapsed durations remain overdue and do not automatically complete steps',
    () {
      final bake = BakingSession(
        recipeId: 1,
        recipe: bakingRecipe(),
        plannedStart: planned,
      );
      final now = planned.add(const Duration(minutes: 75));
      bake.startPlanned(2, now);
      expect(bake.progress[2]!.remaining(now), const Duration(minutes: -15));
      expect(bake.progress[2]!.status, BakeStepStatus.running);
      expect(bake.canStart(4), isFalse);
      expect(() => bake.startPlanned(2, now), throwsStateError);
    },
  );

  test('dependent starts use actual predecessor completions, including explicit preparation edges', () {
    final bake = BakingSession(
      recipeId: 1,
      recipe: bakingRecipe(),
      plannedStart: planned,
      extraDependencies: {
        3: {2},
      },
    );
    final now = planned.add(const Duration(hours: 2));
    expect(() => bake.startPlanned(3, now), throwsStateError);
    bake.start(2, planned);
    final completion = now.subtract(const Duration(minutes: 10));
    bake.complete(2, completion);
    bake.startPlanned(3, now);
    expect(bake.progress[2]!.completedAt, completion);
    expect(bake.progress[3]!.startedAt, completion);
    expect(bake.progress[3]!.remaining(now), const Duration(minutes: 20));
    expect(bake.canStart(4), isFalse);
  });

  testWidgets('Starten persists the past start and already reduced countdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryBakes();
    final now = planned.add(const Duration(minutes: 20));
    final saved = await repo.save(
      BakingSession(recipeId: 1, recipe: bakingRecipe(), plannedStart: planned),
    );
    await tester.pumpWidget(
      styledApp(
        BakingView(sessionId: saved.id!, repository: repo, clock: () => now),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-2')));
    await tester.pumpAndSettle();
    expect(find.text('00:40:00'), findsOneWidget);
    final reopened = await repo.load(saved.id!);
    expect(reopened.progress[2]!.startedAt, planned);
    expect(reopened.progress[2]!.remaining(now), const Duration(minutes: 40));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      styledApp(
        BakingView(
          sessionId: saved.id!,
          repository: repo,
          clock: () => now.add(const Duration(minutes: 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('00:35:00'), findsOneWidget);
  });

  testWidgets('Start from now explicitly keeps the full duration', (
    tester,
  ) async {
    final repo = MemoryBakes();
    final now = planned.add(const Duration(minutes: 20));
    final saved = await repo.save(
      BakingSession(recipeId: 1, recipe: bakingRecipe(), plannedStart: planned),
    );
    await tester.pumpWidget(
      styledApp(
        BakingView(sessionId: saved.id!, repository: repo, clock: () => now),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('start-now-2'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect((await repo.load(saved.id!)).progress[2]!.startedAt, now);
    expect(
      (await repo.load(saved.id!)).progress[2]!.remaining(now),
      const Duration(hours: 1),
    );
  });

  testWidgets(
    'failed backdated saves retain the pending step and retry the same past start',
    (tester) async {
      final repo = MemoryBakes();
      final now = planned.add(const Duration(minutes: 20));
      final saved = await repo.save(
        BakingSession(
          recipeId: 1,
          recipe: bakingRecipe(),
          plannedStart: planned,
        ),
      );
      repo.failSave = true;
      await tester.pumpWidget(
        styledApp(
          BakingView(sessionId: saved.id!, repository: repo, clock: () => now),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('start-2'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        (await repo.load(saved.id!)).progress[2]!.status,
        BakeStepStatus.pending,
      );
      repo.failSave = false;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect((await repo.load(saved.id!)).progress[2]!.startedAt, planned);
    },
  );
}
