import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_data.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_repository.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_schema.dart';
import 'package:flutter_back_o_mat/baking/baking_schema.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:flutter_back_o_mat/baking/baking_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'recipe_test_database.dart';
import 'baking_session_test.dart' show bakingRecipe;

void main() {
  for (final oldVersion in [1, 2]) {
    test(
      'upgrade v$oldVersion preserves IDs, raw recipes and existing bakes',
      () async {
        sqfliteFfiInit();
        final directory = await Directory.systemTemp.createTemp(
          'backomat-migration-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final path = directory.uri.resolve('recipes.db').toFilePath();
        var db = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: oldVersion,
            singleInstance: false,
            onCreate: (db, _) async {
              await createLegacyRecipes(db);
              if (oldVersion == 2) await createBakingSessions(db);
            },
          ),
        );
        final raw = jsonEncode(bakingRecipe().toJson()..remove('notes'));
        await db.insert('recipes_json', {
          'id': 17,
          'name': 'Bread',
          'recipe_data': raw,
          'last_modified': 1234,
        });
        final oldSession = BakingSession(
          recipeId: 17,
          recipe: bakingRecipe(),
          plannedStart: DateTime(2026),
        );
        String? oldSessionJson;
        if (oldVersion == 2) {
          oldSessionJson = jsonEncode(
            oldSession.toJson()
              ..remove('sharedNotes')
              ..remove('variantName')
              ..remove('familyName'),
          );
          await db.insert('baking_sessions', {
            'id': 4,
            'recipe_id': 17,
            'planned_start': 0,
            'session_data': oldSessionJson,
            'status': 'planned',
          });
        }
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
        final repository = RecipeRepository(database: () async => db);
        final record = await repository.loadRecord(17);
        expect(record.family!.mainRecipeId, 17);
        expect(record.variant!.name, 'Standard');
        expect(record.family!.notes, isEmpty);
        expect((await db.query('recipes_json')).single['recipe_data'], raw);
        expect((await repository.revisions(17)).single.content, raw);
        if (oldSessionJson != null) {
          expect(
            (await db.query('baking_sessions')).single['session_data'],
            oldSessionJson,
          );
          final loaded = await BakingRepository(database: () async => db)
              .load(4);
          expect(loaded.sharedNotes, isEmpty);
          expect(loaded.recipeId, 17);
        }
        await repository.save(RecipeData(name: 'New bread'));
        expect((await repository.listFamilyEntries()).length, 2);
      },
    );
  }

  test(
    'variants are independent, uniquely named and share a selectable main',
    () async {
      final db = await recipeTestDatabase();
      addTearDown(db.close);
      final repo = RecipeRepository(database: () async => db);
      final main = await repo.save(
        bakingRecipe()
          ..notes.add(RecipeNote(title: 'Dough', body: 'Fold gently')),
      );
      final variant = await repo.createVariant(main, 'Overnight');
      await expectLater(
        repo.createVariant(main, ' overnight '),
        throwsFormatException,
      );
      await expectLater(repo.createVariant(main, ''), throwsFormatException);
      expect(await repo.hasDuplicateName('Bread', exceptId: variant), isFalse);
      final data = await repo.load(variant);
      data.notes.single.body = 'Try cold proof';
      data.stages.first.durationMax = 240;
      await repo.save(data, id: variant, changeDescription: 'Longer proof');
      expect((await repo.load(main)).notes.single.body, 'Fold gently');
      expect((await repo.load(main)).stages.first.durationMax, 120);
      final familyId = (await repo.loadRecord(main)).family!.id;
      await repo.setMainVariant(familyId, variant);
      await repo.renameFamily(familyId, 'My sourdough');
      final entries = await repo.listFamilyEntries();
      expect(entries.single.id, variant);
      expect(entries.single.name, 'My sourdough');
      expect(entries.single.variantCount, 2);
      expect((await repo.revisions(variant)).length, 2);
      final separate = await repo.save(RecipeData(name: 'Other'));
      await expectLater(
        repo.setMainVariant(familyId, separate),
        throwsStateError,
      );
    },
  );

  test(
    'only changed saves create history; restore appends and respects ownership',
    () async {
      final db = await recipeTestDatabase();
      addTearDown(db.close);
      final repo = RecipeRepository(database: () async => db);
      final id = await repo.save(RecipeData(name: 'Bread'));
      final original = (await repo.revisions(id)).single;
      await repo.save(
        await repo.load(id),
        id: id,
        changeDescription: 'No content change',
      );
      expect((await repo.revisions(id)).length, 1);
      await repo.save(
        RecipeData(name: 'Better bread'),
        id: id,
        changeDescription: 'Improved',
      );
      await repo.restore(id, original.id, changeDescription: 'Restore');
      expect((await repo.load(id)).name, 'Bread');
      final history = await repo.revisions(id);
      expect(history.length, 3);
      expect(history.first.description, 'Restore');
      expect(history.last.content, original.content);
      final other = await repo.save(RecipeData(name: 'Other'));
      await expectLater(repo.restore(other, original.id), throwsStateError);
    },
  );

  test('family notes and variant history restore independently; baking snapshots stay frozen', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final id = await repo.save(
      bakingRecipe()..notes.add(RecipeNote(title: 'Try', body: 'More water')),
    );
    final familyId = (await repo.loadRecord(id)).family!.id;
    final original = (await repo.revisions(id)).single;
    await repo.saveSharedNotes(familyId, [
      RecipeNote(title: 'Handling', body: 'Wet hands'),
    ]);
    final oldNotes = (await repo.revisions(familyId, sharedNotes: true)).first;
    final record = await repo.loadRecord(id);
    final bakes = BakingRepository(database: () async => db);
    final session = await bakes.openForRecipe(
      id,
      record.recipe,
      DateTime(2026),
      familyName: record.family!.name,
      variantName: record.variant!.name,
      sharedNotes: record.family!.notes,
    );
    await repo.saveSharedNotes(familyId, [
      RecipeNote(title: 'Handling', body: 'Oiled hands'),
    ]);
    await repo.restore(id, original.id);
    expect(
      (await repo.loadRecord(id)).family!.notes.single.body,
      'Oiled hands',
    );
    await repo.save(RecipeData(name: 'New recipe'), id: id);
    await repo.restore(familyId, oldNotes.id, sharedNotes: true);
    expect((await repo.load(id)).name, 'New recipe');
    expect((await repo.loadRecord(id)).family!.notes.single.body, 'Wet hands');
    final frozen = await bakes.load(session.id!);
    expect(frozen.recipe.name, 'Bread');
    expect(frozen.recipe.notes.single.body, 'More water');
    expect(frozen.sharedNotes.single.body, 'Wet hands');
    expect(frozen.variantName, 'Standard');
  });

  test('revision write failures roll back content and do not leave orphan families', () async {
    final db = await recipeTestDatabase();
    addTearDown(db.close);
    final repo = RecipeRepository(database: () async => db);
    final id = await repo.save(RecipeData(name: 'Bread'));
    await db.execute(
      "CREATE TRIGGER fail_revision BEFORE INSERT ON recipe_revisions BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
    );
    await expectLater(
      repo.save(RecipeData(name: 'Changed'), id: id),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      repo.save(RecipeData(name: 'New')),
      throwsA(isA<DatabaseException>()),
    );
    expect((await repo.load(id)).name, 'Bread');
    expect((await repo.listFamilyEntries()).length, 1);
    expect((await repo.revisions(id)).length, 1);
    await db.execute(
      "CREATE TRIGGER fail_notes BEFORE INSERT ON family_note_revisions BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
    );
    final family = (await repo.loadRecord(id)).family!;
    await expectLater(
      repo.saveSharedNotes(family.id, [RecipeNote(title: 'Test')]),
      throwsA(isA<DatabaseException>()),
    );
    expect((await repo.loadFamily(family.id)).notes, isEmpty);
  });

  test('native imports retain notes, ignore IDs and default missing notes', () {
    final recipe = RecipeImport.parse(
      '{"id":999,"family_id":77,"name":"Bread","notes":[{"title":"Try","body":"Less yeast"}]}',
    ).single;
    expect(recipe.copy().notes.single.body, 'Less yeast');
    expect(recipe.toJson().containsKey('family_id'), isFalse);
    expect(RecipeData.fromJson({'name': 'Old'}).notes, isEmpty);
  });
}
