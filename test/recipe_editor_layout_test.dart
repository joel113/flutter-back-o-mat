import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_editor_section.dart';

import 'app_style_test.dart' show styledApp;
import 'recipe_preparation_widgets_test.dart' show PreparationRecipes;

void main() {
  for (final filled in [false, true]) {
    for (final locale in ['en', 'de']) {
      testWidgets(
        'editor section spacing is consistent: filled=$filled $locale',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = PreparationRecipes();
          final recipe = filled
              ? (repo.data[1]!.copy()
                  ..notes.add(
                    RecipeNote(title: 'Advice', body: 'Handle gently'),
                  ))
              : RecipeData(name: 'Draft');
          await tester.pumpWidget(
            styledApp(
              RecipeEditor(recipe: recipe, id: 1, repository: repo),
              locale: Locale(locale),
            ),
          );
          await tester.pumpAndSettle();
          final sections = find.byType(RecipeEditorSection);
          expect(sections, findsNWidgets(4));
          Rect? previous;
          final s = AppLocalizations.of(
            tester.element(find.byType(RecipeEditor)),
          )!;
          for (final element in sections.evaluate()) {
            final section = element.widget as RecipeEditorSection;
            final scope = find.byWidget(section);
            final heading = find.descendant(
              of: scope,
              matching: find.text(section.title),
            );
            final cards = find.descendant(
              of: scope,
              matching: find.byType(Card),
            );
            final first = filled
                ? cards.first
                : section.title == s.preparationsLabel
                ? find.text(s.preparationAddStagesFirst)
                : find
                      .descendant(
                        of: scope,
                        matching: find.byType(OutlinedButton),
                      )
                      .first;
            expect(
              tester.getTopLeft(first).dy - tester.getBottomRight(heading).dy,
              12,
              reason: section.title,
            );
            final rect = tester.getRect(scope);
            if (previous != null) {
              expect(rect.top - previous.bottom, 24, reason: section.title);
            }
            previous = rect;
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
