import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<dynamic> get database async {
    // Simulated SQLite initialization delay
    await Future.delayed(const Duration(milliseconds: 600));
    return null;
  }

  // Central in-memory product database table
  final List<Product> _mockDatabase = [
    const Product(
        id: '1',
        name: 'Minyak Goreng Sunco 2L',
        category: 'Lainnya',
        stock: 2,
        price: 38000,
        supplier: 'Indofood',
        sku: 'MNG-SNC-2L',
        satuan: 'pcs',
        hargaBeli: 34000,
        minStockAlert: 5,
        lokasiRak: 'A-12-3',
        description: 'Minyak goreng kelapa sawit berkualitas tinggi.'),
    const Product(
        id: '2',
        name: 'Susu UHT Ultra Milk 1L',
        category: 'Minuman',
        stock: 24,
        price: 18500,
        supplier: 'Ultra Jaya',
        sku: 'SSU-ULT-1L',
        satuan: 'box',
        hargaBeli: 15000,
        minStockAlert: 10,
        lokasiRak: 'B-02-1',
        description: 'Susu UHT rasa tawar kaya nutrisi.'),
    const Product(
        id: '3',
        name: 'Indomie Goreng Spontan',
        category: 'Makanan',
        stock: 4,
        price: 3500,
        supplier: 'Indofood',
        sku: 'IDM-GRG-SP',
        satuan: 'pcs',
        hargaBeli: 2800,
        minStockAlert: 10,
        lokasiRak: 'A-01-2',
        description: 'Mie instan goreng favorit masyarakat.'),
    const Product(
        id: '4',
        name: 'Gula Pasir Gulaku 1kg',
        category: 'Lainnya',
        stock: 8,
        price: 16000,
        supplier: 'Gulaku Corp',
        sku: 'GLK-PSR-1K',
        satuan: 'pcs',
        hargaBeli: 13500,
        minStockAlert: 5,
        lokasiRak: 'A-12-4',
        description: 'Gula tebu murni pilihan berkualitas.'),
    const Product(
        id: '5',
        name: 'Coca Cola 250ml',
        category: 'Minuman',
        stock: 15,
        price: 5000,
        supplier: 'Coca Cola Amatil',
        sku: 'COL-CAN-25',
        satuan: 'pcs',
        hargaBeli: 3800,
        minStockAlert: 8,
        lokasiRak: 'B-03-2',
        description: 'Minuman berkarbonasi rasa cola menyegarkan.'),
    const Product(
        id: '6',
        name: 'Kopi Kapal Api 165g',
        category: 'Minuman',
        stock: 0,
        price: 12500,
        supplier: 'Santos Jaya Abadi',
        sku: 'KPI-KPL-16',
        satuan: 'pack',
        hargaBeli: 10200,
        minStockAlert: 5,
        lokasiRak: 'A-04-1',
        description: 'Kopi bubuk hitam mantap dengan gula.'),
    const Product(
        id: '7',
        name: 'Chitato Sapi Panggang',
        category: 'Makanan',
        stock: 11,
        price: 9500,
        supplier: 'Indofood',
        sku: 'CTT-SPG-68',
        satuan: 'pcs',
        hargaBeli: 7900,
        minStockAlert: 10,
        lokasiRak: 'A-01-3',
        description: 'Keripik kentang rasa sapi panggang.'),
    const Product(
        id: '8',
        name: 'Kabel Charger Type-C',
        category: 'Elektronik',
        stock: 20,
        price: 25000,
        supplier: 'Baseus',
        sku: 'KBL-TYP-C1',
        satuan: 'pcs',
        hargaBeli: 15000,
        minStockAlert: 3,
        lokasiRak: 'E-01-1',
        description: 'Kabel charger fast charging Type-C panjang 1m.'),
    const Product(
        id: '9',
        name: 'Stopkontak 5 Lubang',
        category: 'Elektronik',
        stock: 3,
        price: 45000,
        supplier: 'Broco',
        sku: 'STP-BRC-5L',
        satuan: 'pcs',
        hargaBeli: 32000,
        minStockAlert: 2,
        lokasiRak: 'E-02-3',
        description: 'Stopkontak 5 lubang standar SNI.'),
  ];

  // In-memory mock transactions database table
  final List<Map<String, dynamic>> _mockTransactions = [
    {
      'id': 'TRX-20260602-101',
      'total_pay': 38000.0,
      'discount': 0.0,
      'status': 'Selesai',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'items': [
        {'name': 'Minyak Goreng Sunco 2L', 'quantity': 1, 'price': 38000.0},
      ]
    },
    {
      'id': 'TRX-20260602-102',
      'total_pay': 74000.0,
      'discount': 2000.0,
      'status': 'Selesai',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'items': [
        {'name': 'Susu UHT Ultra Milk 1L', 'quantity': 2, 'price': 18500.0},
        {'name': 'Chitato Sapi Panggang', 'quantity': 4, 'price': 9500.0},
      ]
    },
    {
      'id': 'TRX-20260601-201',
      'total_pay': 10500.0,
      'discount': 0.0,
      'status': 'Selesai',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      'items': [
        {'name': 'Indomie Goreng Spontan', 'quantity': 3, 'price': 3500.0},
      ]
    },
    {
      'id': 'TRX-20260531-301',
      'total_pay': 45000.0,
      'discount': 5000.0,
      'status': 'Pending',
      'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      'items': [
        {'name': 'Stopkontak 5 Lubang', 'quantity': 1, 'price': 45000.0},
      ]
    },
    {
      'id': 'TRX-20260528-401',
      'total_pay': 50000.0,
      'discount': 0.0,
      'status': 'Dibatalkan',
      'timestamp': DateTime.now().subtract(const Duration(days: 5, hours: 1)),
      'items': [
        {'name': 'Kabel Charger Type-C', 'quantity': 2, 'price': 25000.0},
      ]
    },
    {
      'id': 'TRX-20260515-501',
      'total_pay': 32000.0,
      'discount': 0.0,
      'status': 'Selesai',
      'timestamp': DateTime.now().subtract(const Duration(days: 18)),
      'items': [
        {'name': 'Gula Pasir Gulaku 1kg', 'quantity': 2, 'price': 16000.0},
      ]
    }
  ];

  // In-memory mock categories database table
  final List<CategoryModel> _mockCategories = [
    CategoryModel(id: '1', name: 'Minuman', emoji: '🥤', modifiedAt: DateTime.now().subtract(const Duration(minutes: 5))),
    CategoryModel(id: '2', name: 'Makanan', emoji: '🍱', modifiedAt: DateTime.now().subtract(const Duration(hours: 1))),
    CategoryModel(id: '3', name: 'Elektronik', emoji: '⚡', modifiedAt: DateTime.now().subtract(const Duration(hours: 3))),
    CategoryModel(id: '4', name: 'Lainnya', emoji: '📦', modifiedAt: DateTime.now().subtract(const Duration(days: 1))),
  ];

  /// Gets the total products count (Mock SQLite aggregation query)
  Future<int> getTotalProductsCount() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockDatabase.length; 
  }

  /// Gets the count of low stock products (Mock SQLite aggregation query)
  Future<int> getLowStockCount({int threshold = 5}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockDatabase.where((p) => p.stock <= threshold).length;
  }

  /// Gets the total transaction count for today (Mock SQLite aggregation query)
  Future<int> getTodayTransactionsCount() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _mockTransactions.where((tx) {
      final ts = tx['timestamp'] as DateTime;
      return ts.isAfter(startOfToday) || ts.isAtSameMomentAs(startOfToday);
    }).length;
  }

  /// Gets the total suppliers count (Mock SQLite aggregation query)
  Future<int> getSuppliersCount() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return 8;
  }

  /// Gets list of products with low stock (Mock SQLite list query)
  Future<List<Product>> getLowStockItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockDatabase.where((p) => p.stock <= 5).toList();
  }

  /// Gets recent transaction records (Mock SQLite list query)
  Future<List<TransactionItem>> getRecentTransactions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final List<TransactionItem> list = [];
    int limit = 5;
    for (final tx in _mockTransactions) {
      final items = tx['items'] as List;
      final ts = tx['timestamp'] as DateTime;
      final status = tx['status'] as String;
      if (status != 'Selesai') continue;
      for (final item in items) {
        if (list.length >= limit) break;
        list.add(TransactionItem(
          id: tx['id'] as String,
          productName: item['name'] as String,
          dateTime: ts,
          quantityChange: -(item['quantity'] as int),
          type: 'sale',
        ));
      }
      if (list.length >= limit) break;
    }
    return list;
  }

  /// Query products matching search keywords and category (corresponds to SQLite:
  /// SELECT * FROM products WHERE name LIKE %query% AND category = selectedCategory ORDER BY name ASC/DESC)
  Future<List<Product>> getProducts({
    String? search,
    String? category,
    bool sortAscending = true,
  }) async {
    // Simulating database query delay
    await Future.delayed(const Duration(milliseconds: 200));

    Iterable<Product> filtered = _mockDatabase;

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.supplier.toLowerCase().contains(query));
    }

    if (category != null && category != 'Semua') {
      filtered = filtered.where((p) => p.category == category);
    }

    final sortedList = filtered.toList();
    if (sortAscending) {
      sortedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      sortedList.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    return sortedList;
  }

  /// SQLite CRUD Create Operation Simulation
  Future<void> insertProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockDatabase.add(product);
  }

  /// SQLite CRUD Update Operation Simulation
  Future<void> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _mockDatabase.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _mockDatabase[idx] = product;
    }
  }

  /// SQLite Master-Detail Relational Write Transaction and Stock Reduction Simulation
  Future<void> processTransaction({
    required String invoiceId,
    required double totalPay,
    required double discount,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    // Simulate database write delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Loop and apply stock reduction query: UPDATE products SET stock = stock - qty WHERE id = product_id
    for (final item in cartItems) {
      final productId = item['product_id']?.toString();
      final qty = item['quantity'] as int;

      final idx = _mockDatabase.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        final currentProduct = _mockDatabase[idx];
        final newStock = (currentProduct.stock - qty).clamp(0, currentProduct.stock);

        _mockDatabase[idx] = Product(
          id: currentProduct.id,
          name: currentProduct.name,
          category: currentProduct.category,
          stock: newStock,
          price: currentProduct.price,
          supplier: currentProduct.supplier,
          imageUrl: currentProduct.imageUrl,
          sku: currentProduct.sku,
          satuan: currentProduct.satuan,
          hargaBeli: currentProduct.hargaBeli,
          minStockAlert: currentProduct.minStockAlert,
          lokasiRak: currentProduct.lokasiRak,
          description: currentProduct.description,
        );
      }
    }

    // Save master-detail records dynamically to transaction history
    _mockTransactions.insert(0, {
      'id': invoiceId,
      'total_pay': totalPay,
      'discount': discount,
      'status': 'Selesai',
      'timestamp': DateTime.now(),
      'items': cartItems.map((item) => {
        'name': item['name'] as String,
        'quantity': item['quantity'] as int,
        'price': item['price'] as double,
      }).toList(),
    });
  }

  /// SQLite Aggregated Reporting for Horizontal Cards: Hari Ini, Minggu Ini, Bulan Ini
  Future<Map<String, double>> getTransactionSummaryReporting() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final now = DateTime.now();

    double todaySum = 0.0;
    double weekSum = 0.0;
    double monthSum = 0.0;

    // Start of today (midnight)
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Start of week (Monday first)
    final daysToSubtract = now.weekday - 1;
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));

    // Start of month
    final startOfMonth = DateTime(now.year, now.month, 1);

    for (final tx in _mockTransactions) {
      if (tx['status'] == 'Selesai') {
        final DateTime ts = tx['timestamp'] as DateTime;
        final double amt = tx['total_pay'] as double;

        if (ts.isAfter(startOfToday) || ts.isAtSameMomentAs(startOfToday)) {
          todaySum += amt;
        }
        if (ts.isAfter(startOfWeek) || ts.isAtSameMomentAs(startOfWeek)) {
          weekSum += amt;
        }
        if (ts.isAfter(startOfMonth) || ts.isAtSameMomentAs(startOfMonth)) {
          monthSum += amt;
        }
      }
    }

    return {
      'hari_ini': todaySum,
      'minggu_ini': weekSum,
      'bulan_ini': monthSum,
    };
  }

  /// SQLite Transaction List Query Supporting Search & Date Filters
  Future<List<Map<String, dynamic>>> getTransactions({
    String? search,
    String? dateFilter, // 'Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Custom'
    DateTimeRange? customDateRange,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    Iterable<Map<String, dynamic>> filtered = _mockTransactions;

    // Search query: filters records matching the invoice ID or item names
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((tx) {
        final idMatch = (tx['id'] as String).toLowerCase().contains(query);
        final items = tx['items'] as List;
        final itemMatch = items.any((item) =>
            (item['name'] as String).toLowerCase().contains(query));
        return idMatch || itemMatch;
      });
    }

    // Date filter
    if (dateFilter != null && dateFilter != 'Semua') {
      final now = DateTime.now();
      if (dateFilter == 'Hari Ini') {
        final startOfToday = DateTime(now.year, now.month, now.day);
        filtered = filtered.where((tx) {
          final ts = tx['timestamp'] as DateTime;
          return ts.isAfter(startOfToday) || ts.isAtSameMomentAs(startOfToday);
        });
      } else if (dateFilter == 'Minggu Ini') {
        final daysToSubtract = now.weekday - 1;
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
        filtered = filtered.where((tx) {
          final ts = tx['timestamp'] as DateTime;
          return ts.isAfter(startOfWeek) || ts.isAtSameMomentAs(startOfWeek);
        });
      } else if (dateFilter == 'Bulan Ini') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        filtered = filtered.where((tx) {
          final ts = tx['timestamp'] as DateTime;
          return ts.isAfter(startOfMonth) || ts.isAtSameMomentAs(startOfMonth);
        });
      } else if (dateFilter == 'Custom' && customDateRange != null) {
        final start = DateTime(customDateRange.start.year, customDateRange.start.month, customDateRange.start.day);
        final end = DateTime(customDateRange.end.year, customDateRange.end.month, customDateRange.end.day, 23, 59, 59, 999);
        filtered = filtered.where((tx) {
          final ts = tx['timestamp'] as DateTime;
          return (ts.isAfter(start) || ts.isAtSameMomentAs(start)) &&
                 (ts.isBefore(end) || ts.isAtSameMomentAs(end));
        });
      }
    }

    // Return sorted chronologically (newest first)
    final list = filtered.toList();
    list.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return list;
  }

  // --- Category CRUD and Aggregations ---

  /// Fetch total category count (Mock SQLite aggregation query)
  Future<int> getCategoryCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockCategories.length;
  }

  /// Fetch total products count summed across categories (Mock SQLite aggregation query)
  Future<int> getTotalProductCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockDatabase.length;
  }

  /// Gets product count for a specific category
  int getProductCount(String categoryName) {
    return _mockDatabase.where((p) => p.category == categoryName).length;
  }

  /// Fetch categories with search keywords (Mock SQLite query)
  Future<List<CategoryModel>> getCategories({String? search}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (search == null || search.trim().isEmpty) {
      return _mockCategories;
    }
    final query = search.trim().toLowerCase();
    return _mockCategories.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  /// Insert category row (Mock SQLite write query)
  Future<void> insertCategory(String name) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final emoji = _getEmojiForCategory(name);
    _mockCategories.add(CategoryModel(
      id: id,
      name: name,
      emoji: emoji,
      modifiedAt: DateTime.now(),
    ));
  }

  /// Update category row (Mock SQLite write query)
  Future<void> updateCategory(String id, String newName) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _mockCategories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _mockCategories[idx] = CategoryModel(
        id: id,
        name: newName,
        emoji: _getEmojiForCategory(newName),
        modifiedAt: DateTime.now(),
      );
    }
  }

  /// Delete category row (Mock SQLite delete query)
  Future<void> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _mockCategories.removeWhere((c) => c.id == id);
  }

  /// Dynamic emoji selection mapping
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
