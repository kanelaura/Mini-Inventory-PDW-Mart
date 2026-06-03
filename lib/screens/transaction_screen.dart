import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../data/database_helper.dart';
import 'transaction_history_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _noteController = TextEditingController();

  // Cart state: List of Maps tracking selected products
  // E.g., {'product_id': '1', 'name': '...', 'price': 38000.0, 'quantity': 1, 'available_stock': 2, 'satuan': 'pcs'}
  final List<Map<String, dynamic>> _cartItems = [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Product> _suggestedProducts = [];
  bool _showSuggestions = false;

  late String _invoiceId;
  double _discount = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _invoiceId = _generateInvoiceId();
    _loadInitialProducts(); // Load initial products to search/add
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Automatically generates Invoice IDs in TRX-YYYYMMDD-XXX format
  String _generateInvoiceId() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final randomSuffix = (now.millisecond % 900 + 100)
        .toString(); // Generate unique 3-digit suffix
    return 'TRX-$year$month$day-$randomSuffix';
  }

  /// Format date for display
  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  /// Pre-fetch product lists for local search suggestions
  Future<void> _loadInitialProducts() async {
    final products = await DatabaseHelper.instance.getProducts();
    if (mounted) {
      setState(() {
        _suggestedProducts = products;
      });
    }
  }

  /// Perform type-ahead search filter
  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _showSuggestions = query.isNotEmpty;
    });

    final products = await DatabaseHelper.instance.getProducts(search: query);
    if (mounted) {
      setState(() {
        _suggestedProducts = products;
      });
    }
  }

  /// Adds selected product into the cart list state
  void _addProductToCart(Product product) {
    if (product.stock <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk ini sedang kehabisan stok!'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final index = _cartItems.indexWhere(
      (item) => item['product_id'] == product.id,
    );

    setState(() {
      if (index != -1) {
        // Increment quantity if already exists but validate bounds
        final int currentQty = _cartItems[index]['quantity'];
        if (currentQty < product.stock) {
          _cartItems[index]['quantity'] = currentQty + 1;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stok maksimal untuk ${product.name} telah tercapai!',
                ),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      } else {
        // Add new item to cart list state
        _cartItems.add({
          'product_id': product.id,
          'name': product.name,
          'price': product.price,
          'quantity': 1,
          'available_stock': product.stock,
          'satuan': product.satuan,
        });
      }
      _searchController.clear();
      _showSuggestions = false;
      _searchFocusNode.unfocus();
    });
  }

  /// Increments cart item count validating available stock limits
  void _incrementQty(int index) {
    final int currentQty = _cartItems[index]['quantity'];
    final int maxStock = _cartItems[index]['available_stock'];

    if (currentQty < maxStock) {
      setState(() {
        _cartItems[index]['quantity'] = currentQty + 1;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Batas stok maksimal untuk ${_cartItems[index]['name']} tercapai!',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  /// Decrements cart item count down to 1
  void _decrementQty(int index) {
    final int currentQty = _cartItems[index]['quantity'];
    if (currentQty > 1) {
      setState(() {
        _cartItems[index]['quantity'] = currentQty - 1;
      });
    }
  }

  /// Removes product completely from cart state
  void _removeCartItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  /// Dialog modal to enter dynamic discount
  void _showDiscountDialog() {
    final TextEditingController discountController = TextEditingController(
      text: _discount.round().toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Diskon',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: discountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Masukkan jumlah diskon (Rp)',
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final double disc =
                    double.tryParse(discountController.text.trim()) ?? 0.0;
                setState(() {
                  _discount = disc;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Terapkan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Formatting price helper
  String _formatPrice(double value) {
    final cleanValue = value.round();
    final buffer = StringBuffer();
    final valueString = cleanValue.toString();

    int count = 0;
    for (int i = valueString.length - 1; i >= 0; i--) {
      buffer.write(valueString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  /// Calculates aggregate totals
  double _calculateSubtotal() {
    double sub = 0.0;
    for (final item in _cartItems) {
      sub += (item['price'] as double) * (item['quantity'] as int);
    }
    return sub;
  }

  int _calculateTotalQty() {
    int qty = 0;
    for (final item in _cartItems) {
      qty += item['quantity'] as int;
    }
    return qty;
  }

  /// Processes transaction write pipeline
  Future<void> _processCheckout() async {
    if (_cartItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keranjang belanja Anda masih kosong!'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isProcessing = true;
    });

    final subtotal = _calculateSubtotal();
    final totalPay = (subtotal - _discount).clamp(0.0, double.infinity);

    try {
      // Execute SQLite Relational checkout transaction in DatabaseHelper
      await DatabaseHelper.instance.processTransaction(
        invoiceId: _invoiceId,
        totalPay: totalPay,
        discount: _discount,
        note: _noteController.text.trim(),
        cartItems: _cartItems,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Transaksi $_invoiceId Berhasil Diproses!'),
          backgroundColor: const Color(0xFF10B981), // Success color
        ),
      );
      // Pop with true to refresh lists
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal memproses transaksi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Palette Specification Alignments
    const Color primaryColor = Color(0xFF1E3A8A);
    const Color secondaryColor = Color(0xFF3B82F6);
    const Color successColor = Color(0xFF10B981);
    const Color alertColor = Color(0xFFEF4444);
    const Color backgroundColor = Color(0xFFF8FAFC);

    final subtotal = _calculateSubtotal();
    final totalPay = (subtotal - _discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOP APP BAR CANVAS (slate blue rounded corners banner)
                _buildHeaderBanner(primaryColor),

                Expanded(
                  child: Stack(
                    children: [
                      // Scrollable content body
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          16.0,
                          20.0,
                          100.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // SEARCH & ADD MODULE
                            _buildSearchAddModule(primaryColor, secondaryColor),

                            const SizedBox(height: 20),

                            // Cart Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daftar Belanja',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1B21),
                                  ),
                                ),
                                Text(
                                  '${_cartItems.length} Item',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // SELECTED PRODUCTS CART LIST
                            if (_cartItems.isEmpty)
                              _buildEmptyCartCard()
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  return _buildCartItemCard(
                                    index,
                                    alertColor: alertColor,
                                    successColor: successColor,
                                    secondaryColor: secondaryColor,
                                  );
                                },
                              ),

                            const SizedBox(height: 24),

                            // ORDER SUMMARY BLOCK
                            _buildOrderSummaryBlock(
                              subtotal,
                              totalPay,
                              primaryColor,
                            ),
                          ],
                        ),
                      ),

                      // Floating suggestions overlay during search type-ahead
                      if (_showSuggestions && _suggestedProducts.isNotEmpty)
                        Positioned(
                          top: 86,
                          left: 20,
                          right: 20,
                          child: Card(
                            elevation: 8,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: _suggestedProducts.length,
                                itemBuilder: (context, index) {
                                  final p = _suggestedProducts[index];
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                    ),
                                    title: Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Stok: ${p.stock} ${p.satuan} • ${_formatPrice(p.price)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => _addProductToCart(p),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // STICKY FOOTER ACTIONS BAR
                _buildStickyFooter(primaryColor),
              ],
            ),
    );
  }

  /// Builds App Bar Canvas header
  Widget _buildHeaderBanner(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Nav Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Transaksi Jual',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TransactionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Subtitles displaying date and invoice id
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getFormattedDate(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF93C5FD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _invoiceId,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds input card containing product searches and barcode triggers
  Widget _buildSearchAddModule(Color primaryColor, Color secondaryColor) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TAMBAH PRODUK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            // Search Input Row
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(
                        color: Color(0xFF1A1B21),
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari produk berdasarkan nama...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: primaryColor,
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // Trailing barcode reader icon
                  IconButton(
                    icon: Icon(
                      Icons.barcode_reader,
                      color: secondaryColor,
                      size: 22,
                    ),
                    onPressed: () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pemindai barcode kamera (Simulasi)'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual cart cards inside scroll list state
  Widget _buildCartItemCard(
    int index, {
    required Color alertColor,
    required Color successColor,
    required Color secondaryColor,
  }) {
    final item = _cartItems[index];
    final double price = item['price'];
    final int qty = item['quantity'];
    final int maxStock = item['available_stock'];
    final double subtotal = price * qty;

    const Color primaryColor = Color(0xFF1E3A8A);
    const Color warningColor = Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12.0),
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
          // Close button and name details row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF1A1B21),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(price)} / ${item['satuan']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subtotal & Quantity counter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Max baseline stock indicators
              Text(
                'Stok: $maxStock ${item['satuan']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: maxStock <= 5 ? warningColor : const Color(0xFF94A3B8),
                ),
              ),
              // Oval quantity counter layout
              Row(
                children: [
                  // Subtotal price label
                  Text(
                    _formatPrice(subtotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CartItemCounter(
                    quantity: qty,
                    maxStock: maxStock,
                    onIncrement: () => _incrementQty(index),
                    onDecrement: () => _decrementQty(index),
                    onRemove: () => _removeCartItem(index),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculates calculations parameters and prints block
  Widget _buildOrderSummaryBlock(
    double subtotal,
    double totalPay,
    Color primaryColor,
  ) {
    final totalItems = _cartItems.length;
    final totalQty = _calculateTotalQty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CATATAN TRANSAKSI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1B21),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan (opsional)...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF1E3A8A),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
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
                const Text(
                  'RINGKASAN PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Total Item Row
                _buildSummaryRow('Total Item', '$totalItems'),
                const SizedBox(height: 8),
                // Total Qty Row
                _buildSummaryRow('Total Kuantitas', '$totalQty pcs'),
                const SizedBox(height: 8),
                // Subtotal Row
                _buildSummaryRow('Subtotal', _formatPrice(subtotal)),
                const SizedBox(height: 8),
                // Discount Row containing edit note hook
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Diskon',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _showDiscountDialog,
                          child: const Icon(
                            Icons.edit_note,
                            size: 20,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '- ${_formatPrice(_discount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: Color(0xFFE2E8F0)),
                // Bold dominant total bayar calculation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Bayar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1B21),
                      ),
                    ),
                    Text(
                      _formatPrice(totalPay),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1B21),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  /// Sticky bottom horiz actions row
  Widget _buildStickyFooter(Color primaryColor) {
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
            // cancel pop button
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
            // solid primary transactional checkout button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processCheckout,
                  icon: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Proses Transaksi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: primaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: const [
            Icon(
              Icons.shopping_basket_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Text(
              'Keranjang belanja kosong',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Cari produk di atas untuk mulai menambahkan barang',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Widget: CartItemCounter
/// A quantity counter with swipe-left gesture to remove item from cart
class CartItemCounter extends StatefulWidget {
  final int quantity;
  final int maxStock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCounter({
    super.key,
    required this.quantity,
    required this.maxStock,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<CartItemCounter> createState() => _CartItemCounterState();
}

class _CartItemCounterState extends State<CartItemCounter> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Custom gesture: horizontal drag to reveal delete
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          _dragOffset = _dragOffset.clamp(-80.0, 0.0);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_dragOffset < -40) {
          widget.onRemove();
        }
        setState(() {
          _dragOffset = 0.0;
        });
      },
      child: Stack(
        children: [
          // Background delete indicator
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _dragOffset < -20 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Sliding counter widget
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.onDecrement,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${widget.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF1A1B21),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onIncrement,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
