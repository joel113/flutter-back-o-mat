import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'dart:convert';

import '../../baking/baking_schema.dart';
import '../../recipe/data/recipe_schema.dart';

class RecipeJsonEntry {
  final int id;
  final String name;
  final String jsonData;
  final DateTime lastModified;
  final int? familyId;
  final int variantCount;

  RecipeJsonEntry({
    required this.id,
    required this.name,
    required this.jsonData,
    required this.lastModified,
    this.familyId,
    this.variantCount = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'recipe_data': jsonData,
      'last_modified': lastModified.millisecondsSinceEpoch,
    };
  }

  static RecipeJsonEntry fromMap(Map<String, dynamic> map) {
    return RecipeJsonEntry(
      id: map['id'],
      name: map['name'],
      jsonData: map['recipe_data'],
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['last_modified']),
    );
  }

  Map<String, dynamic> get parsedJsonData => json.decode(jsonData);
}

class DatabaseHelperJson {
  static final DatabaseHelperJson _instance = DatabaseHelperJson._internal();

  factory DatabaseHelperJson() => _instance;

  DatabaseHelperJson._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = File.fromUri(
      documentsDirectory.uri.resolve('recipes_json_database.db'),
    ).path;
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: upgradeRecipeDatabase,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes_json(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        recipe_data TEXT NOT NULL,
        last_modified INTEGER NOT NULL
      )
    ''');
    await createBakingSessions(db);
    await createRecipeFamilies(db);
    await createRecipeOrdering(db);
  }

  Future<RecipeJsonEntry?> getRecipeJsonById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'recipes_json',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return RecipeJsonEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<RecipeJsonEntry?> getRecipeJsonByName(String name) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'recipes_json',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return RecipeJsonEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<RecipeJsonEntry>> getAllRecipeJsonEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes_json',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return RecipeJsonEntry.fromMap(maps[i]);
    });
  }
}
