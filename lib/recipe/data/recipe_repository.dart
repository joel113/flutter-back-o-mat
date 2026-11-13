import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../util/db/db.dart';
import 'recipe_data.dart';
import 'recipe_family.dart';

class RecipeRepository {
  RecipeRepository({Future<Database> Function()? database})
    : _database = database ?? (() => DatabaseHelperJson().database);
  final Future<Database> Function() _database;

  RecipeData _decode(Map<String, Object?> row) => RecipeData.fromJson(
    jsonDecode(row['recipe_data'] as String) as Map<String, dynamic>,
  );

  Future<Map<String, Object?>> _row(
    DatabaseExecutor db,
    String table,
    int id,
  ) async {
    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('missingRecord');
    return rows.single;
  }

  Future<RecipeData> load(int id) async =>
      _decode(await _row(await _database(), 'recipes_json', id));

  Future<RecipeFamily> _family(DatabaseExecutor db, int id) async {
    final family = await _row(db, 'recipe_families', id);
    final members = await db.query(
      'recipe_variants',
      where: 'family_id = ?',
      whereArgs: [id],
      orderBy: 'recipe_id ASC',
    );
    final variants = <RecipeVariant>[];
    for (final member in members) {
      final recipeId = member['recipe_id'] as int;
      variants.add(
        RecipeVariant(
          id: recipeId,
          name: member['variant_name'] as String,
          recipe: _decode(await _row(db, 'recipes_json', recipeId)),
        ),
      );
    }
    return RecipeFamily(
      id: id,
      name: family['name'] as String,
      mainRecipeId: family['main_recipe_id'] as int,
      notes: decodeNotes(family['notes_json'] as String),
      variants: variants,
    );
  }

  Future<RecipeFamily> loadFamily(int id) async =>
      _family(await _database(), id);

  Future<RecipeRecord> loadRecord(int id) async {
    final db = await _database();
    return db.transaction((txn) => _record(txn, id));
  }

  Future<RecipeRecord> _record(DatabaseExecutor db, int id) async {
    final data = _decode(await _row(db, 'recipes_json', id));
    final members = await db.query(
      'recipe_variants',
      where: 'recipe_id = ?',
      whereArgs: [id],
    );
    if (members.isEmpty) throw StateError('missingFamily');
    return RecipeRecord(
      id: id,
      recipe: data,
      family: await _family(db, members.single['family_id'] as int),
    );
  }

  /// Resolve all selected sources in one read transaction for a coherent snapshot.
  Future<List<RecipeRecord>> loadBakingRecords(
    int rootId,
    Set<int> selected,
  ) async {
    final db = await _database();
    return db.transaction((txn) async {
      final root = await _record(txn, rootId);
      if (!root.recipe.preparations
          .map((p) => p.recipeId)
          .toSet()
          .containsAll(selected)) {
        throw const FormatException('preparations');
      }
      return [root, for (final id in selected) await _record(txn, id)];
    });
  }

  Future<void> _validatePreparations(
    DatabaseExecutor db,
    RecipeData recipe,
    int id,
  ) async {
    if (recipe.preparations.isEmpty) return;
    final records = {
      for (final row in await db.query('recipes_json'))
        row['id'] as int: _decode(row),
    };
    records[id] = recipe;
    final visiting = <int>{}, visited = <int>{};
    void visit(int current) {
      if (visiting.contains(current)) {
        throw const FormatException('preparations');
      }
      if (!visited.add(current)) return;
      final data = records[current];
      if (data == null) throw const FormatException('preparations');
      visiting.add(current);
      for (final link in data.preparations) {
        visit(link.recipeId);
      }
      visiting.remove(current);
    }

    visit(id);
  }

  Future<List<RecipeJsonEntry>> listFamilyEntries() async {
    final db = await _database();
    final rows = await db.rawQuery('''SELECT r.*, f.name AS family_name,
      f.id AS family_id, (SELECT count(*) FROM recipe_variants v WHERE v.family_id = f.id) AS variant_count
      FROM recipe_families f JOIN recipes_json r ON r.id = f.main_recipe_id
      ORDER BY f.sort_order, f.id''');
    return rows
        .map(
          (row) => RecipeJsonEntry(
            id: row['id'] as int,
            name: row['family_name'] as String,
            jsonData: row['recipe_data'] as String,
            lastModified: DateTime.fromMillisecondsSinceEpoch(
              row['last_modified'] as int,
            ),
            familyId: row['family_id'] as int,
            variantCount: row['variant_count'] as int,
          ),
        )
        .toList();
  }

