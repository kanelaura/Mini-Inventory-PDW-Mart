import 'package:sqflite/sqflite.dart';
import '../models/supplier_model.dart';
import 'database_helper.dart'; // Reuse the same database instance

class SupplierDatabaseHelper {
  // Singleton pattern
  SupplierDatabaseHelper._privateConstructor();
  static final SupplierDatabaseHelper instance = SupplierDatabaseHelper._privateConstructor();

  // Reuse database from DatabaseHelper (same .db file)
  Future<Database> get database async => await DatabaseHelper.instance.database;

  // READ with search & filter
  Future<List<Supplier>> getSuppliers({String? search, String? filter}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (search != null && search.trim().isNotEmpty) {
      whereClause = 'LOWER(name) LIKE ?';
      whereArgs = ['%${search.trim().toLowerCase()}%'];
    }

    if (filter != null && filter != 'Semua') {
      final int activeVal = filter == 'Aktif' ? 1 : 0;
      if (whereClause != null) {
        whereClause += ' AND is_active = ?';
        whereArgs!.add(activeVal);
      } else {
        whereClause = 'is_active = ?';
        whereArgs = [activeVal];
      }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => _supplierFromMap(maps[i]));
  }

  // AGGREGATIONS
  Future<int> getTotalSupplierCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM suppliers');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getActiveSupplierCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM suppliers WHERE is_active = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCumulativeProductsSupplied() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(product_count) as sum FROM suppliers');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CRUD
  Future<void> insertSupplier(Supplier supplier) async {
    final db = await database;
    await db.insert(
      'suppliers',
      {
        'id': supplier.id,
        'name': supplier.name,
        'type': supplier.type,
        'phone': supplier.phone,
        'location': supplier.location,
        'is_active': supplier.isActive ? 1 : 0,
        'product_count': supplier.productCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await database;
    await db.update(
      'suppliers',
      {
        'name': supplier.name,
        'type': supplier.type,
        'phone': supplier.phone,
        'location': supplier.location,
        'is_active': supplier.isActive ? 1 : 0,
        'product_count': supplier.productCount,
      },
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // HELPER — map SQLite row to Supplier model
  Supplier _supplierFromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'Lainnya',
      phone: map['phone'] as String? ?? '',
      location: map['location'] as String? ?? '',
      isActive: map['is_active'] == 1,
      productCount: map['product_count'] as int? ?? 0,
    );
  }
}
