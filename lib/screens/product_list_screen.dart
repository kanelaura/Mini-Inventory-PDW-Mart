import 'package:flutter/material.dart';
import 'product_form_screen.dart';
import '../models/product_model.dart';
import '../data/database_helper.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _sortAscending = true;
  int _currentNavIndex = 1; // "Produk" is active by default (Index 1)

  final List<String> _categories = [
    'Semua',
    'Minuman',
    'Makanan',
    'Elektronik',
    'Lainnya',
  ];

  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _productsFuture = DatabaseHelper.instance.getProducts(
      search: _searchQuery,
      category: _selectedCategory,
      sortAscending: _sortAscending,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Triggers update when search terms change
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _loadProducts();
    });
  }

  /// Triggers update when category changes
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _loadProducts();
    });
  }

  /// Toggles alphabetical sorting (A-Z or Z-A)
  void _toggleSort() {
    setState(() {
      _sortAscending = !_sortAscending;
      _loadProducts();
    });
  }

  /// Formatting price with thousands separator
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

  @override
  Widget build(BuildContext context) {
    // Palette Specification Alignments
    const Color primaryColor = Color(0xFF00236F);
    const Color secondaryColor = Color(0xFF2170E4);
    const Color backgroundColor = Color(0xFFF7F9FB);
    const Color successColor = Color(0xFF10B981);
    const Color warningColor = Color(0xFFF59E0B);
    const Color dangerColor = Color(0xFFEF4444);
    const Color textColor = Color(0xFF191C1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Daftar Produk',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter lanjutan akan segera hadir.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SEARCH SECTION & CANVAS EXTENSION (Blue Backdrop)
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: primaryColor,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),

          // CATEGORY CHIPS ROW (Horizontal Scrollable)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: _categories.map((category) {
                  final bool isActive = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () => _onCategorySelected(category),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? primaryColor
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // STATS BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                final int count = snapshot.data?.length ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$count Produk ditemukan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    InkWell(
                      onTap: _toggleSort,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Urutkan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.swap_vert,
                              color: secondaryColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // PRODUCT LIST VIEW
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: dangerColor),
                    ),
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba cari nama lain atau ubah filter',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 80.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(
                      product,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      textColor: textColor,
                      successColor: successColor,
                      warningColor: warningColor,
                      dangerColor: dangerColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation to AddProductScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          ).then((value) {
            if (value == true) {
              setState(() {
                _loadProducts();
              });
            }
          });
        },
        backgroundColor: secondaryColor,
        elevation: 6,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
    );
  }

  /// Builds individual product card widgets
  Widget _buildProductCard(
    Product product, {
    required Color primaryColor,
    required Color secondaryColor,
    required Color textColor,
    required Color successColor,
    required Color warningColor,
    required Color dangerColor,
  }) {
    // Condition Stock status badging
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;

    if (product.stock > 10) {
      badgeBgColor = successColor.withOpacity(0.1);
      badgeTextColor = successColor;
      badgeText = 'Stock: ${product.stock}';
    } else if (product.stock > 0) {
      badgeBgColor = warningColor.withOpacity(0.1);
      badgeTextColor = warningColor;
      badgeText = 'Stock: ${product.stock}';
    } else {
      badgeBgColor = dangerColor.withOpacity(0.1);
      badgeTextColor = dangerColor;
      badgeText = 'Habis';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image Placeholder (80x80px)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: primaryColor.withOpacity(0.6),
              size: 32,
            ),
          ),

          const SizedBox(width: 12),

          // Middle: Column Info Layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Label
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                // Product Name
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Price (bold green)
                Text(
                  _formatPrice(product.price),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Supplier Info
                Text(
                  'Sup: ${product.supplier}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right: Badges & Edit Trigger
          SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Right Top: Stock Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeTextColor,
                    ),
                  ),
                ),

                // Right Bottom: Edit Action trigger icon
                GestureDetector(
                  onTap: () {
                    // Navigation to EditProductScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductFormScreen(product: product),
                      ),
                    ).then((value) {
                      if (value == true) {
                        setState(() {
                          _loadProducts();
                        });
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_square,
                      color: secondaryColor,
                      size: 20,
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

  /// Modern persistent bottom navigation bar
  Widget _buildBottomNavigationBar({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final navItems = [
      _BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
      _BottomNavItem(icon: Icons.inventory_2_rounded, label: 'Produk'),
      _BottomNavItem(icon: Icons.receipt_long_rounded, label: 'Transaksi'),
      _BottomNavItem(icon: Icons.local_shipping_outlined, label: 'Supplier'),
      _BottomNavItem(icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isActive = index == _currentNavIndex;

              return InkWell(
                onTap: () {
                  if (index == 0) {
                    Navigator.pop(context); // Go back to Home
                  } else {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigasi ke menu ${item.label} (Mock)'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? secondaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        color: isActive
                            ? secondaryColor
                            : const Color(0xFF94A3B8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isActive
                            ? secondaryColor
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? secondaryColor : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  const _BottomNavItem({required this.icon, required this.label});
}
