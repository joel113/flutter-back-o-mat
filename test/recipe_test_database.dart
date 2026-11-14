import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_back_o_mat/baking/baking_schema.dart';
import 'package:flutter_back_o_mat/recipe/data/recipe_schema.dart';

Future<void> createLegacyRecipes(DatabaseExecutor db) =>
    db.execute('''CREATE TABLE recipes_json(
  id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
  recipe_data TEXT NOT NULL, last_modified INTEGER NOT NULL)''');

Future<Database> recipeTestDatabase() async {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 5,
      singleInstance: false,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await createLegacyRecipes(db);
        await createBakingSessions(db);
        await createRecipeFamilies(db);
        await createRecipeOrdering(db);
        await createBundledRecipeImports(db);
      },
    ),
  );
}
