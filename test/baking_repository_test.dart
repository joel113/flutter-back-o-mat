import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_back_o_mat/baking/baking_repository.dart';
import 'package:flutter_back_o_mat/baking/baking_schema.dart';
import 'package:flutter_back_o_mat/baking/baking_session.dart';
import 'package:sqflite/sqflite.dart';

import 'baking_session_test.dart' show bakingRecipe;

class BakingDatabase implements Database, Transaction {
  final rows = <int, Map<String, Object?>>{};
  final statements = <String>[];
  int nextId = 1;
  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction) action, {
    bool? exclusive,
  }) => action(this);
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    statements.add(sql);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = nextId++;
    rows[id] = {...values, 'id': id};
    return id;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final row = rows[whereArgs!.single];
    if (row == null) return 0;
    row.addAll(values);
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async => rows.remove(whereArgs!.single) == null ? 0 : 1;
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (where != null) {
      return [
        if (rows[whereArgs!.single] != null) {...rows[whereArgs.single]!},
      ];
    }
    return rows.values.map((r) => {...r}).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('database upgrade only creates the session table', () async {
    final database = BakingDatabase();
    await upgradeBakingDatabase(database, 1, 2);
    expect(database.statements.length, 1);
    expect(
      database.statements.single,
      contains('CREATE TABLE baking_sessions'),
    );
    expect(database.statements.single, isNot(contains('recipes_json')));
    await upgradeBakingDatabase(database, 2, 2);
    expect(database.statements.length, 1);
  });
  test(
    'sessions persist independently, reopen countdowns, and retain snapshots',
    () async {
      final database = BakingDatabase();
      final repository = BakingRepository(database: () async => database);
      final now = DateTime(2026, 11, 7, 8);
      final saved = await repository.save(
        BakingSession(recipeId: 7, recipe: bakingRecipe(), plannedStart: now),
      );
      final other = await repository.save(
        BakingSession(
          recipeId: 7,
          recipe: bakingRecipe(),
          plannedStart: now.add(const Duration(days: 1)),
        ),
      );
      saved.start(2, now);
      await repository.save(saved);
      final reopened = await repository.load(saved.id!);
      expect(
        reopened.progress[2]!.remaining(now.add(const Duration(minutes: 15))),
        const Duration(minutes: 45),
      );
      expect(
        (await repository.load(other.id!)).status,
        BakeSessionStatus.planned,
      );
      expect((await repository.activeForRecipe(7))!.id, saved.id);
      await repository.delete(other.id!);
      expect((await repository.list()).length, 1);
      expect((await repository.activeForRecipe(7))!.id, saved.id);
      await expectLater(repository.load(other.id!), throwsStateError);
    },
  );
  test('opening a recipe resumes an unfinished snapshot instead of creating duplicates', () async {
    final database = BakingDatabase();
    final repository = BakingRepository(database: () async => database);
    final now = DateTime(2026, 11, 7, 8);
    final first = await repository.openForRecipe(7, bakingRecipe(), now);
    final edited = bakingRecipe()..name = 'Changed recipe';
    final second = await repository.openForRecipe(7, edited, now);
    expect(first.id, second.id);
    expect(second.recipe.name, 'Bread');
    expect((await repository.list()).length, 1);
  });
}
