import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/l10n/app_localizations.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_input.dart';

import 'recipe_editor_test.dart' show MemoryRecipes, open;

Widget inputApp(Widget child, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'unit suggestions and custom units both persist through editing',
    (tester) async {
      final repository = MemoryRecipes();
      await open(
        tester,
        repository,
        recipe: RecipeData(
          name: 'Bread',
          ingredients: [RecipeIngredient(id: 1, name: 'Flour', unit: 'scoop')],
        ),
      );
      final input = find.byType(RecipeUnitInput);
      await tester.ensureVisible(input);
      expect(find.text('scoop'), findsOneWidget);
      await tester.tap(find.byTooltip('Choose a common unit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repository.saved!.ingredients.single.unit, 'kg');

      await open(tester, repository, recipe: repository.saved, id: 42);
      await tester.ensureVisible(find.byType(RecipeUnitInput));
      await tester.enterText(
        find.descendant(
          of: find.byType(RecipeUnitInput),
          matching: find.byType(TextFormField),
        ),
        'handful',
      );
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repository.saved!.ingredients.single.unit, 'handful');
    },
  );

  testWidgets('hours, decimal comma and unit conversion save whole minutes', (
    tester,
  ) async {
    final repository = MemoryRecipes();
    await open(
      tester,
      repository,
      recipe: RecipeData(
        name: 'Bread',
        stages: [
          RecipeStage(id: 1, name: 'Rest', durationMin: 90, durationMax: 120),
        ],
      ),
    );
    final minimum = find.byKey(const ValueKey('durationMin'));
    final maximum = find.byKey(const ValueKey('durationMax'));
    await tester.ensureVisible(minimum);
    await tester.tap(
      find.descendant(of: minimum, matching: find.byType(DropdownButton<int>)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hours').last);
    await tester.pumpAndSettle();
    final minText = find.descendant(
      of: minimum,
      matching: find.byType(TextFormField),
    );
    expect(tester.widget<TextFormField>(minText).controller!.text, '1.5');
    await tester.enterText(minText, '1,5');
    await tester.ensureVisible(maximum);
    await tester.enterText(
      find.descendant(of: maximum, matching: find.byType(TextFormField)),
      '2.5',
    );
    await tester.tap(find.byKey(const ValueKey('saveRecipe')));
    await tester.pumpAndSettle();
    expect(repository.saved!.stages.single.durationMin, 90);
    expect(repository.saved!.stages.single.durationMax, 150);
  });

  for (final locale in ['en', 'de']) {
    testWidgets(
      '$locale duration input validates and converts without precision loss',
      (tester) async {
        final form = GlobalKey<FormState>();
        int? changed;
        await tester.pumpWidget(
          inputApp(
            Form(
              key: form,
              child: RecipeDurationInput(
                label: 'Duration',
                minutes: 1,
                onChanged: (v) => changed = v,
              ),
            ),
            locale: locale,
          ),
        );
        await tester.tap(find.byType(DropdownButton<int>));
        await tester.pumpAndSettle();
        final hours = locale == 'de' ? 'Stunden' : 'Hours';
        await tester.tap(find.text(hours).last);
        await tester.pumpAndSettle();
        expect(form.currentState!.validate(), isTrue);
        final field = find.byType(TextFormField);
        await tester.enterText(field, '0,5');
        expect(changed, 30);
        expect(form.currentState!.validate(), isTrue);
        for (final invalid in ['-1', 'NaN', 'Infinity', '0.001', 'abc']) {
          await tester.enterText(field, invalid);
          expect(changed, isNull);
          expect(form.currentState!.validate(), isFalse);
        }
        // Invalid input cannot be silently reinterpreted by changing its unit.
        await tester.tap(find.byType(DropdownButton<int>));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(locale == 'de' ? 'Minuten' : 'Minutes').last,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
              .value,
          60,
        );
        expect(tester.widget<TextFormField>(field).controller!.text, 'abc');
        await tester.enterText(field, '');
        expect(form.currentState!.validate(), isTrue);
        expect(changed, isNull);
        await tester.enterText(field, '0');
        expect(form.currentState!.validate(), isTrue);
        expect(changed, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a maximum below the minimum is rejected after hours conversion',
    (tester) async {
      final repository = MemoryRecipes();
      await open(
        tester,
        repository,
        recipe: RecipeData(
          name: 'Bread',
          stages: [
            RecipeStage(
              id: 1,
              name: 'Rest',
              durationMin: 120,
              durationMax: 180,
            ),
          ],
        ),
      );
      final maximum = find.byKey(const ValueKey('durationMax'));
      await tester.ensureVisible(maximum);
      await tester.enterText(
        find.descendant(of: maximum, matching: find.byType(TextFormField)),
        '1.5',
      );
      await tester.tap(find.byKey(const ValueKey('saveRecipe')));
      await tester.pumpAndSettle();
      expect(repository.saved, isNull);
      expect(
        find.text(
          'Durations must be whole, non-negative minutes; maximum must not be below minimum.',
        ),
        findsOneWidget,
      );
    },
  );
}
