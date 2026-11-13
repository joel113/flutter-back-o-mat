import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_view.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';

import 'app_style_test.dart' show styledApp;
import 'baking_session_test.dart' show bakingRecipe;
import 'baking_view_test.dart' show MemoryBakes;

void main() {
  for (final width in [1280.0, 390.0]) {
    for (final locale in ['en', 'de']) {
      testWidgets('baking summary and workspace spacing: $width $locale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final now = DateTime(2026, 11, 10, 8);
        final repository = MemoryBakes();
        final saved = await repository.save(
          BakingSession(recipeId: 1, recipe: bakingRecipe(), plannedStart: now),
        );
        await tester.pumpWidget(
          styledApp(
            BakingView(
              sessionId: saved.id!,
              repository: repository,
              clock: () => now,
            ),
            locale: Locale(locale),
          ),
        );
        await tester.pumpAndSettle();
        final s = AppLocalizations.of(tester.element(find.byType(BakingView)))!;
        final summary = find.byKey(const ValueKey('bake-start-summary'));
        final change = find.byKey(const ValueKey('change-bake-start'));
        expect(find.descendant(of: summary, matching: change), findsOneWidget);
        expect(
          find.descendant(of: change, matching: find.text(s.changeStart)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: change,
            matching: find.byIcon(Icons.edit_outlined),
          ),
          findsOneWidget,
        );
        expect(find.byTooltip(s.changeStart), findsOneWidget);
        final header = tester.getRect(find.byType(AppBar));
        expect(tester.getRect(summary).top - header.bottom, 12);
        final selector = tester.getRect(find.byType(SegmentedButton<bool>));
        expect(tester.getRect(find.byType(Table)).top - selector.bottom, 16);
        expect(tester.takeException(), isNull);

        // The relocated action still changes the session start through its picker.
        await tester.tap(change);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tester.tap(
          find.text(
            MaterialLocalizations.of(
              tester.element(find.byType(DatePickerDialog)),
            ).cancelButtonLabel,
          ),
        );
        await tester.pumpAndSettle();
        expect((await repository.load(saved.id!)).plannedStart, now);

        await tester.tap(find.text(s.timelineTitle));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byType(Table)).top -
              tester.getRect(find.byType(SegmentedButton<bool>)).bottom,
          greaterThanOrEqualTo(16),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
