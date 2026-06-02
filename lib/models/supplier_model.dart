class Supplier {
  final String id;
  final String name;
  final String type; // e.g. 'Distributor', 'Grosir', 'Agen', 'Lainnya'
  final String phone;
  final String location;
  final bool isActive;
  final int productCount;

  const Supplier({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.location,
    required this.isActive,
    required this.productCount,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? type,
    String? phone,
    String? location,
    bool? isActive,
    int? productCount,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
    );
  }
}
