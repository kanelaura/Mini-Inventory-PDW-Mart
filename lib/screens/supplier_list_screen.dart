import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_list_screen.dart';
import 'transaction_screen.dart';
import '../models/supplier_model.dart';
import '../data/supplier_database_helper.dart';
import 'settings_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Aktif', 'Tidak Aktif'
  bool _isLoading = true;

  // Summaries metric state
  int _totalSuppliers = 0;
  int _activeSuppliers = 0;
  int _cumulativeProducts = 0;

  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Refreshes statistical sums and vendor list from the DB mock helper
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final total = await SupplierDatabaseHelper.instance
          .getTotalSupplierCount();
      final active = await SupplierDatabaseHelper.instance
          .getActiveSupplierCount();
      final cumulative = await SupplierDatabaseHelper.instance
          .getCumulativeProductsSupplied();
      final list = await SupplierDatabaseHelper.instance.getSuppliers(
        search: _searchQuery,
        filter: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _totalSuppliers = total;
          _activeSuppliers = active;
          _cumulativeProducts = cumulative;
          _suppliers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan memuat data: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  /// Business acronym generator (e.g. PT, CV, UD) next to name stack
  String _getAcronymInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.startsWith(RegExp(r'(PT|CV|UD)\b', caseSensitive: false))) {
      final parts = cleanName.split(' ');
      if (parts.isNotEmpty) return parts[0].toUpperCase();
    }
    final words = cleanName.split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'SP';
  }

  /// Show Modal Bottom Sheet for Form Inputs (Add/Edit Mode)
  void _showFormSheet({Supplier? supplier}) {
    final isEdit = supplier != null;
    final nameController = TextEditingController(
      text: isEdit ? supplier.name : '',
    );
    final phoneController = TextEditingController(
      text: isEdit ? supplier.phone : '',
    );
    final locationController = TextEditingController(
      text: isEdit ? supplier.location : '',
    );
    String selectedType = isEdit ? supplier.type : 'Distributor';
    bool isActive = isEdit ? supplier.isActive : true;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20.0,
                24.0,
                20.0,
                MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Ubah Supplier' : 'Tambah Supplier Baru',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00236F),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: nameController,
                        style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nama Supplier',
                          labelStyle: GoogleFonts.hankenGrotesk(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: 'Masukkan nama vendor...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.business,
                            color: Color(0xFF00236F),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama supplier wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Type Select dropdown (Using initialValue after Flutter v3.33 deprecations)
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tipe Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.category,
                            color: Color(0xFF00236F),
                          ),
                        ),
                        items: ['Distributor', 'Grosir', 'Agen', 'Lainnya'].map(
                          (type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          },
                        ).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Telepon',
                          hintText: '081XXXXXXXX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFF00236F),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nomor telepon wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      TextFormField(
                        controller: locationController,
                        style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Lokasi / Alamat',
                          hintText: 'Masukkan kota atau alamat...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: Color(0xFF00236F),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Alamat / Lokasi wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Active Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status Aktif',
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeThumbColor: const Color(0xFF10B981),
                            onChanged: (val) {
                              setSheetState(() {
                                isActive = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit trigger button
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            final location = locationController.text.trim();

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            if (isEdit) {
                              final updated = supplier.copyWith(
                                name: name,
                                type: selectedType,
                                phone: phone,
                                location: location,
                                isActive: isActive,
                              );
                              await SupplierDatabaseHelper.instance
                                  .updateSupplier(updated);
                            } else {
                              final newId = DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString();
                              final added = Supplier(
                                id: newId,
                                name: name,
                                type: selectedType,
                                phone: phone,
                                location: location,
                                isActive: isActive,
                                productCount:
                                    0, // Starts supplying 0 items initially
                              );
                              await SupplierDatabaseHelper.instance
                                  .insertSupplier(added);
                            }

                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Data supplier berhasil diperbarui!'
                                      : 'Supplier baru berhasil ditambahkan!',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                            _loadAllData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00236F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'Simpan Perubahan' : 'Simpan Supplier',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show Operational Options Modal Sheet (Edit, Toggle, Delete)
  void _showOptionsSheet(Supplier supplier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                supplier.name,
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: const Color(0xFF00236F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF2170E4)),
                title: Text(
                  'Edit Supplier',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showFormSheet(supplier: supplier);
                },
              ),
              ListTile(
                leading: Icon(
                  supplier.isActive ? Icons.toggle_off : Icons.toggle_on,
                  color: supplier.isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
                title: Text(
                  supplier.isActive
                      ? 'Nonaktifkan Supplier'
                      : 'Aktifkan Supplier',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  final updated = supplier.copyWith(
                    isActive: !supplier.isActive,
                  );
                  await SupplierDatabaseHelper.instance.updateSupplier(updated);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${supplier.name} sekarang ${updated.isActive ? "Aktif" : "Tidak Aktif"}',
                      ),
                      backgroundColor: updated.isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  );
                  _loadAllData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: Text(
                  'Hapus Supplier',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(supplier);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirm Delete Modal Dialog
  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus Supplier',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus ${supplier.name}? Data yang terhapus tidak dapat dikembalikan.',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.hankenGrotesk(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await SupplierDatabaseHelper.instance.deleteSupplier(
                  supplier.id,
                );
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Supplier berhasil dihapus'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
                _loadAllData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Styling palette definitions
    const Color primaryTheme = Color(0xFF00236F);
    const Color containerSlate = Color(0xFF2170E4);
    const Color accentSuccess = Color(0xFF10B981);
    const Color alertRed = Color(0xFFEF4444);
    const Color layerCanvas = Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor: layerCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flat App Bar Flat Canvas (Primary Theme color)
          _buildAppBarFlat(primaryTheme),

          // Scrollable list content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: primaryTheme,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search bar search selection
                    _buildSearchBar(primaryTheme),

                    const SizedBox(height: 18),

                    // Horizontal statistics metrics row
                    _buildStatsRow(accentSuccess, primaryTheme, containerSlate),

                    const SizedBox(height: 18),

                    // Segmented Filter Controls Row
                    _buildFilterChips(primaryTheme),

                    const SizedBox(height: 16),

                    // Supplier listings stack
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: CircularProgressIndicator(
                                color: primaryTheme,
                              ),
                            ),
                          )
                        : _suppliers.isEmpty
                        ? _buildEmptyState()
                        : _buildSuppliersList(
                            primaryTheme,
                            containerSlate,
                            accentSuccess,
                            alertRed,
                          ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed bottom system navigation bar
          _buildSystemNavigationBar(primaryTheme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormSheet(),
        backgroundColor: primaryTheme,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Builds Flat App Bar flat canvas
  Widget _buildAppBarFlat(Color primaryTheme) {
    return Container(
      color: primaryTheme,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              Text(
                'Supplier',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              // Right-aligned mini circular badge enclosing Icons.add symbol
              GestureDetector(
                onTap: () => _showFormSheet(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search Bar with magnifying and filtering icons
  Widget _buildSearchBar(Color primaryTheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          Icon(Icons.search, color: primaryTheme, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.hankenGrotesk(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _loadAllData();
              },
              decoration: InputDecoration(
                hintText: 'Cari nama supplier...',
                hintStyle: GoogleFonts.hankenGrotesk(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Icon(Icons.filter_list, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }

  /// 3-item wide horizontal metric row (stats banner)
  Widget _buildStatsRow(
    Color accentSuccess,
    Color primaryTheme,
    Color containerSlate,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Supplier',
            value: '$_totalSuppliers',
            icon: Icons.local_shipping,
            iconColor: containerSlate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Aktif',
            value: '$_activeSuppliers',
            icon: Icons.check_circle,
            iconColor: accentSuccess,
            valueColor: accentSuccess,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Produk Dipasok',
            value: '$_cumulativeProducts',
            icon: Icons.inventory_2,
            iconColor: primaryTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 9,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented Filter Controls chips selection row
  Widget _buildFilterChips(Color primaryTheme) {
    final options = ['Semua', 'Aktif', 'Tidak Aktif'];

    return Row(
      children: options.map((option) {
        final isActive = _selectedFilter == option;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              selected: isActive,
              showCheckmark: false,
              label: Text(
                option,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: primaryTheme,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isActive ? primaryTheme : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = option;
                  });
                  _loadAllData();
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Empty state widget if list is empty
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data supplier',
              style: GoogleFonts.hankenGrotesk(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gunakan filter di atas atau cari dengan kata kunci lain',
              style: GoogleFonts.hankenGrotesk(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Renders vendor listings
  Widget _buildSuppliersList(
    Color primaryTheme,
    Color containerSlate,
    Color accentSuccess,
    Color alertRed,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suppliers.length + 1, // Add 1 for the dashed button at bottom
      itemBuilder: (context, index) {
        if (index == _suppliers.length) {
          return _buildDashedAddButton(primaryTheme);
        }

        final s = _suppliers[index];
        final initials = _getAcronymInitials(s.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row (Initial avatar, Name stack, Status Badge)
              Row(
                children: [
                  // round gradient circle enclosing acronym initials
                  SupplierAvatarWidget(
                    initials: initials,
                    isActive: s.isActive,
                    onLongPress: () => _showOptionsSheet(s),
                  ),
                  const SizedBox(width: 12),

                  // Name and Category Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Type capsule label pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.type,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Active / Inactive Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: s.isActive
                          ? accentSuccess.withOpacity(0.1)
                          : alertRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.isActive ? 'Aktif' : 'Tidak Aktif',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: s.isActive ? accentSuccess : alertRed,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Middle Grid Row (neat 2-column detail layout: Phone vs Location)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.phone,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.location,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Footer Row (Distribution stats & Operational launcher)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.productCount} produk dipasok',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: containerSlate,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showOptionsSheet(s),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dashed Add Button at the base of listings
  Widget _buildDashedAddButton(Color primaryTheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      height: 52,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: primaryTheme.withOpacity(0.4),
          borderRadius: 12.0,
          gap: 6.0,
          dashLength: 8.0,
        ),
        child: InkWell(
          onTap: () => _showFormSheet(),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tambah Supplier Baru',
                style: GoogleFonts.hankenGrotesk(
                  color: primaryTheme,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_outline, color: primaryTheme, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Sticky Bottom System Navigation Bar
  Widget _buildSystemNavigationBar(Color primaryTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', false, () {
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }),
              _buildNavItem(Icons.inventory_2_outlined, 'Produk', false, () {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(),
                    ),
                  );
                }
              }),
              _buildNavItem(Icons.receipt_long_rounded, 'Transaksi', false, () {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionScreen(),
                    ),
                  );
                }
              }),
              _buildNavItem(
                Icons.local_shipping_outlined,
                'Supplier',
                true,
                () {
                  // Tapping active: stays
                },
              ),
              _buildNavItem(Icons.settings_outlined, 'Settings', false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    final Color primaryTheme = const Color(0xFF00236F);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryTheme.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? primaryTheme : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? primaryTheme : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

}

/// Custom Widget: SupplierAvatarWidget
/// Displays supplier initials avatar with long-press gesture
/// that shows a ripple animation and triggers options sheet
class SupplierAvatarWidget extends StatefulWidget {
  final String initials;
  final bool isActive;
  final VoidCallback onLongPress;

  const SupplierAvatarWidget({
    super.key,
    required this.initials,
    required this.isActive,
    required this.onLongPress,
  });

  @override
  State<SupplierAvatarWidget> createState() => _SupplierAvatarWidgetState();
}

class _SupplierAvatarWidgetState extends State<SupplierAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onLongPress();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryTheme = const Color(0xFF00236F);
    final Color containerSlate = const Color(0xFF2170E4);
    final Color accentSuccess = const Color(0xFF10B981);
    final Color alertRed = const Color(0xFFEF4444);

    return GestureDetector(
      onLongPress: _handleLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple circle behind avatar
              Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value * 0.3,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive ? accentSuccess : alertRed,
                    ),
                  ),
                ),
              ),
              // Main avatar
              Transform.scale(
                scale: _scaleAnim.value * 0.9 + 0.1,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryTheme,
                        containerSlate.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isActive
                          ? accentSuccess.withOpacity(0.5)
                          : alertRed.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.initials,
                      style: GoogleFonts.hankenGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom dashed border painter drawing dotted rounded boxes for button footer
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(
            distance,
            (distance + dashLength).clamp(0.0, metric.length),
          ),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.borderRadius != borderRadius;
}
