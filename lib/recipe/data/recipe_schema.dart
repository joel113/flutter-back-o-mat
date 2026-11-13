import 'package:sqflite/sqflite.dart';

import '../../baking/baking_schema.dart';

Future<void> createRecipeFamilies(DatabaseExecutor db) async {
  await db.execute('''CREATE TABLE recipe_families(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    main_recipe_id INTEGER,
    notes_json TEXT NOT NULL DEFAULT '[]'
  )''');
  await db.execute('''CREATE TABLE recipe_variants(
    recipe_id INTEGER PRIMARY KEY REFERENCES recipes_json(id),
    family_id INTEGER NOT NULL REFERENCES recipe_families(id),
    variant_name TEXT NOT NULL,
    variant_key TEXT NOT NULL,
    UNIQUE(family_id, variant_key)
  )''');
  await db.execute('''CREATE TABLE recipe_revisions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL REFERENCES recipes_json(id),
    content TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL
  )''');
  await db.execute('''CREATE TABLE family_note_revisions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    family_id INTEGER NOT NULL REFERENCES recipe_families(id),
    content TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL
  )''');
  await db.execute(
    'CREATE INDEX recipe_revision_owner ON recipe_revisions(recipe_id, id)',
  );
  await db.execute(
    'CREATE INDEX family_note_revision_owner ON family_note_revisions(family_id, id)',
  );
}

Future<void> upgradeRecipeDatabase(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  await upgradeBakingDatabase(db, oldVersion, newVersion);
  if (oldVersion < 3 && newVersion >= 3) {
    await createRecipeFamilies(db);
    for (final row in await db.query('recipes_json')) {
      final recipeId = row['id'] as int;
      final familyId = await db.insert('recipe_families', {
        'name': row['name'],
        'main_recipe_id': recipeId,
        'notes_json': '[]',
      });
      await db.insert('recipe_variants', {
        'recipe_id': recipeId,
        'family_id': familyId,
        'variant_name': 'Standard',
        'variant_key': 'standard',
      });
      await db.insert('recipe_revisions', {
        'recipe_id': recipeId,
        'content': row['recipe_data'],
        'description': '',
        'created_at': row['last_modified'],
      });
      await db.insert('family_note_revisions', {
        'family_id': familyId,
        'content': '[]',
        'description': '',
        'created_at': row['last_modified'],
      });
    }
  }
  if (oldVersion < 4 && newVersion >= 4) await createRecipeOrdering(db);
}

/// Preserve the formerly alphabetical order when introducing persisted positions.
Future<void> createRecipeOrdering(DatabaseExecutor db) async {
  await db.execute(
    'ALTER TABLE recipe_families ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
  );
  final families = await db.query(
    'recipe_families',
    columns: ['id'],
    orderBy: 'name COLLATE NOCASE, id',
  );
  for (var i = 0; i < families.length; i++) {
    await db.update(
      'recipe_families',
      {'sort_order': i},
      where: 'id = ?',
      whereArgs: [families[i]['id']],
    );
  }
}