  Future<void> saveFamilyOrder(List<int> familyIds) async {
    final db = await _database();
    await db.transaction((txn) async {
      final existing = await txn.query('recipe_families', columns: ['id']);
      final ids = existing.map((row) => row['id'] as int).toSet();
      if (familyIds.length != ids.length ||
          familyIds.toSet().length != familyIds.length ||
          !ids.containsAll(familyIds)) {
        throw const FormatException('staleRecipeOrder');
      }
      for (var i = 0; i < familyIds.length; i++) {
        await txn.update(
          'recipe_families',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [familyIds[i]],
        );
      }
    });
  }

  Future<bool> hasDuplicateName(String name, {int? exceptId}) async {
    final db = await _database();
    // Editing a variant may keep the same title as its siblings.
    int? familyId;
    if (exceptId != null) {
      final members = await db.query(
        'recipe_variants',
        where: 'recipe_id = ?',
        whereArgs: [exceptId],
      );
      familyId = members.firstOrNull?['family_id'] as int?;
    }
    final rows = await db.rawQuery(
      '''SELECT r.id, v.family_id FROM recipes_json r
      JOIN recipe_variants v ON v.recipe_id = r.id WHERE lower(trim(r.name)) = ?''',
      [name.trim().toLowerCase()],
    );
    return rows.any(
      (row) => row['id'] != exceptId && row['family_id'] != familyId,
    );
  }

  Future<int> save(
    RecipeData recipe, {
    int? id,
    String changeDescription = '',
  }) async {
    final db = await _database();
    return db.transaction(
      (txn) => _save(txn, recipe, id: id, description: changeDescription),
    );
  }

  Future<int> _save(
    DatabaseExecutor txn,
    RecipeData recipe, {
    int? id,
    int? familyId,
    String variantName = 'Standard',
    String description = '',
    bool forceRevision = false,
  }) async {
    if (recipe.validate().isNotEmpty) {
      throw const FormatException('invalidRecipe');
    }
    final content = jsonEncode(recipe.toJson());
    final now = DateTime.now().millisecondsSinceEpoch;
    if (id != null) {
      final previous = _decode(await _row(txn, 'recipes_json', id));
      if (!forceRevision && jsonEncode(previous.toJson()) == content) return id;
    }
    final row = <String, Object?>{
      'name': recipe.name.trim(),
      'recipe_data': content,
      'last_modified': now,
    };
    final recipeId = id ?? await txn.insert('recipes_json', row);
    await _validatePreparations(txn, recipe, recipeId);
    final stored = recipe.toJson()..['id'] = recipeId;
    row['recipe_data'] = jsonEncode(stored);
    await txn.update(
      'recipes_json',
      row,
      where: 'id = ?',
      whereArgs: [recipeId],
    );
    if (id == null) {
      final nextPosition = familyId == null
          ? ((await txn.rawQuery(
                  'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_position FROM recipe_families',
                )).single['next_position']
                as int)
          : 0;
      final family =
          familyId ??
          await txn.insert('recipe_families', {
            'name': recipe.name.trim(),
            'main_recipe_id': recipeId,
            'notes_json': '[]',
            'sort_order': nextPosition,
          });
      await txn.insert('recipe_variants', {
        'recipe_id': recipeId,
        'family_id': family,
        'variant_name': variantName.trim(),
        'variant_key': variantName.trim().toLowerCase(),
      });
      if (familyId == null) {
        await txn.insert('family_note_revisions', {
          'family_id': family,
          'content': '[]',
          'description': '',
          'created_at': now,
        });
      }
    }
    await txn.insert('recipe_revisions', {
      'recipe_id': recipeId,
      'content': content,
      'description': description.trim(),
      'created_at': now,
    });
    return recipeId;
  }

