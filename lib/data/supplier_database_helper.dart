import '../models/supplier_model.dart';

class SupplierDatabaseHelper {
  SupplierDatabaseHelper._privateConstructor();
  static final SupplierDatabaseHelper instance = SupplierDatabaseHelper._privateConstructor();

  final List<Supplier> _mockSuppliers = [
    const Supplier(
      id: '1',
      name: 'PT Unilever Indonesia',
      type: 'Distributor',
      phone: '08112345678',
      location: 'Jakarta Selatan',
      isActive: true,
      productCount: 15,
    ),
    const Supplier(
      id: '2',
      name: 'CV Maju Jaya Makmur',
      type: 'Grosir',
      phone: '08129876543',
      location: 'Surabaya',
      isActive: true,
      productCount: 8,
    ),
    const Supplier(
      id: '3',
      name: 'UD Sumber Sandang',
      type: 'Grosir',
      phone: '08571122334',
      location: 'Bandung',
      isActive: false,
      productCount: 4,
    ),
    const Supplier(
      id: '4',
      name: 'PT Indofood CBP',
      type: 'Distributor',
      phone: '0811888999',
      location: 'Semarang',
      isActive: true,
      productCount: 22,
    ),
  ];

  /// Query suppliers matching search keywords and segmented filter status
  Future<List<Supplier>> getSuppliers({String? search, String? filter}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    Iterable<Supplier> filtered = _mockSuppliers;

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      filtered = filtered.where((s) => s.name.toLowerCase().contains(query));
    }

    if (filter != null && filter != 'Semua') {
      final active = filter == 'Aktif';
      filtered = filtered.where((s) => s.isActive == active);
    }

    return filtered.toList();
  }

  Future<int> getTotalSupplierCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _mockSuppliers.length;
  }

  Future<int> getActiveSupplierCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _mockSuppliers.where((s) => s.isActive).length;
  }

  Future<int> getCumulativeProductsSupplied() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _mockSuppliers.fold<int>(0, (sum, s) => sum + s.productCount);
  }

  Future<void> insertSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _mockSuppliers.add(supplier);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _mockSuppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _mockSuppliers[idx] = supplier;
    }
  }

  Future<void> deleteSupplier(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _mockSuppliers.removeWhere((s) => s.id == id);
  }
}
