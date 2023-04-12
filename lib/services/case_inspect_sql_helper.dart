import 'package:sqflite/sqflite.dart' as sql;
import 'package:dfuapp/services/fact_debug.dart';

class CaseViewSQLHelper {
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

  static Future<void> createTables(sql.Database database) async {
    dprint("ItemRefs Tables opened");
  }

  // // Create new item (journal)
  static Future<int> createItem(
    String item_type,
    String item_ref,
    String image_path,
    String fk_case_id,
  ) async {
    final db = await CaseViewSQLHelper.db();

    final data = {
      'item_type': item_type,
      'item_ref': item_ref,
      'image_path': image_path,
      'fk_case_id': fk_case_id,
    };
    final id = await db.insert('case_exhibits', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await CaseViewSQLHelper.db();
    return db.query(
      'case_exhibits',
      orderBy: "item_id",
    );
  }

  // Read all items (journals)
  static Future<int?> getItemCount() async {
    final db = await CaseViewSQLHelper.db();
    int? ItemCount = sql.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM case_exhibits'));
    return ItemCount;
  }

  // Read a single item by id
  static Future<List<Map<String, dynamic>>> getItemsByCase(String case_id) async {
    final db = await CaseViewSQLHelper.db();
    return db.query(
      'case_exhibits',
      where: "fk_case_id = ?",
      whereArgs: [case_id],
    );
  }

  // Read a single item by id
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await CaseViewSQLHelper.db();
    return db.query(
      'case_exhibits',
      where: "item_id = ?",
      whereArgs: [id],
    );
  }

  // Update an item by id
  static Future<int> updateItem(
    int case_id,
    String case_no,
    String case_asignee,
    String image_path,
    String fk_case_asignee,
    String fk_case_id,
  ) async {
    final db = await CaseViewSQLHelper.db();

    final data = {
      'case_id': case_id,
      'case_no': case_no,
      'case_asignee': case_asignee,
      'image_path': image_path,
      'fk_case_asignee': fk_case_asignee,
      'fk_case_id': fk_case_id,
    };

    final result = await db.update('cases', data, where: "case_id = ?", whereArgs: [case_id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int item_id) async {
    final db = await CaseViewSQLHelper.db();
    try {
      await db.delete('case_exhibits', where: "item_id = ?", whereArgs: [item_id]);
    } catch (err) {
      eprint("Something went wrong when deleting an item: $err");
    }
  }
}
