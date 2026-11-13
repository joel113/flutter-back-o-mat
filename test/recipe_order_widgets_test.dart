import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipes/recipes.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';

import 'app_style_test.dart' show styledApp;

List<RecipeJsonEntry> entries() => [
  for (var i = 1; i <= 3; i++)
    RecipeJsonEntry(
      id: i * 10,
      familyId: i,
      name: ['Bread A', 'Bread B', 'Bread C'][i - 1],
      jsonData: '{}',
      lastModified: DateTime(2026),
    ),
];

Future<void> dragFirstToLast(WidgetTester tester) async {
  final first = tester.getCenter(find.byKey(const ValueKey('reorder-1')));
  final last = tester.getCenter(find.byKey(const ValueKey('reorder-3')));
  final gesture = await tester.startGesture(first);
  await gesture.moveBy(const Offset(0, 30));
  await tester.pump();
  final target = last + const Offset(0, 90);
  for (var step = 1; step <= 8; step++) {
    await gesture.moveTo(
      Offset.lerp(first + const Offset(0, 30), target, step / 8)!,
    );
    await tester.pump(const Duration(milliseconds: 80));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'dragging saves family IDs once and restores the persisted order after reopening',
    (tester) async {
      var rows = entries();
      final saves = <List<int>>[];
      Widget screen() => styledApp(
        BackomatRecipes(
          loadRecipes: () async => rows,
          saveOrder: (ids) async {
            saves.add(List.of(ids));
            rows = [
              for (final id in ids) rows.firstWhere((r) => r.familyId == id),
            ];
          },
        ),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      await dragFirstToLast(tester);
      expect(saves, [
        [2, 3, 1],
      ]);
      expect(
        tester.getTopLeft(find.text('Bread C')).dy,
        lessThan(tester.getTopLeft(find.text('Bread A')).dy),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Bread B')).dy,
        lessThan(tester.getTopLeft(find.text('Bread C')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Bread C')).dy,
        lessThan(tester.getTopLeft(find.text('Bread A')).dy),
      );
    },
  );

  testWidgets(
    'failed save restores the previous visual order and allows retry',
    (tester) async {
      var fail = true;
      var saves = 0;
      await tester.pumpWidget(
        styledApp(
          BackomatRecipes(
            loadRecipes: () async => entries(),
            saveOrder: (_) async {
              saves++;
              if (fail) throw StateError('disk full');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragFirstToLast(tester);
      expect(
        find.text(
          'Could not save the recipe order. The previous order has been restored.',
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Bread A')).dy,
        lessThan(tester.getTopLeft(find.text('Bread B')).dy),
      );
      fail = false;
      await dragFirstToLast(tester);
      expect(saves, 2);
      expect(
        tester.getTopLeft(find.text('Bread C')).dy,
        lessThan(tester.getTopLeft(find.text('Bread A')).dy),
      );
    },
  );

  testWidgets(
    'leaving while an order save is pending does not update disposed state',
    (tester) async {
      final pending = Completer<void>();
      await tester.pumpWidget(
        styledApp(
          BackomatRecipes(
            loadRecipes: () async => entries(),
            saveOrder: (_) => pending.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await dragFirstToLast(tester);
      await tester.pumpWidget(const SizedBox());
      pending.completeError(StateError('disk'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
