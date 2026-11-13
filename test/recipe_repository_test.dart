import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';

import 'recipe_test_database.dart';

void main() {
  test(
    'source ID cannot replace a record and internal IDs match allocated IDs',
    () async {
      final db = await recipeTestDatabase();
      addTearDown(db.close);
      final repository = RecipeRepository(database: () async => db);
      final recipe = RecipeImport.parse('{"id":1,"name":"Bread"}').single;
      final first = await repository.save(recipe);
      final second = await repository.save(recipe);
      expect(first, 1);
      expect(second, 2);
      expect((await db.query('recipes_json')).length, 2);
      expect(
        jsonDecode(
          (await db.query(
                'recipes_json',
                where: 'id = ?',
                whereArgs: [second],
              )).single['recipe_data']
              as String,
        )['id'],
        second,
      );
      expect(await repository.hasDuplicateName(' bread '), isTrue);
      recipe.name = 'Edited';
      await repository.save(recipe, id: first);
      expect((await repository.load(first)).name, 'Edited');
      expect((await repository.load(second)).name, 'Bread');
      expect(
        await repository.hasDuplicateName('Edited', exceptId: first),
        isFalse,
      );
    },
  );
  test('missing records and invalid drafts do not overwrite data', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repository = RecipeRepository(database: () async => db);
    await expectLater(repository.save(RecipeData()), throwsFormatException);
    await expectLater(
      repository.save(RecipeData(name: 'Bread'), id: 99),
      throwsStateError,
    );
    await expectLater(repository.load(99), throwsStateError);
    expect(await db.query('recipes_json'), isEmpty);
  });
}
