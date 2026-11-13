import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'recipe_test_database.dart';

void main() {
  test('version 3 upgrades to a stable alphabetical order without changing recipes or history', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('backomat-order-');
    addTearDown(() => directory.delete(recursive: true));
    final path = directory.uri.resolve('recipes.db').toFilePath();
    var db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        singleInstance: false,
        onCreate: (db, _) async {
          await createLegacyRecipes(db);
          await createRecipeFamilies(db);
        },
      ),
    );
    for (final entry in {10: 'Zeta', 20: 'Alpha', 30: 'Beta'}.entries) {
      final raw = jsonEncode(RecipeData(name: entry.value).toJson());
      await db.insert('recipes_json', {
        'id': entry.key,
        'name': entry.value,
        'recipe_data': raw,
        'last_modified': 123,
      });
      await db.insert('recipe_families', {
        'id': entry.key,
        'name': entry.value,
        'main_recipe_id': entry.key,
        'notes_json': '[{"title":"Advice","body":"Keep me"}]',
      });
      await db.insert('recipe_variants', {
        'recipe_id': entry.key,
        'family_id': entry.key,
        'variant_name': 'Standard',
        'variant_key': 'standard',
      });
      await db.insert('recipe_revisions', {
        'recipe_id': entry.key,
        'content': raw,
        'description': 'Original',
        'created_at': 123,
      });
    }
    final recipes = await db.query('recipes_json');
    final history = await db.query('recipe_revisions');
    await db.close();
    db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        singleInstance: false,
        onUpgrade: upgradeRecipeDatabase,
      ),
    );
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    expect((await repo.listFamilyEntries()).map((e) => e.familyId), [
      20,
      30,
      10,
    ]);
    expect(await db.query('recipes_json'), recipes);
    expect(await db.query('recipe_revisions'), history);
    expect((await repo.loadFamily(20)).notes.single.body, 'Keep me');
  });

  test('manual family order persists across reloads, main changes, renaming and new recipes', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final first = await repo.save(RecipeData(name: 'First'));
    final second = await repo.save(RecipeData(name: 'Second'));
    final third = await repo.save(RecipeData(name: 'Third'));
    final entries = await repo.listFamilyEntries();
    final ids = entries.map((e) => e.familyId!).toList();
    await repo.saveFamilyOrder([ids[2], ids[0], ids[1]]);
    final reopened = RecipeRepository(database: () async => db);
    expect((await reopened.listFamilyEntries()).map((e) => e.id), [
      third,
      first,
      second,
    ]);
    final variant = await repo.createVariant(first, 'Alternative');
    await repo.setMainVariant(ids[0], variant);
    await repo.renameFamily(ids[0], 'AAAA');
    final added = await repo.save(RecipeData(name: 'A new bread'));
    expect((await reopened.listFamilyEntries()).map((e) => e.id), [
      third,
      variant,
      second,
      added,
    ]);
    expect((await repo.revisions(first)).length, 1);
  });

  test('invalid or stale order is rejected and a failed write rolls back all positions', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    await repo.save(RecipeData(name: 'One'));
    await repo.save(RecipeData(name: 'Two'));
    final ids = (await repo.listFamilyEntries())
        .map((e) => e.familyId!)
        .toList();
    for (final invalid in [
      <int>[],
      [ids[0], ids[0]],
      [ids[0], 999],
    ]) {
      await expectLater(repo.saveFamilyOrder(invalid), throwsFormatException);
    }
    await db.execute(
      "CREATE TRIGGER fail_order BEFORE UPDATE OF sort_order ON recipe_families WHEN NEW.id = ${ids[0]} BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
    );
    await expectLater(
      repo.saveFamilyOrder(ids.reversed.toList()),
      throwsA(isA<DatabaseException>()),
    );
    expect((await repo.listFamilyEntries()).map((e) => e.familyId), ids);
    expect(
      (await db.query(
        'recipe_families',
        orderBy: 'sort_order',
      )).map((e) => e['sort_order']),
      [0, 1],
    );
  });
}
