import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/recipe/editor/recipe_file_import.dart';
import 'package:flutter_back_o_mat/baking/baking_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'recipe_test_database.dart';

import 'package:flutter_back_o_mat/recipe/data/recipe_schema.dart';

import 'baking_session_test.dart' show bakingRecipe;

void main() {
  test(
    'version 4 migration preserves existing content and adds an import ledger',
    () async {
      final db = await recipeTestDatabase();
      addTearDown(db.close);
      final repo = RecipeRepository(database: () async => db);
      final id = await repo.save(RecipeData(name: 'Keep me'));
      final history = await repo.revisions(id);
      await db.execute('DROP TABLE bundled_recipe_imports');
      await upgradeRecipeDatabase(db, 4, 5);
      expect((await repo.load(id)).name, 'Keep me');
      expect((await repo.revisions(id)).single.content, history.single.content);
      expect(await db.query('bundled_recipe_imports'), isEmpty);
    },
  );

  test('deleted bundled variants do not reappear at startup and old names are adopted without duplication', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final original = RecipeData(name: 'Bundled bread');
    // Existing installations already contain recipes before the ledger is added.
    final id = await repo.save(original);
    expect(
      await repo.importBundled('assets/recipes/bread.json', original),
      isFalse,
    );
    final family = (await repo.loadRecord(id)).family!;
    final other = await repo.importVariant(
      family.id,
      'Other',
      RecipeData(name: 'New title'),
    );
    await repo.renameFamily(family.id, 'Renamed family');
    await repo.deleteVariant(id, replacementId: other);
    expect(
      await repo.importBundled('assets/recipes/bread.json', original),
      isFalse,
    );
    expect((await repo.listFamilyEntries()).length, 1);
    expect((await repo.listFamilyEntries()).single.id, other);
    expect(
      await repo.importBundled(
        'assets/recipes/new.json',
        RecipeData(name: 'New bundled bread'),
      ),
      isTrue,
    );
  });

  test('failed bundled imports do not record the asset as completed', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    await expectLater(
      repo.importBundled('bad.json', RecipeData()),
      throwsFormatException,
    );
    expect(await db.query('bundled_recipe_imports'), isEmpty);
    expect(await repo.listFamilyEntries(), isEmpty);
  });

  test('deleting a non-main variant retains its family, main, notes, order and saved bakes', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final main = await repo.save(bakingRecipe());
    final family = (await repo.loadRecord(main)).family!;
    await repo.saveSharedNotes(family.id, [
      RecipeNote(title: 'Advice', body: 'Keep me'),
    ]);
    final variant = await repo.createVariant(main, 'Alternative');
    final bakes = BakingRepository(database: () async => db);
    final bake = await bakes.openForRecipe(
      variant,
      await repo.load(variant),
      DateTime(2026),
    );
    expect(await repo.deleteVariant(variant), main);
    expect((await repo.loadFamily(family.id)).variants.length, 1);
    expect((await repo.loadFamily(family.id)).notes.single.body, 'Keep me');
    expect(await repo.revisions(variant), isEmpty);
    await expectLater(repo.load(variant), throwsStateError);
    expect((await repo.listFamilyEntries()).single.variantCount, 1);
    expect((await bakes.load(bake.id!)).recipe.name, 'Bread');
    expect((await bakes.load(bake.id!)).recipeId, variant);
    expect((await repo.revisions(main)).length, 1);
  });

  test('main deletion requires a sibling replacement and protects the last variant', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final main = await repo.save(RecipeData(name: 'Bread'));
    final variant = await repo.createVariant(main, 'Other');
    final unrelated = await repo.save(RecipeData(name: 'Unrelated'));
    await expectLater(repo.deleteVariant(main), throwsFormatException);
    await expectLater(
      repo.deleteVariant(main, replacementId: unrelated),
      throwsFormatException,
    );
    expect((await repo.loadRecord(main)).family!.mainRecipeId, main);
    expect(await repo.deleteVariant(main, replacementId: variant), variant);
    expect((await repo.listFamilyEntries()).first.id, variant);
    await expectLater(repo.deleteVariant(variant), throwsFormatException);
  });

  test('referenced preparation variants cannot be deleted', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final prep = await repo.save(bakingRecipe());
    await repo.createVariant(prep, 'Spare');
    final parent = await repo.save(
      bakingRecipe()
        ..preparations.add(RecipePreparation(recipeId: prep, stageId: 4)),
    );
    final replacement = (await repo.loadRecord(prep)).family!.variants.last.id;
    await expectLater(
      repo.deleteVariant(prep, replacementId: replacement),
      throwsA(isA<VariantDeletionBlocked>()),
    );
    expect((await repo.loadRecord(prep)).family!.mainRecipeId, prep);
    final edited = await repo.load(parent);
    edited.preparations.clear();
    await repo.save(edited, id: parent);
    expect(
      await repo.deleteVariant(prep, replacementId: replacement),
      replacement,
    );
  });

  test(
    'failed deletion rolls back main selection, history and recipe rows',
    () async {
      final db = await recipeTestDatabase();
      addTearDown(db.close);
      final repo = RecipeRepository(database: () async => db);
      final main = await repo.save(RecipeData(name: 'Bread'));
      final other = await repo.createVariant(main, 'Other');
      await db.execute(
        "CREATE TRIGGER fail_delete BEFORE DELETE ON recipes_json BEGIN SELECT RAISE(ABORT, 'disk'); END",
      );
      await expectLater(
        repo.deleteVariant(main, replacementId: other),
        throwsA(isA<DatabaseException>()),
      );
      expect((await repo.loadRecord(main)).family!.mainRecipeId, main);
      expect((await repo.loadRecord(main)).family!.variants.length, 2);
      expect((await repo.revisions(main)).length, 1);
    },
  );

  test('file imports create a new variant in the selected family without replacing source IDs', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final main = await repo.save(RecipeData(name: 'Bread'));
    final family = (await repo.loadRecord(main)).family!;
    final file = XFile.fromData(
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'id': main,
            'familyId': 999,
            'name': 'Imported',
            'image': 'local:stolen.png',
            'preparations': [
              {'recipeId': main, 'stageId': 999},
            ],
            'notes': [
              {'title': 'Trial', 'body': 'Try this'},
            ],
          }),
        ),
      ),
      name: 'recipe.json',
    );
    final imported = (await readRecipeFile(file)).single;
    expect(imported.image, isNull);
    expect(imported.preparations, isEmpty);
    expect(imported.importedPreparationsRemoved, isTrue);
    final id = await repo.importVariant(family.id, 'From file', imported);
    expect(id, isNot(main));
    expect((await repo.load(main)).name, 'Bread');
    expect((await repo.loadRecord(id)).family!.id, family.id);
    expect((await repo.loadRecord(id)).family!.mainRecipeId, main);
    expect((await repo.load(id)).notes.single.body, 'Try this');
    expect((await repo.revisions(id)).length, 1);
    expect((await repo.listFamilyEntries()).length, 1);
    await expectLater(
      repo.importVariant(family.id, ' from FILE ', imported),
      throwsFormatException,
    );
    await expectLater(
      repo.importVariant(999, 'New', imported),
      throwsStateError,
    );
    expect((await repo.loadFamily(family.id)).variants.length, 2);
  });

  test('file parsing supports JSON-LD and multiple recipes, rejecting invalid or oversized data', () async {
    XFile file(String text) => XFile.fromData(
      Uint8List.fromList(utf8.encode(text)),
      name: 'recipe.jsonld',
    );
    final parsed = await readRecipeFile(
      file(
        '[{"@type":"Recipe","name":"One","recipeIngredient":["Flour"]},{"name":"Two"}]',
      ),
    );
    expect(parsed.map((r) => r.name), ['One', 'Two']);
    expect(parsed.first.ingredients.single.name, 'Flour');
    await expectLater(readRecipeFile(file('invalid')), throwsFormatException);
    await expectLater(
      readRecipeFile(
        XFile.fromData(Uint8List(recipeFileLimit + 1), name: 'big.json'),
      ),
      throwsFormatException,
    );
  });
}
