import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../data/database_helper.dart';
import '../data/supplier_database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String _selectedSupplier = 'Lainnya';

  // Counter States
  int _stockCount = 0;
  int _minStockAlert = 5;

  String? _imagePath;
  bool _isSubmitting = false;
  bool _isLoadingDropdowns = true;

  List<String> _categories = ['Minuman'];
  final List<String> _units = ['pcs', 'box', 'pack', 'kg', 'liter'];
  List<String> _suppliers = ['Lainnya'];

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
      _selectedCategory = p.category;
      _selectedUnit = _units.contains(p.satuan) ? p.satuan : 'pcs';
      _selectedSupplier = p.supplier;
      _stockCount = p.stock;
      _minStockAlert = p.minStockAlert;
      _imagePath = p.imageUrl;
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
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final categories = await DatabaseHelper.instance.getCategories();
    final suppliers = await SupplierDatabaseHelper.instance.getSuppliers();

    final categoryNames = categories.map((c) => c.name).toList();
    final supplierNames = suppliers.map((s) => s.name).toList();
    if (!supplierNames.contains('Lainnya')) supplierNames.add('Lainnya');

    setState(() {
      _categories = categoryNames.isNotEmpty ? categoryNames : ['Lainnya'];
      _suppliers = supplierNames.isNotEmpty ? supplierNames : ['Lainnya'];
      _isLoadingDropdowns = false;

      // Fix selected values if not in loaded list
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first;
      }
      if (!_suppliers.contains(_selectedSupplier)) {
        _selectedSupplier = _suppliers.last; // 'Lainnya'
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
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

  // Removed _simulateImageUpload method

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
        imageUrl: _imagePath,
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

  /// Triggers dialog confirmation to delete the current product
  Future<void> _deleteProduct() async {
    if (widget.product == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.product!.name}"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        await DatabaseHelper.instance.deleteProduct(widget.product!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product!.name} berhasil dihapus'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context, true); // Pop with true to notify list refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus produk: $e'),
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
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _isSubmitting ? null : _deleteProduct,
            ),
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

  /// Builds image upload container using image_picker
  Widget _buildImagePicker(Color secondaryColor) {
    final hasImage = _imagePath != null;

    return Center(
      child: GestureDetector(
        onTap: hasImage ? null : _pickImage,
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
                      Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: _removeImage,
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
                      _isLoadingDropdowns
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
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
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
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
                        initialValue: _selectedUnit,
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
                StockCounterWidget(
                  value: _stockCount,
                  buttonColor: secondaryColor,
                  onMinus: () { if (_stockCount > 0) setState(() => _stockCount--); },
                  onPlus: () { setState(() => _stockCount++); },
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
                StockCounterWidget(
                  value: _minStockAlert,
                  buttonColor: warningColor,
                  onMinus: () { if (_minStockAlert > 0) setState(() => _minStockAlert--); },
                  onPlus: () { setState(() => _minStockAlert++); },
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
            _isLoadingDropdowns
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedSupplier,
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

/// Custom Widget: StockCounterWidget
/// A reusable counter widget with gesture support and animated press feedback
class StockCounterWidget extends StatefulWidget {
  final int value;
  final Color buttonColor;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const StockCounterWidget({
    super.key,
    required this.value,
    required this.buttonColor,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  State<StockCounterWidget> createState() => _StockCounterWidgetState();
}

class _StockCounterWidgetState extends State<StockCounterWidget> {
  bool _minusPressed = false;
  bool _plusPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button with press animation
          GestureDetector(
            onTapDown: (_) => setState(() => _minusPressed = true),
            onTapUp: (_) {
              setState(() => _minusPressed = false);
              widget.onMinus();
            },
            onTapCancel: () => setState(() => _minusPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _minusPressed
                    ? widget.buttonColor.withOpacity(0.2)
                    : widget.buttonColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Icon(Icons.remove, size: 18, color: widget.buttonColor),
            ),
          ),
          // Value display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${widget.value}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1B21),
              ),
            ),
          ),
          // Plus Button with press animation
          GestureDetector(
            onTapDown: (_) => setState(() => _plusPressed = true),
            onTapUp: (_) {
              setState(() => _plusPressed = false);
              widget.onPlus();
            },
            onTapCancel: () => setState(() => _plusPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _plusPressed
                    ? widget.buttonColor.withOpacity(0.2)
                    : widget.buttonColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Icon(Icons.add, size: 18, color: widget.buttonColor),
            ),
          ),
        ],
      ),
    );
  }
}
