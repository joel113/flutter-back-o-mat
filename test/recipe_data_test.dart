import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';

void main() {
  test('bundled recipes round trip and incomplete recipe remains readable', () {
    for (final file
        in Directory('assets/recipes')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))) {
      final recipe = RecipeImport.parse(file.readAsStringSync()).single;
      expect(recipe.validate(), isEmpty);
      expect(
        RecipeData.fromJson(
          jsonDecode(jsonEncode(recipe.toJson())) as Map<String, dynamic>,
        ).toJson(),
        recipe.toJson(),
      );
      if (file.path.contains('sourdoughdinkel')) {
        expect(recipe.ingredients, isEmpty);
        expect(recipe.stages, isEmpty);
        expect(recipe.bakingReady, isFalse);
      } else {
        expect(recipe.bakingReady, isTrue);
        expect(recipe.stages.first.durationMin, 720);
      }
    }
  });

  test('quantities accept integer JSON and normalize to doubles', () {
    final recipe = RecipeImport.parse(
      '{"id":1,"name":"Bread","ingredients":[{"id":1,"name":"Flour","amount":500}]}',
    ).single;
    expect(recipe.ingredients.single.amount, 500.0);
    expect(recipe.toJson().containsKey('id'), isFalse);
  });

  test(
    'Schema.org graph, arrays, and nested sections preserve instructions',
    () {
      final source = jsonEncode({
        '@graph': [
          {'@type': 'WebPage', 'name': 'Page'},
          {
            '@type': ['Thing', 'Recipe'],
            'name': 'Bread',
            'recipeIngredient': ['1½ cups flour', 'salt to taste'],
            'recipeInstructions': [
              {
                '@type': 'HowToSection',
                'itemListElement': [
                  {
                    '@type': 'HowToStep',
                    'name': 'Mix',
                    'text': 'Mix everything.',
                  },
                ],
              },
              'Rest overnight.',
            ],
          },
          {'@type': 'Recipe', 'name': 'Other'},
        ],
      });
      final recipes = RecipeImport.parse(source);
      expect(recipes.length, 2);
      expect(recipes.first.ingredients.first.name, '1½ cups flour');
      expect(recipes.first.ingredients.first.amount, isNull);
      expect(recipes.first.stages.map((e) => e.description), [
        'Mix everything.',
        'Rest overnight.',
      ]);
      expect(recipes.first.stages.first.durationMin, isNull);
      expect(recipes.first.validate(), isEmpty);
      expect(
        () => RecipeImport.parse('{"@type":"WebPage","name":"Other"}'),
        throwsFormatException,
      );
    },
  );

  test('validation rejects cycles, dangling references, duplicates and forward dependencies', () {
    final recipe = RecipeData(
      name: 'Bread',
      ingredients: [RecipeIngredient(id: 1, name: 'Flour')],
      stages: [
        RecipeStage(
          id: 2,
          name: 'Mix',
          ingredients: [IngredientReference(id: 3)],
        ),
        RecipeStage(
          id: 3,
          name: 'Bake',
          ingredients: [IngredientReference(id: 2)],
        ),
      ],
    );
    expect(recipe.validate(), contains(RecipeIssue.references));
    recipe.stages.first.ingredients.clear();
    expect(recipe.validate(), isEmpty);
    recipe.stages.last.ingredients.add(IngredientReference(id: 999));
    expect(recipe.validate(), contains(RecipeIssue.references));
    recipe.stages.last.ingredients.removeLast();
    recipe.ingredients.add(RecipeIngredient(id: 2, name: 'Salt'));
    expect(recipe.validate(), contains(RecipeIssue.references));
  });

  test('timed baking requires all timings and validates ranges', () {
    final recipe = RecipeData(
      name: 'Bread',
      ingredients: [RecipeIngredient(id: 1, name: 'Flour')],
      stages: [RecipeStage(id: 2, name: 'Bake')],
    );
    expect(recipe.validate(), isEmpty);
    expect(recipe.bakingReady, isFalse);
    recipe.stages.single
      ..durationMin = 30
      ..durationMax = 40;
    expect(recipe.bakingReady, isTrue);
    recipe.stages.single.durationMax = 20;
    expect(recipe.validate(), contains(RecipeIssue.duration));
    recipe.ingredients.single.amount = -1;
    expect(recipe.validate(), contains(RecipeIssue.quantity));
  });
}
