import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_timeline.dart';
import 'package:flutter_back_o_mat/baking/baking_view.dart';

import 'baking_session_test.dart' show bakingRecipe;
import 'baking_view_test.dart' show MemoryBakes, app, largeWindow;

class TrackingBakes extends MemoryBakes {
  int saves = 0;
  @override
  Future<BakingSession> save(BakingSession session) async {
    saves++;
    return super.save(session);
  }
}

void main() {
  final now = DateTime(2026, 11, 7, 8);
  BakingSession bake() =>
      BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now);
  final scale = BakingTimelineScale(
    start: now,
    end: now.add(const Duration(hours: 3)),
    width: 396,
  ); // 2 px/min

  test(
    'move previews update dependent steps without modifying the saved snapshot',
    () {
      final original = bake();
      final drag = BakingTimelineDrag(
        session: original,
        stageId: 2,
        resize: false,
        now: now,
        scale: scale,
      );
      final preview = drag.preview(60);
      expect(
        preview.schedule(now)[2]!.start,
        now.add(const Duration(minutes: 30)),
      );
      expect(
        preview.schedule(now)[4]!.start,
        now.add(const Duration(minutes: 90)),
      );
      expect(original.progress[2]!.notBefore, isNull);
      final constrained = BakingTimelineDrag(
        session: original,
        stageId: 4,
        resize: false,
        now: now,
        scale: scale,
      ).preview(-1000);
      expect(
        constrained.schedule(now)[4]!.start,
        now.add(const Duration(minutes: 60)),
      );
      expect(
        constrained.progress[4]!.notBefore,
        now.add(const Duration(minutes: 60)),
      );
    },
  );
  test('resize previews clamp to minimum and maximum, while fixed durations stay fixed', () {
    final drag = BakingTimelineDrag(
      session: bake(),
      stageId: 2,
      resize: true,
      now: now,
      scale: scale,
    );
    expect(drag.preview(60).progress[2]!.durationMinutes, 90);
    expect(drag.preview(9999).progress[2]!.durationMinutes, 120);
    expect(drag.preview(-9999).progress[2]!.durationMinutes, 60);
    final fixed = bake();
    fixed.recipe.stages.first.durationMax = 60;
    expect(
      BakingTimelineDrag(
        session: fixed,
        stageId: 2,
        resize: true,
        now: now,
        scale: scale,
      ).preview(9999).progress[2]!.durationMinutes,
      60,
    );
    final started = bake()..start(2, now);
    expect(
      () => BakingTimelineDrag(
        session: started,
        stageId: 2,
        resize: false,
        now: now,
        scale: scale,
      ),
      throwsStateError,
    );
  });

  Future<TrackingBakes> open(WidgetTester tester) async {
    largeWindow(tester);
    final repository = TrackingBakes();
    final session = await repository.save(bake());
    await tester.pumpWidget(
      app(
        BakingView(
          sessionId: session.id!,
          repository: repository,
          clock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets(
    'wide view aligns table and timeline; drag saves once on release',
    (tester) async {
      final repository = await open(tester);
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(TimelineStage), findsNWidgets(3));
      final rowName = find.text('Sourdough').first;
      final bar = find.byKey(const ValueKey('timeline-bar-2'));
      final nameCell = find
          .ancestor(of: rowName, matching: find.byType(InkWell))
          .first;
      expect(
        tester.getCenter(find.byType(TimelineStage).first).dy,
        tester.getCenter(nameCell).dy,
      );
      await tester.tap(rowName);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TimelineStage>(find.byType(TimelineStage).first).selected,
        isTrue,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(bar),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(35, 0));
      await tester.pump();
      expect(repository.saves, 1);
      expect(repository.sessions.values.single.progress[2]!.notBefore, isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(repository.saves, 2);
      expect(
        repository.sessions.values.single.progress[2]!.notBefore!.isAfter(now),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'right handle resizes, then Escape cancels a later drag without saving',
    (tester) async {
      final repository = await open(tester);
      final handle = find.byKey(const ValueKey('timeline-resize-2'));
      await tester.drag(handle, const Offset(55, 0));
      await tester.pumpAndSettle();
      expect(
        repository.sessions.values.single.progress[2]!.durationMinutes,
        greaterThan(60),
      );
      final saves = repository.saves;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('timeline-bar-2'))),
      );
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(repository.saves, saves);
      expect(repository.sessions.values.single.progress[2]!.notBefore, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'failed drag save rolls back and started steps have no resize handle',
    (tester) async {
      final repository = await open(tester);
      repository.failSave = true;
      await tester.drag(
        find.byKey(const ValueKey('timeline-resize-2')),
        const Offset(50, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save the baking session.'),
        findsOneWidget,
      );
      expect(
        repository.sessions.values.single.progress[2]!.durationMinutes,
        60,
      );
      repository.failSave = false;
      await tester.tap(find.byKey(const ValueKey('start-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('timeline-resize-2')), findsNothing);
      final saves = repository.saves;
      await tester.drag(
        find.byKey(const ValueKey('timeline-bar-2')),
        const Offset(50, 0),
      );
      await tester.pumpAndSettle();
      expect(repository.saves, saves);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'narrow window switches between table and timeline without overflowing',
    (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = TrackingBakes();
      final session = await repository.save(bake());
      await tester.pumpWidget(
        app(
          BakingView(
            sessionId: session.id!,
            repository: repository,
            clock: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TimelineStage), findsNothing);
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.byType(TimelineStage), findsNWidgets(3));
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();
      expect(find.byType(TimelineStage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'resize keeps the left edge and row position fixed through preview and save',
    (tester) async {
      final repository = await open(tester);
      final bar = find.byKey(const ValueKey('timeline-bar-2'));
      final before = tester.getRect(bar);
      final otherBefore = tester.getRect(
        find.byKey(const ValueKey('timeline-bar-3')),
      );
      final handle = find.byKey(const ValueKey('timeline-resize-2'));
      final gesture = await tester.startGesture(
        tester.getCenter(handle),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      final during = tester.getRect(bar);
      expect(during.left, closeTo(before.left, .01));
      expect(during.top, closeTo(before.top, .01));
      expect(during.width, greaterThan(before.width));
      expect(repository.sessions.values.single.progress[2]!.notBefore, isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      final after = tester.getRect(bar);
      expect(after.left, closeTo(before.left, .01));
      expect(after.width, closeTo(during.width, .01));
      expect(
        tester.getRect(find.byKey(const ValueKey('timeline-bar-3'))).left,
        closeTo(otherBefore.left, .01),
      );
      expect(repository.sessions.values.single.progress[2]!.notBefore, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('moving a bar does not refit the axis on release', (
    tester,
  ) async {
    await open(tester);
    final bar = find.byKey(const ValueKey('timeline-bar-2'));
    final before = tester.getRect(bar);
    final gesture = await tester.startGesture(
      tester.getCenter(bar),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(35, 0));
    await tester.pump();
    final preview = tester.getRect(bar);
    expect(preview.left, greaterThan(before.left));
    expect(preview.width, closeTo(before.width, .01));
    await gesture.up();
    await tester.pumpAndSettle();
    final saved = tester.getRect(bar);
    expect(saved.left, closeTo(preview.left, .01));
    expect(saved.width, closeTo(preview.width, .01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'all baking cells stay vertically centered in a tall instruction row',
    (tester) async {
      largeWindow(tester);
      final repository = TrackingBakes();
      final recipe = bakingRecipe();
      recipe.stages.first.description = List.filled(
        25,
        'Long preparation instructions for the sourdough.',
      ).join(' ');
      final saved = await repository.save(
        BakingSession(recipeId: 7, recipe: recipe, plannedStart: now),
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
      final table = tester.widget<Table>(find.byType(Table));
      final row = table.children[1];
      final center = tester.getCenter(find.byType(TimelineStage).first).dy;
      for (final child in row.children) {
        expect(tester.getCenter(find.byWidget(child)).dy, closeTo(center, .01));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'duration guide is thin and appears only on the selected flexible step',
    (tester) async {
      await open(tester);
      expect(find.byKey(const ValueKey('timeline-range-2')), findsNothing);
      expect(find.byKey(const ValueKey('timeline-range-3')), findsNothing);
      await tester.tap(find.text('Sourdough').first);
      await tester.pumpAndSettle();
      final guide = find.byKey(const ValueKey('timeline-range-2'));
      expect(guide, findsOneWidget);
      expect(
        tester.getSize(guide).height,
        lessThan(
          tester.getSize(find.byKey(const ValueKey('timeline-bar-2'))).height,
        ),
      );
      expect(find.byKey(const ValueKey('timeline-range-3')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'drag preview highlights recalculated descendants but not independent roots',
    (tester) async {
      final repository = await open(tester);
      final child = find.byKey(const ValueKey('timeline-bar-4'));
      final before = tester.getRect(child);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('timeline-bar-2'))),
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(35, 0));
      await tester.pump();
      final nodes = tester
          .widgetList<TimelineStage>(find.byType(TimelineStage))
          .toList();
      expect(nodes.firstWhere((node) => node.stage.id == 4).affected, isTrue);
      expect(nodes.firstWhere((node) => node.stage.id == 3).affected, isFalse);
      expect(tester.getRect(child).left, greaterThan(before.left));
      expect(repository.saves, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(repository.saves, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'delaying a consumer flags early predecessors without moving them',
    (tester) async {
      await open(tester);
      final parentBar = find.byKey(const ValueKey('timeline-bar-2'));
      final before = tester.getRect(parentBar);
      final consumerBar = find.byKey(const ValueKey('timeline-bar-4'));
      final gesture = await tester.startGesture(
        tester.getTopLeft(consumerBar) + const Offset(3, 17),
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(215, 0));
      await tester.pump();
      final parent = tester
          .widgetList<TimelineStage>(find.byType(TimelineStage))
          .firstWhere((node) => node.stage.id == 2);
      expect(parent.timingWarning, contains('Sourdough is ready'));
      expect(parent.timingWarning, contains('Dough'));
      expect(parent.timingWarning, contains('maximum duration'));
      expect(parent.hasTimingConflict, isFalse);
      expect(parent.affected, isFalse);
      expect(tester.getRect(parentBar).left, closeTo(before.left, .01));
      expect(tester.getRect(parentBar).width, closeTo(before.width, .01));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('timing-warning-2-4')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'timing conflicts are shown for historical running steps without rewriting actual times',
    (tester) async {
      largeWindow(tester);
      final repository = TrackingBakes();
      final session = bake();
      session.progress[4]!
        ..startedAt = now.add(const Duration(minutes: 60))
        ..deadline = now.add(const Duration(minutes: 75));
      session.setStepStart(2, now.add(const Duration(minutes: 90)));
      final saved = await repository.save(session);
      await tester.pumpWidget(
        app(
          BakingView(
            sessionId: saved.id!,
            repository: repository,
            clock: () => now.add(const Duration(hours: 2)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final consumer = tester
          .widgetList<TimelineStage>(find.byType(TimelineStage))
          .firstWhere((node) => node.stage.id == 4);
      expect(consumer.hasTimingConflict, isTrue);
      expect(
        consumer.timingWarning,
        contains('Dough starts 1 h 30 min before Sourdough is ready'),
      );
      expect(find.byKey(const ValueKey('timing-warning-2-4')), findsOneWidget);
      expect(
        (await repository.load(saved.id!)).progress[4]!.startedAt,
        session.progress[4]!.startedAt,
      );
      expect(find.byKey(const ValueKey('timeline-resize-4')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
