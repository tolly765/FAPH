import 'package:sqflite/sqflite.dart' as sql;
import 'package:dfuapp/services/fact_debug.dart';

class SQLHelper {
  // Init databases
  static Future<void> createTables(sql.Database database) async {
    await database.execute(
        """CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        user TEXT,
        initials TEXT,
        unit TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
    await database.execute(
        """CREATE TABLE cases(
        case_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        case_number TEXT,
        case_asignee TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
    await database.execute(
        """CREATE TABLE case_exhibits(
        item_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        item_type TEXT,
        item_ref TEXT,
        fk_case_id INTEGER,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (fk_case_id) REFERENCES cases (case_id) ON DELETE CASCADE ON UPDATE CASCADE
      )
      """);
    await database.execute(
        """
    CREATE TABLE exhibit_contents(
        exhibit_item_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        exhibit_item_ref TEXT,
        image_path TEXT,
        fk_exhibit_id INTEGER,
        fk_case_id INTEGER,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (fk_exhibit_id) REFERENCES case_exhibits (item_id) ON DELETE CASCADE ON UPDATE CASCADE
        FOREIGN KEY (fk_case_id) REFERENCES cases (case_id) ON DELETE CASCADE ON UPDATE CASCADE
      )""");
    await database.execute(
        """CREATE TABLE image_item_refs(
        image_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        fk_item_ref TEXT,
        filename TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (fk_item_ref) REFERENCES case_items (item_ref) ON DELETE CASCADE ON UPDATE CASCADE
      )
      """);
  }
// id: the id of a item
// title, description: name and description of your activity
// created_at: the time that the item was created. It will be automatically handled by SQLite

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'FAPH.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // Create new item (journal)
  static Future<int> createItem(String user, String initials, String unit) async {
    final db = await SQLHelper.db();

    final data = {'user': user, 'initials': initials, 'unit': unit};
    final id = await db.insert('users', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('users', orderBy: "id");
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('users', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(int id, String user, String initials, String unit) async {
    final db = await SQLHelper.db();

    final data = {
      'user_id': id,
      'user': user,
      'initials': initials,
      'unit': unit,
      'createdAt': DateTime.now().toString()
    };

    final result = await db.update('users', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("users", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      eprint("Something went wrong when deleting an item: $err");
    }
  }
}
