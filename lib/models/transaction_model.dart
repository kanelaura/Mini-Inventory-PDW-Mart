class TransactionItem {
  final String id;           // transaction_id reference
  final String productName;
  final DateTime dateTime;
  final int quantityChange;  // negative = sale, positive = restock
  final String type;         // 'sale' or 'restock'
  final double price;        // price per unit
  final int quantity;        // actual quantity sold

  // Constructor (non-const because of DateTime)
  TransactionItem({
    required this.id,
    required this.productName,
    required this.dateTime,
    required this.quantityChange,
    required this.type,
    this.price = 0.0,
    this.quantity = 0,
  });

  // toMap() for SQLite transaction_items table:
  Map<String, dynamic> toMap() {
    return {
      'transaction_id': id,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
    };
  }

  // fromMap() from SQLite row:
  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['transaction_id']?.toString() ?? '',
      productName: map['product_name'] as String? ?? '',
      dateTime: DateTime.parse(map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      quantityChange: -(map['quantity'] as int? ?? 0),
      type: 'sale',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 0,
    );
  }

  // copyWith()
  TransactionItem copyWith({
    String? id,
    String? productName,
    DateTime? dateTime,
    int? quantityChange,
    String? type,
    double? price,
    int? quantity,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      dateTime: dateTime ?? this.dateTime,
      quantityChange: quantityChange ?? this.quantityChange,
      type: type ?? this.type,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Transaction {
  final String id;
  final double totalPay;
  final double discount;
  final String status;      // 'Selesai', 'Pending', 'Dibatalkan'
  final String note;
  final DateTime timestamp;
  final List<TransactionItem> items; // joined detail rows

  // Constructor
  Transaction({
    required this.id,
    required this.totalPay,
    required this.discount,
    required this.status,
    required this.note,
    required this.timestamp,
    required this.items,
  });

  // toMap() for SQLite transactions table:
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_pay': totalPay,
      'discount': discount,
      'status': status,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // fromMap() from SQLite row:
  factory Transaction.fromMap(Map<String, dynamic> map, {List<TransactionItem>? items}) {
    return Transaction(
      id: map['id']?.toString() ?? '',
      totalPay: (map['total_pay'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'Pending',
      note: map['note'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      items: items ?? [],
    );
  }

  // copyWith()
  Transaction copyWith({
    String? id,
    double? totalPay,
    double? discount,
    String? status,
    String? note,
    DateTime? timestamp,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      totalPay: totalPay ?? this.totalPay,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
    );
  }
}
