import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/navigation.dart';
import 'package:flutter_back_o_mat/planner/planner.dart';
import 'package:flutter_back_o_mat/recipes/recipes.dart';
import 'package:flutter_back_o_mat/settings/settings.dart';
import 'package:flutter_back_o_mat/theme/app_components.dart';
import 'package:flutter_back_o_mat/util/db/db.dart';

import 'app_style_test.dart' show styledApp;
import 'baking_session_test.dart' show bakingRecipe;
import 'baking_view_test.dart' show MemoryBakes;

void main() {
  for (final width in [1800.0, 390.0]) {
    for (final locale in ['en', 'de']) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'main pages share alignment and fill height: $width $locale $mode',
          (tester) async {
            tester.view.physicalSize = Size(width, 720);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final bakes = MemoryBakes();
            await bakes.save(
              BakingSession(
                recipeId: 1,
                recipe: bakingRecipe(),
                plannedStart: DateTime(2026, 11, 9),
              ),
            );
            await tester.pumpWidget(
              styledApp(
                BackomatNavigation(
                  recipesBuilder: (_) => BackomatRecipes(
                    loadRecipes: () async => [
                      RecipeJsonEntry(
                        id: 1,
                        name: 'Bread',
                        jsonData: '{}',
                        lastModified: DateTime(2026),
                      ),
                    ],
                  ),
                  plannerBuilder: (_) => BackomatPlanner(repository: bakes),
                ),
                locale: Locale(locale),
                mode: mode,
              ),
            );
            await tester.pumpAndSettle();
            final area = tester.getRect(
              find.byKey(const ValueKey('section-content')),
            );
            Rect? firstPanel;
            Rect? firstTitle;
            TextStyle? firstTitleStyle;
            for (final destination in ['recipes', 'planner', 'settings']) {
              await tester.tap(find.byKey(ValueKey('nav-$destination')));
              await tester.pumpAndSettle();
              final frame = find.byType(AppPage);
              final panel = tester.getRect(
                find.descendant(of: frame, matching: find.byType(AppSurface)),
              );
              final context = tester.element(frame);
              final s = AppLocalizations.of(context)!;
              final label = switch (destination) {
                'recipes' => s.recipes,
                'planner' => s.planer,
                _ => s.settings,
              };
              final title = find.descendant(
                of: find.byType(AppPageHeader),
                matching: find.text(label),
              );
              final titleRect = tester.getRect(title);
              final titleStyle = tester.widget<Text>(title).style;
              // Even short lists and settings occupy the same content frame.
              expect(panel.bottom, area.bottom - 24);
              expect(panel.center.dx, area.center.dx);
              expect(panel.width, (area.width > 1280 ? 1280 : area.width) - 48);
              expect(titleRect.left, panel.left);
              if (firstPanel != null) {
                expect(panel.left, firstPanel.left);
                expect(panel.right, firstPanel.right);
                expect(titleRect.top, firstTitle!.top);
                expect(titleStyle, firstTitleStyle);
                if (width >= 1000) expect(panel, firstPanel);
              } else {
                firstPanel = panel;
                firstTitle = titleRect;
                firstTitleStyle = titleStyle;
              }
              expect(tester.takeException(), isNull);
            }
            // Settings content stays scrollable inside the shared panel.
            final scroll = find.descendant(
              of: find.byType(AppSettings),
              matching: find.byType(SingleChildScrollView),
            );
            await tester.drag(scroll, const Offset(0, -500));
            await tester.pumpAndSettle();
            expect(find.text('Back-o-Mat').last.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
