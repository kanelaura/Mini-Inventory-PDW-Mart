class TransactionItem {
  final String id;
  final String productName;
  final DateTime dateTime;
  final int quantityChange;
  final String type; // 'sale' (negative) or 'restock' (positive)

  const TransactionItem({
    required this.id,
    required this.productName,
    required this.dateTime,
    required this.quantityChange,
    required this.type,
  });
}
