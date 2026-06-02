import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../data/database_helper.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _rackLocationController;
  late TextEditingController _descriptionController;

  // Dropdown States
  String _selectedCategory = 'Minuman';
  String _selectedUnit = 'pcs';
  String _selectedSupplier = 'Indofood';

  // Counter States
  int _stockCount = 0;
  int _minStockAlert = 5;

  // Image upload state simulation
  String? _simulatedImagePath;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Minuman',
    'Makanan',
    'Elektronik',
    'Lainnya',
  ];
  final List<String> _units = ['pcs', 'box', 'pack', 'kg', 'liter'];
  final List<String> _suppliers = [
    'Indofood',
    'Ultra Jaya',
    'Santos Jaya Abadi',
    'Baseus',
    'Broco',
    'Gulaku Corp',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    // Mode Detection: Pre-fill if editing an existing product
    if (widget.product != null) {
      final p = widget.product!;
      _nameController = TextEditingController(text: p.name);
      _skuController = TextEditingController(text: p.sku);
      _priceController = TextEditingController(
        text: p.price.round().toString(),
      );
      _purchasePriceController = TextEditingController(
        text: p.hargaBeli.round().toString(),
      );
      _rackLocationController = TextEditingController(text: p.lokasiRak);
      _descriptionController = TextEditingController(text: p.description);
      _selectedCategory = _categories.contains(p.category)
          ? p.category
          : 'Lainnya';
      _selectedUnit = _units.contains(p.satuan) ? p.satuan : 'pcs';
      _selectedSupplier = _suppliers.contains(p.supplier)
          ? p.supplier
          : 'Lainnya';
      _stockCount = p.stock;
      _minStockAlert = p.minStockAlert;
      _simulatedImagePath = p.imageUrl;
    } else {
      // Add Mode: Clean fields
      _nameController = TextEditingController();
      _skuController = TextEditingController();
      _priceController = TextEditingController();
      _purchasePriceController = TextEditingController();
      _rackLocationController = TextEditingController();
      _descriptionController = TextEditingController();
      _stockCount = 0;
      _minStockAlert = 5;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _rackLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Simulate image picker path updates
  void _simulateImageUpload() {
    setState(() {
      if (_simulatedImagePath == null) {
        _simulatedImagePath =
            'assets/images/products/prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diupload (Simulasi)')),
        );
      } else {
        _simulatedImagePath = null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto dihapus')));
      }
    });
  }

  /// Handles form submission pipeline (CREATE or UPDATE)
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Assemble Product object
      final id =
          widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final product = Product(
        id: id,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        stock: _stockCount,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        supplier: _selectedSupplier,
        imageUrl: _simulatedImagePath,
        sku: _skuController.text.trim(),
        satuan: _selectedUnit,
        hargaBeli: double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
        minStockAlert: _minStockAlert,
        lokasiRak: _rackLocationController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      try {
        if (widget.product != null) {
          // UPDATE Operation
          await DatabaseHelper.instance.updateProduct(product);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk berhasil diperbarui')),
            );
          }
        } else {
          // CREATE Operation
          await DatabaseHelper.instance.insertProduct(product);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk baru berhasil ditambahkan')),
            );
          }
        }

        if (mounted) {
          // Pop with true value to signify data refresh required
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan database: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Palette Specification Alignments
    const Color primaryColor = Color(0xFF00236F);
    const Color secondaryColor = Color(0xFF2170E4);
    const Color backgroundColor = Color(0xFFF8FAFC);
    const Color warningColor = Color(0xFFD97706);
    const Color textColor = Color(0xFF1A1B21);

    final isEditMode = widget.product != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          isEditMode ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isSubmitting ? null : _submitForm,
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // IMAGE PICKER CAPSULE
                          _buildImagePicker(secondaryColor),

                          const SizedBox(height: 24),

                          // FORM SECTION 1: Informasi Produk
                          _buildSectionHeader('Informasi Produk'),
                          _buildInformasiProdukCard(textColor, secondaryColor),

                          const SizedBox(height: 20),

                          // FORM SECTION 2: Stok & Supplier
                          _buildSectionHeader('Stok & Supplier'),
                          _buildStokSupplierCard(
                            textColor,
                            secondaryColor,
                            warningColor,
                            primaryColor,
                          ),

                          const SizedBox(height: 20),

                          // FORM SECTION 3: Deskripsi
                          _buildSectionHeader('Deskripsi Tambahan'),
                          _buildDeskripsiCard(textColor, secondaryColor),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // FIXED BOTTOM ACTIONS FOOTER
                _buildBottomActions(textColor, secondaryColor),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Builds image upload container mockup
  Widget _buildImagePicker(Color secondaryColor) {
    final hasImage = _simulatedImagePath != null;

    return Center(
      child: GestureDetector(
        onTap: _simulateImageUpload,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: secondaryColor.withOpacity(0.3),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera, size: 28, color: secondaryColor),
                    const SizedBox(height: 6),
                    Text(
                      'Upload Foto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Form Section 1: Informasi Produk
  Widget _buildInformasiProdukCard(Color textColor, Color secondaryColor) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nama Produk
            Text(
              'Nama Produk *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              decoration: _buildInputDecoration(
                'Contoh: Lampu LED 10W',
                secondaryColor,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama produk wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kode Produk / SKU
            Text(
              'Kode Produk / SKU *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _skuController,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              decoration:
                  _buildInputDecoration(
                    'Contoh: LP-LED-10W',
                    secondaryColor,
                  ).copyWith(
                    suffixIcon: Icon(
                      Icons.barcode_reader,
                      color: secondaryColor,
                      size: 22,
                    ),
                  ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kode SKU wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category & Satuan Dropdowns (2 columns)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: _buildInputDecoration('', secondaryColor),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedCategory = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satuan *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: _buildInputDecoration('', secondaryColor),
                        items: _units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Harga Jual & Harga Beli
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga Jual *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: _buildInputDecoration('0', secondaryColor)
                            .copyWith(
                              prefixText: 'Rp ',
                              prefixStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harus angka';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga Beli',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: _buildInputDecoration('0', secondaryColor)
                            .copyWith(
                              prefixText: 'Rp ',
                              prefixStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Form Section 2: Stok & Supplier
  Widget _buildStokSupplierCard(
    Color textColor,
    Color secondaryColor,
    Color warningColor,
    Color primaryColor,
  ) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stok Awal Row Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stok Awal *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Stok awal barang di toko',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                _buildCounterWidget(
                  value: _stockCount,
                  buttonColor: secondaryColor,
                  onMinus: () {
                    if (_stockCount > 0) {
                      setState(() => _stockCount--);
                    }
                  },
                  onPlus: () {
                    setState(() => _stockCount++);
                  },
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFE2E8F0)),

            // Minimum Stok Alert Row Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum Stok Alert *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Batas minimal warning stok',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                _buildCounterWidget(
                  value: _minStockAlert,
                  buttonColor: warningColor, // Amber warning color
                  onMinus: () {
                    if (_minStockAlert > 0) {
                      setState(() => _minStockAlert--);
                    }
                  },
                  onPlus: () {
                    setState(() => _minStockAlert++);
                  },
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFE2E8F0)),

            // Supplier Selection
            Text(
              'Supplier',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedSupplier,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              decoration: _buildInputDecoration(
                'Pilih Supplier',
                secondaryColor,
              ),
              items: _suppliers
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSupplier = val);
              },
            ),
            const SizedBox(height: 16),

            // Lokasi Rak
            Text(
              'Lokasi Rak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _rackLocationController,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              decoration: _buildInputDecoration(
                'Contoh: A-12-3',
                secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Form Section 3: Deskripsi
  Widget _buildDeskripsiCard(Color textColor, Color secondaryColor) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Deskripsi Detail',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 8,
              style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
              decoration: _buildInputDecoration(
                'Masukkan spesifikasi produk, catatan rak, atau detail lainnya...',
                secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Persistent bottom button actions bar
  Widget _buildBottomActions(Color textColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // "Batal" expanded clip (Flex 1)
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // "Simpan" expanded clip (Flex 2)
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: secondaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Produk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterWidget({
    required int value,
    required Color buttonColor,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button
          GestureDetector(
            onTap: onMinus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Icon(Icons.remove, size: 18, color: buttonColor),
            ),
          ),
          // Value Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1B21),
              ),
            ),
          ),
          // Plus Button
          GestureDetector(
            onTap: onPlus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Icon(Icons.add, size: 18, color: buttonColor),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, Color activeBorderColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: activeBorderColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
