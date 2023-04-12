import 'package:sqflite/sqflite.dart' as sql;
import 'package:dfuapp/services/fact_debug.dart';

class ExhibitItemSQLHelper {
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
    String exhibit_item_ref,
    String image_path,
    String fk_exhibit_id,
    String fk_case_id,
  ) async {
    final db = await ExhibitItemSQLHelper.db();

    final data = {
      'exhibit_item_ref': exhibit_item_ref,
      'image_path': image_path,
      'fk_exhibit_id': fk_exhibit_id,
      'fk_case_id': fk_case_id,
    };
    final id = await db.insert('exhibit_contents', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<int?> getItemCount() async {
    final db = await ExhibitItemSQLHelper.db();
    int? ItemCount = sql.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM exhibit_contents'));
    return ItemCount;
  }

  // Read all items (journals)
  static Future<int?> getExhibitItemCount(int exhibitID) async {
    final db = await ExhibitItemSQLHelper.db();
    int? ItemCount = sql.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM exhibit_contents WHERE fk_exhibit_id = $exhibitID'));
    return ItemCount;
  }

  // Read a single item by id
  static Future<List<Map<String, dynamic>>> getItem(String item_id) async {
    final db = await ExhibitItemSQLHelper.db();
    return db.query(
      'exhibit_contents',
      where: "item_id = ?",
      whereArgs: [item_id],
    );
  }

  static Future<List<Map<String, dynamic>>> getFirstExhibitItem(int exhibitID) async {
    final db = await ExhibitItemSQLHelper.db();
    dprint("ExhibitID in query: $exhibitID");
    return db.rawQuery('SELECT * FROM exhibit_contents WHERE fk_exhibit_id = $exhibitID');
  }

  static Future<List<Map<String, dynamic>>> getItemByCase(String caseID) async {
    final db = await ExhibitItemSQLHelper.db();
    return db.query(
      'exhibit_contents',
      where: "fk_case_id = ?",
      whereArgs: [caseID],
    );
  }

  static Future<List<Map<String, dynamic>>> getItemsByExhibit(int exhibitID) async {
    final db = await ExhibitItemSQLHelper.db();
    return db.query(
      'exhibit_contents',
      where: "fk_exhibit_id = ?",
      whereArgs: [exhibitID],
    );
  }

//TODO GET
  // static Future<List<Map<String, dynamic>>> getItemByCase(String caseID) async {
  //   final db = await ExhibitItemSQLHelper.db();
  //   return db.query(
  //     'exhibit_contents',
  //     where: "fk_case_id = ?",
  //     whereArgs: [caseID],
  //   );
  // }

  static Future<List<Map<String, dynamic>>> getContentsByExhibit(String exhibitID) async {
    final db = await ExhibitItemSQLHelper.db();
    return db.query(
      'exhibit_contents',
      where: "fk_exhibit_id = ?",
      whereArgs: [exhibitID],
    );
  }

  // Update an item by id
  static Future<int> updateItem(
    int exhibit_item_id,
    String exhibit_item_ref,
    String image_path,
    String fk_exhibit_id,
    String fk_case_id,
  ) async {
    final db = await ExhibitItemSQLHelper.db();

    final data = {
      'exhibit_item_id': exhibit_item_id,
      'exhibit_item_ref': exhibit_item_ref,
      'image_path': image_path,
      'fk_exhibit_id': fk_exhibit_id,
      'fk_case_id': fk_case_id,
      'createdAt': DateTime.now().toString()
    };

    final result = await db.update('exhibit_contents', data, where: "fk_case_id = ?", whereArgs: [fk_case_id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int exhibit_item_id) async {
    final db = await ExhibitItemSQLHelper.db();
    try {
      await db.delete('exhibit_contents', where: "exhibit_item_id = ?", whereArgs: [exhibit_item_id]);
    } catch (err) {
      eprint("Something went wrong when deleting an item: $err");
    }
  }
}
