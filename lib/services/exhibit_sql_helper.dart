import 'package:sqflite/sqflite.dart' as sql;
import 'package:dfuapp/services/fact_debug.dart';

class ExhibitSQLHelper {
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
    String fk_case_id,
  ) async {
    final db = await ExhibitSQLHelper.db();
    final data = {
      'item_type': item_type,
      'item_ref': item_ref,
      'fk_case_id': fk_case_id,
    };
    final id = await db.insert('case_exhibits', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<int?> getItemCount(String caseID) async {
    final db = await ExhibitSQLHelper.db();
    int? itemCount =
        sql.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM case_exhibits WHERE fk_case_id = $caseID'));
    return itemCount;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getUniqueExhibitItems(String fkCaseID) async {
    final db = await ExhibitSQLHelper.db();
    var IDs = await db.rawQuery('''SELECT * FROM case_exhibits 
        JOIN exhibit_contents ON exhibit_contents.fk_exhibit_id = case_exhibits.item_id
        WHERE exhibit_contents.fk_case_id = $fkCaseID
        GROUP BY case_exhibits.item_id''');
    return IDs;
  }

  // Read a single item by id
  static Future<List<Map<String, dynamic>>> getItem(String item_id) async {
    final db = await ExhibitSQLHelper.db();
    return db.query(
      'case_exhibits',
      where: "item_id = ?",
      whereArgs: [item_id],
    );
  }

  static Future<List<Map<String, dynamic>>> getItemByCase(String case_id) async {
    final db = await ExhibitSQLHelper.db();
    return db.query(
      'case_exhibits',
      where: "fk_case_id = ?",
      whereArgs: [case_id],
    );
  }

  // Update an item by id
  static Future<int> updateItem(
    int item_id,
    String item_type,
    String item_ref,
    String fk_case_id,
  ) async {
    final db = await ExhibitSQLHelper.db();
    final data = {
      'item_id': item_id,
      'item_type': item_type,
      'item_ref': item_ref,
      'fk_case_id': fk_case_id,
      'createdAt': DateTime.now().toString()
    };

    final result = await db.update('case_exhibits', data, where: "item_id = ?", whereArgs: [item_id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int exhibit_id) async {
    final db = await ExhibitSQLHelper.db();
    try {
      await db.delete('case_exhibits', where: "item_id = ?", whereArgs: [exhibit_id]);
    } catch (err) {
      eprint("Something went wrong when deleting an item: $err");
    }
  }
}
