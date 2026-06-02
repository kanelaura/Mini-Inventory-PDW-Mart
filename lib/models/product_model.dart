class Product {
  final String id;
  final String name;
  final String category;
  final int stock;
  final double price;
  final String supplier;
  final String? imageUrl;
  final String sku;
  final String satuan;
  final double hargaBeli;
  final int minStockAlert;
  final String lokasiRak;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.supplier,
    this.imageUrl,
    required this.sku,
    required this.satuan,
    required this.hargaBeli,
    required this.minStockAlert,
    required this.lokasiRak,
    required this.description,
  });

  /// Factory constructor to convert database maps to Product object
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      stock: map['stock'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      supplier: map['supplier'] ?? '',
      imageUrl: map['image_url'],
      sku: map['sku'] ?? '',
      satuan: map['satuan'] ?? 'pcs',
      hargaBeli: (map['harga_beli'] as num?)?.toDouble() ?? 0.0,
      minStockAlert: map['min_stock_alert'] ?? 5,
      lokasiRak: map['lokasi_rak'] ?? '',
      description: map['description'] ?? '',
    );
  }

  /// Convert Product object to database map for inserts/updates
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'stock': stock,
      'price': price,
      'supplier': supplier,
      'image_url': imageUrl,
      'sku': sku,
      'satuan': satuan,
      'harga_beli': hargaBeli,
      'min_stock_alert': minStockAlert,
      'lokasi_rak': lokasiRak,
      'description': description,
    };
  }
}
