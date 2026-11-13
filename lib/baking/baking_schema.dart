import 'package:sqflite/sqflite.dart';

Future<void> createBakingSessions(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE baking_sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      planned_start INTEGER NOT NULL,
      session_data TEXT NOT NULL,
      status TEXT NOT NULL
    )
  ''');
}

Future<void> upgradeBakingDatabase(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2 && newVersion >= 2) await createBakingSessions(db);
}
