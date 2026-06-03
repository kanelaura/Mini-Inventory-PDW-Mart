import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'supplier_database_helper.dart';

class DatabaseHelper {
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  static Future<Database>? _databaseFuture;

  // Cached product count per category for synchronous UI helper
  final Map<String, int> _categoryProductCounts = {};

  Future<Database> get database async {
    debugPrint('DatabaseHelper: database getter called. _database: $_database, _databaseFuture: $_databaseFuture');
    if (_database != null) {
      debugPrint('DatabaseHelper: returning cached _database.');
      return _database!;
    }
    debugPrint('DatabaseHelper: initializing database future...');
    _databaseFuture ??= _initDatabase();
    debugPrint('DatabaseHelper: awaiting database future...');
    _database = await _databaseFuture;
    debugPrint('DatabaseHelper: database initialized successfully. _database: $_database');
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pdw_mart.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        stock INTEGER DEFAULT 0,
        price REAL DEFAULT 0,
        supplier TEXT,
        sku TEXT,
        satuan TEXT,
        harga_beli REAL DEFAULT 0,
        min_stock_alert INTEGER DEFAULT 5,
        lokasi_rak TEXT,
        description TEXT,
        image_url TEXT
      )
    ''');

    // 2. Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT,
        modified_at TEXT
      )
    ''');

    // 3. Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        total_pay REAL,
        discount REAL DEFAULT 0,
        status TEXT,
        note TEXT,
        timestamp TEXT
      )
    ''');

    // 4. Create transaction_items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT,
        product_name TEXT,
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    // 5. Create suppliers table
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        phone TEXT,
        location TEXT,
        is_active INTEGER DEFAULT 1,
        product_count INTEGER DEFAULT 0
      )
    ''');

    // Seed default categories
    final now = DateTime.now().toIso8601String();
    await db.insert('categories', {'id': '1', 'name': 'Minuman', 'emoji': '🥤', 'modified_at': now});
    await db.insert('categories', {'id': '2', 'name': 'Makanan', 'emoji': '🍱', 'modified_at': now});
    await db.insert('categories', {'id': '3', 'name': 'Elektronik', 'emoji': '⚡', 'modified_at': now});
    await db.insert('categories', {'id': '4', 'name': 'Lainnya', 'emoji': '📦', 'modified_at': now});
    await db.insert('categories', {'id': '5', 'name': 'Kebersihan', 'emoji': '🧹', 'modified_at': now});

    // Seed default suppliers
    await db.insert('suppliers', {
      'id': '1',
      'name': 'PT Unilever Indonesia',
      'type': 'Distributor',
      'phone': '08112345678',
      'location': 'Jakarta Selatan',
      'is_active': 1,
      'product_count': 15
    });
    await db.insert('suppliers', {
      'id': '2',
      'name': 'CV Maju Jaya Makmur',
      'type': 'Grosir',
      'phone': '08129876543',
      'location': 'Surabaya',
      'is_active': 1,
      'product_count': 8
    });
    await db.insert('suppliers', {
      'id': '3',
      'name': 'UD Sumber Sandang',
      'type': 'Grosir',
      'phone': '08571122334',
      'location': 'Bandung',
      'is_active': 0,
      'product_count': 4
    });
    await db.insert('suppliers', {
      'id': '4',
      'name': 'PT Indofood CBP',
      'type': 'Distributor',
      'phone': '0811888999',
      'location': 'Semarang',
      'is_active': 1,
      'product_count': 22
    });
  }

  // --- PRODUCTS CRUD ---

  Future<List<Product>> getProducts({String? search, String? category, bool sortAscending = true}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (search != null && search.trim().isNotEmpty) {
      final query = '%${search.trim().toLowerCase()}%';
      whereClause = '(LOWER(name) LIKE ? OR LOWER(supplier) LIKE ?)';
      whereArgs = [query, query];
    }

    if (category != null && category != 'Semua') {
      if (whereClause != null) {
        whereClause += ' AND category = ?';
        whereArgs!.add(category);
      } else {
        whereClause = 'category = ?';
        whereArgs = [category];
      }
    }

    final orderBy = 'name ${sortAscending ? "ASC" : "DESC"}';

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // --- PRODUCTS AGGREGATIONS ---

  Future<int> getTotalProductsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalProductCount() => getTotalProductsCount();

  Future<int> getLowStockCount({int threshold = 5}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE stock <= ?',
      [threshold],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Product>> getLowStockItems({int threshold = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'stock <= ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // --- CATEGORIES CRUD ---

  Future<List<CategoryModel>> getCategories({String? search}) async {
    final db = await database;
    
    // Fetch product counts dynamically to populate cache for getProductCount
    final List<Map<String, dynamic>> countMaps = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM products GROUP BY category'
    );
    _categoryProductCounts.clear();
    for (final row in countMaps) {
      final cat = row['category'] as String? ?? '';
      final count = row['count'] as int? ?? 0;
      _categoryProductCounts[cat] = count;
    }

    String? whereClause;
    List<dynamic>? whereArgs;

    if (search != null && search.trim().isNotEmpty) {
      whereClause = 'LOWER(name) LIKE ?';
      whereArgs = ['%${search.trim().toLowerCase()}%'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return CategoryModel(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        emoji: maps[i]['emoji'] as String? ?? '📦',
        modifiedAt: DateTime.parse(maps[i]['modified_at'] as String),
      );
    });
  }

  Future<void> insertCategory(String name) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final emoji = _getEmojiForCategory(name);
    await db.insert('categories', {
      'id': id,
      'name': name,
      'emoji': emoji,
      'modified_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateCategory(String id, String newName) async {
    final db = await database;
    final emoji = _getEmojiForCategory(newName);
    await db.update(
      'categories',
      {
        'name': newName,
        'emoji': emoji,
        'modified_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCategoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getProductCountForCategory(String categoryName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category = ?',
      [categoryName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Synchronous lookup from cached category counts (used in categories screen UI builder)
  int getProductCount(String categoryName) {
    return _categoryProductCounts[categoryName] ?? 0;
  }

  // --- TRANSACTIONS & REPORTING ---

  Future<void> processTransaction({
    required String invoiceId,
    required double totalPay,
    required double discount,
    String note = '',
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Insert transaction master
      await txn.insert('transactions', {
        'id': invoiceId,
        'total_pay': totalPay,
        'discount': discount,
        'status': 'Selesai',
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 2. Insert items and decrement stock
      for (final item in cartItems) {
        final productId = item['product_id']?.toString() ?? '';
        final name = item['name']?.toString() ?? '';
        final quantity = item['quantity'] as int? ?? 0;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;

        await txn.insert('transaction_items', {
          'transaction_id': invoiceId,
          'product_name': name,
          'quantity': quantity,
          'price': price,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
          [quantity, productId],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    String? search,
    String? dateFilter,
    DateTimeRange? customDateRange,
    String? statusFilter,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Date Filters
    final now = DateTime.now();
    if (dateFilter != null && dateFilter != 'Semua') {
      if (dateFilter == 'Hari Ini') {
        final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
        whereClause += 'timestamp >= ?';
        whereArgs.add(startOfToday);
      } else if (dateFilter == 'Minggu Ini') {
        final daysToSubtract = now.weekday - 1;
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract)).toIso8601String();
        whereClause += 'timestamp >= ?';
        whereArgs.add(startOfWeek);
      } else if (dateFilter == 'Bulan Ini') {
        final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
        whereClause += 'timestamp >= ?';
        whereArgs.add(startOfMonth);
      } else if (dateFilter == 'Custom' && customDateRange != null) {
        final start = DateTime(customDateRange.start.year, customDateRange.start.month, customDateRange.start.day).toIso8601String();
        final end = DateTime(customDateRange.end.year, customDateRange.end.month, customDateRange.end.day, 23, 59, 59, 999).toIso8601String();
        whereClause += 'timestamp >= ? AND timestamp <= ?';
        whereArgs.addAll([start, end]);
      }
    }

    // Search Filter (by transaction id or item product name)
    if (search != null && search.trim().isNotEmpty) {
      final searchQuery = '%${search.trim().toLowerCase()}%';
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += '(LOWER(id) LIKE ? OR EXISTS (SELECT 1 FROM transaction_items ti WHERE ti.transaction_id = transactions.id AND LOWER(ti.product_name) LIKE ?))';
      whereArgs.addAll([searchQuery, searchQuery]);
    }

    final List<Map<String, dynamic>> txMaps = await db.query(
      'transactions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    List<Map<String, dynamic>> filtered = [];
    for (final txMap in txMaps) {
      final txId = txMap['id'] as String;
      final items = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [txId],
      );
      
      filtered.add({
        'id': txId,
        'total_pay': (txMap['total_pay'] as num?)?.toDouble() ?? 0.0,
        'discount': (txMap['discount'] as num?)?.toDouble() ?? 0.0,
        'status': txMap['status'] as String,
        'note': txMap['note'] as String?,
        'timestamp': DateTime.parse(txMap['timestamp'] as String),
        'items': items.map((item) => {
          'name': item['product_name'] as String,
          'quantity': item['quantity'] as int,
          'price': (item['price'] as num?)?.toDouble() ?? 0.0,
        }).toList(),
      });
    }

    if (statusFilter != null) {
      filtered = filtered.where((tx) => tx['status'] == statusFilter).toList();
    }

    return filtered;
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Get the items associated with this transaction first to restore stock
      final List<Map<String, dynamic>> items = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      // 2. Restore stock for each item by matching the product name
      for (final item in items) {
        final productName = item['product_name'] as String? ?? '';
        final quantity = item['quantity'] as int? ?? 0;

        if (productName.isNotEmpty && quantity > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE name = ?',
            [quantity, productName],
          );
        }
      }

      // 3. Delete the transaction items and the transaction master
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<void> updateTransactionStatus(String transactionId, String newStatus) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Get the current transaction master to check its old status
      final List<Map<String, dynamic>> txList = await txn.query(
        'transactions',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (txList.isEmpty) return;
      final oldStatus = txList.first['status'] as String? ?? 'Selesai';

      if (oldStatus == newStatus) return; // No change

      // 2. Query items to calculate stock adjustments
      final List<Map<String, dynamic>> items = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      // 3. Perform stock adjustment based on state transition
      if (oldStatus == 'Selesai' && (newStatus == 'Dibatalkan' || newStatus == 'Pending')) {
        // Restore stock (increment)
        for (final item in items) {
          final productName = item['product_name'] as String? ?? '';
          final quantity = item['quantity'] as int? ?? 0;
          if (productName.isNotEmpty && quantity > 0) {
            await txn.rawUpdate(
              'UPDATE products SET stock = stock + ? WHERE name = ?',
              [quantity, productName],
            );
          }
        }
      } else if ((oldStatus == 'Dibatalkan' || oldStatus == 'Pending') && newStatus == 'Selesai') {
        // Reduce stock (decrement)
        for (final item in items) {
          final productName = item['product_name'] as String? ?? '';
          final quantity = item['quantity'] as int? ?? 0;
          if (productName.isNotEmpty && quantity > 0) {
            await txn.rawUpdate(
              'UPDATE products SET stock = MAX(0, stock - ?) WHERE name = ?',
              [quantity, productName],
            );
          }
        }
      }

      // 4. Update the transaction status
      await txn.update(
        'transactions',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<Map<String, double>> getTransactionSummaryReporting() async {
    final db = await database;
    final now = DateTime.now();

    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final daysToSubtract = now.weekday - 1;
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract)).toIso8601String();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    // Query for today
    final todayRes = await db.rawQuery(
      "SELECT SUM(total_pay) as sum FROM transactions WHERE status = 'Selesai' AND timestamp >= ?",
      [startOfToday],
    );
    final todaySum = (todayRes.first['sum'] as num?)?.toDouble() ?? 0.0;

    // Query for week
    final weekRes = await db.rawQuery(
      "SELECT SUM(total_pay) as sum FROM transactions WHERE status = 'Selesai' AND timestamp >= ?",
      [startOfWeek],
    );
    final weekSum = (weekRes.first['sum'] as num?)?.toDouble() ?? 0.0;

    // Query for month
    final monthRes = await db.rawQuery(
      "SELECT SUM(total_pay) as sum FROM transactions WHERE status = 'Selesai' AND timestamp >= ?",
      [startOfMonth],
    );
    final monthSum = (monthRes.first['sum'] as num?)?.toDouble() ?? 0.0;

    return {
      'hari_ini': todaySum,
      'minggu_ini': weekSum,
      'bulan_ini': monthSum,
    };
  }

  Future<List<TransactionItem>> getRecentTransactions({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT t.id, ti.product_name, t.timestamp, ti.quantity 
      FROM transactions t 
      JOIN transaction_items ti ON t.id = ti.transaction_id 
      WHERE t.status = 'Selesai' 
      ORDER BY t.timestamp DESC 
      LIMIT ?
    ''', [limit]);

    return List.generate(rows.length, (i) {
      return TransactionItem(
        id: rows[i]['id'] as String,
        productName: rows[i]['product_name'] as String,
        dateTime: DateTime.parse(rows[i]['timestamp'] as String),
        quantityChange: -(rows[i]['quantity'] as int),
        type: 'sale',
      );
    });
  }

  Future<int> getTodayTransactionsCount() async {
    final db = await database;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transactions WHERE status = 'Selesai' AND timestamp >= ?",
      [startOfToday],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSuppliersCount() async {
    return SupplierDatabaseHelper.instance.getTotalSupplierCount();
  }

  // --- HELPER ---

  String _getEmojiForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('minum') || lower.contains('susu') || lower.contains('kopi') || lower.contains('coke')) {
      return '🥤';
    } else if (lower.contains('makan') || lower.contains('mie') || lower.contains('roti') || lower.contains('camilan') || lower.contains('snack')) {
      return '🍱';
    } else if (lower.contains('elektronik') || lower.contains('kabel') || lower.contains('hp') || lower.contains('lampu')) {
      return '⚡';
    } else if (lower.contains('bersih') || lower.contains('sapu') || lower.contains('sabun') || lower.contains('detergen')) {
      return '🧹';
    }
    return '📦'; // Default/Lainnya fallback
  }
}