  Future<int> createVariant(int sourceId, String name) async {
    if (name.trim().isEmpty) throw const FormatException('variantName');
    final db = await _database();
    return db.transaction((txn) async {
      final members = await txn.query(
        'recipe_variants',
        where: 'recipe_id = ?',
        whereArgs: [sourceId],
      );
      if (members.isEmpty) throw StateError('missingRecipe');
      final familyId = members.single['family_id'] as int;
      final existing = await txn.query(
        'recipe_variants',
        where: 'family_id = ? AND variant_key = ?',
        whereArgs: [familyId, name.trim().toLowerCase()],
      );
      if (existing.isNotEmpty) throw const FormatException('duplicateVariant');
      return _save(
        txn,
        _decode(await _row(txn, 'recipes_json', sourceId)),
        familyId: familyId,
        variantName: name,
      );
    });
  }

  Future<void> setMainVariant(int familyId, int recipeId) async {
    final db = await _database();
    await db.transaction((txn) async {
      final member = await txn.query(
        'recipe_variants',
        where: 'family_id = ? AND recipe_id = ?',
        whereArgs: [familyId, recipeId],
      );
      if (member.isEmpty) throw StateError('missingVariant');
      await txn.update(
        'recipe_families',
        {'main_recipe_id': recipeId},
        where: 'id = ?',
        whereArgs: [familyId],
      );
    });
  }

  Future<void> renameFamily(int familyId, String name) async {
    if (name.trim().isEmpty) throw const FormatException('familyName');
    final db = await _database();
    if (await db.update(
          'recipe_families',
          {'name': name.trim()},
          where: 'id = ?',
          whereArgs: [familyId],
        ) !=
        1) {
      throw StateError('missingFamily');
    }
  }

  static List<RecipeNote> decodeNotes(String content) =>
      (jsonDecode(content) as List)
          .map((e) => RecipeNote.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

  Future<void> saveSharedNotes(
    int familyId,
    List<RecipeNote> notes, {
    String changeDescription = '',
  }) async {
    final db = await _database();
    await db.transaction(
      (txn) => _saveNotes(txn, familyId, notes, changeDescription),
    );
  }

  Future<void> _saveNotes(
    DatabaseExecutor txn,
    int familyId,
    List<RecipeNote> notes,
    String description, {
    bool forceRevision = false,
  }) async {
    if (notes.any((n) => n.title.trim().isEmpty)) {
      throw const FormatException('noteTitle');
    }
    final family = await _row(txn, 'recipe_families', familyId);
    final content = jsonEncode(notes.map((n) => n.toJson()).toList());
    if (!forceRevision && family['notes_json'] == content) return;
    await txn.update(
      'recipe_families',
      {'notes_json': content},
      where: 'id = ?',
      whereArgs: [familyId],
    );
    await txn.insert('family_note_revisions', {
      'family_id': familyId,
      'content': content,
      'description': description.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<RecipeRevision>> revisions(
    int ownerId, {
    bool sharedNotes = false,
  }) async {
    final db = await _database();
    final rows = await db.query(
      sharedNotes ? 'family_note_revisions' : 'recipe_revisions',
      where: '${sharedNotes ? 'family_id' : 'recipe_id'} = ?',
      whereArgs: [ownerId],
      orderBy: 'id DESC',
    );
    return rows
        .map(
          (r) => RecipeRevision(
            id: r['id'] as int,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              r['created_at'] as int,
            ),
            description: r['description'] as String,
            content: r['content'] as String,
          ),
        )
        .toList();
  }

  Future<void> restore(
    int ownerId,
    int revisionId, {
    bool sharedNotes = false,
    String changeDescription = '',
  }) async {
    final db = await _database();
    await db.transaction((txn) async {
      final rows = await txn.query(
        sharedNotes ? 'family_note_revisions' : 'recipe_revisions',
        where: 'id = ? AND ${sharedNotes ? 'family_id' : 'recipe_id'} = ?',
        whereArgs: [revisionId, ownerId],
      );
      if (rows.isEmpty) throw StateError('missingRevision');
      final content = rows.single['content'] as String;
      if (sharedNotes) {
        await _saveNotes(
          txn,
          ownerId,
          decodeNotes(content),
          changeDescription,
          forceRevision: true,
        );
      } else {
        await _save(
          txn,
          RecipeData.fromJson(jsonDecode(content) as Map<String, dynamic>),
          id: ownerId,
          description: changeDescription,
          forceRevision: true,
        );
      }
    });
  }
}
