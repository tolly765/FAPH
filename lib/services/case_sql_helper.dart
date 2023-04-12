import 'package:sqflite/sqflite.dart' as sql;
import 'package:dfuapp/services/fact_debug.dart';

class CaseSQLHelper {
  static Future<void> createTables(sql.Database database) async {
    dprint("CaseSQL Tables opened");
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
  static Future<int> createItem(String case_number, String case_asignee) async {
    final db = await CaseSQLHelper.db();

    final data = {'case_number': case_number, 'case_asignee': case_asignee};
    final id = await db.insert('cases', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await CaseSQLHelper.db();
    return db.query('cases', orderBy: "case_id");
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getItem(String case_asignee) async {
    final db = await CaseSQLHelper.db();
    return db.query('cases', where: "case_asignee = ?", whereArgs: [case_asignee]);
  }

  // Update an item by id
  static Future<int> updateItem(int case_id, String case_no, String case_asignee) async {
    final db = await CaseSQLHelper.db();

    final data = {
      'case_id': case_id,
      'case_no': case_no,
      'case_asignee': case_asignee,
      'createdAt': DateTime.now().toString()
    };

    final result = await db.update('cases', data, where: "case_id = ?", whereArgs: [case_id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int case_id) async {
    final db = await CaseSQLHelper.db();
    try {
      await db.delete('cases', where: "case_id = ?", whereArgs: [case_id]);
    } catch (err) {
      eprint("Something went wrong when deleting an item: $err");
    }
  }
}
