import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class RecipeJsonEntry {
  final int id;
  final String name;
  final String jsonData;
  final DateTime lastModified;

  RecipeJsonEntry({
    required this.id,
    required this.name,
    required this.jsonData,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'recipe_data': jsonData,
      'last_modified': lastModified?.millisecondsSinceEpoch,
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
    String path = join(documentsDirectory.path, 'recipes_json_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
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
  }

  Future<int> insertRecipeJson(int id, String name, String jsonString) async {
    final db = await database;
    return await db.insert(
      'recipes_json',
      {
        'id': id,
        'name': name,
        'recipe_data': jsonString,
        'last_modified': DateTime
            .now()
            .millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Or .ignore if you don't want to update
    );
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
        'recipes_json', orderBy: 'name ASC');

    return List.generate(maps.length, (i) {
      return RecipeJsonEntry.fromMap(maps[i]);
    });
  }

  Future<int> updateRecipeJson(int id, String name, String jsonString) async {
    final db = await database;
    return await db.update(
      'recipes_json',
      {
        'name': name,
        'recipe_data': jsonString,
        'last_modified': DateTime
            .now()
            .millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRecipeJson(int id) async {
    final db = await database;
    return await db.delete(
      'recipes_json',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('recipes_json');
    print("JSON Recipe Database cleared.");
  }
}
