import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../util/db/db.dart';
import '../recipe/data/recipe_data.dart';
import 'baking_session.dart';
import 'baking_component.dart';

class BakingRepository {
  BakingRepository({Future<Database> Function()? database})
    : _database = database ?? (() => DatabaseHelperJson().database);
  final Future<Database> Function() _database;
  Future<List<BakingSession>> list() async {
    final db = await _database();
    final rows = await db.query(
      'baking_sessions',
      orderBy: 'planned_start ASC, id ASC',
    );
    return rows.map(_decode).toList();
  }

  Future<BakingSession> load(int id) async {
    final db = await _database();
    final rows = await db.query(
      'baking_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('missingSession');
    return _decode(rows.single);
  }

  BakingSession _decode(Map<String, Object?> row) => BakingSession.fromJson(
    jsonDecode(row['session_data'] as String) as Map<String, dynamic>,
    id: row['id'] as int,
  );
  Future<BakingSession> save(BakingSession session) async {
    final db = await _database();
    final data = _values(session);
    final copy = session.copy();
    if (session.id == null) {
      copy.id = await db.insert('baking_sessions', data);
    } else if (await db.update(
          'baking_sessions',
          data,
          where: 'id = ?',
          whereArgs: [session.id],
        ) !=
        1) {
      throw StateError('missingSession');
    }
    return copy;
  }

  Map<String, Object?> _values(BakingSession session) => {
    'recipe_id': session.recipeId,
    'planned_start': session.plannedStart.millisecondsSinceEpoch,
    'session_data': jsonEncode(session.toJson()),
    'status': session.status.name,
  };

  BakingSession? _unfinished(Iterable<BakingSession> sessions, int recipeId) {
    final choices = sessions
        .where(
          (s) =>
              s.recipeId == recipeId && s.status != BakeSessionStatus.completed,
        )
        .toList();
    choices.sort((a, b) {
      if (a.status != b.status) {
        return a.status == BakeSessionStatus.active ? -1 : 1;
      }
      return a.status == BakeSessionStatus.active
          ? b.plannedStart.compareTo(a.plannedStart)
          : a.plannedStart.compareTo(b.plannedStart);
    });
    return choices.isEmpty ? null : choices.first;
  }

  Future<BakingSession?> activeForRecipe(int recipeId) async =>
      _unfinished(await list(), recipeId);

  // Serialize the lookup and creation so repeated clicks cannot duplicate a bake.
  Future<BakingSession> openForRecipe(
    int recipeId,
    RecipeData recipe,
    DateTime start, {
    String? familyName,
    String? variantName,
    List<RecipeNote> sharedNotes = const [],
    Map<int, Set<int>> extraDependencies = const {},
    List<BakingComponent> components = const [],
  }) async {
    final db = await _database();
    return db.transaction((txn) async {
      final rows = await txn.query('baking_sessions');
      final existing = _unfinished(rows.map(_decode), recipeId);
      if (existing != null) return existing;
      final created = BakingSession(
        recipeId: recipeId,
        recipe: recipe,
        plannedStart: start,
        familyName: familyName,
        variantName: variantName,
        sharedNotes: sharedNotes,
        extraDependencies: extraDependencies,
        components: components,
      );
      created.id = await txn.insert('baking_sessions', _values(created));
      return created;
    });
  }

  Future<void> delete(int id) async {
    final db = await _database();
    await db.delete('baking_sessions', where: 'id = ?', whereArgs: [id]);
  }
}
