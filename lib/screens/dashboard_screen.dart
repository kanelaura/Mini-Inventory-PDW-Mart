import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_list_screen.dart';
import 'transaction_screen.dart';
import 'supplier_list_screen.dart';
import 'settings_screen.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../data/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Store info state
  String _storeName = 'PDW Mart';
  String _ownerName = 'Pemilik';

  // Metrics state
  int _totalProducts = 0;
  int _lowStockCount = 0;
  int _todayTransactions = 0;
  int _totalSuppliers = 0;

  // Lists state
  List<Product> _lowStockItems = [];
  List<TransactionItem> _recentTransactions = [];

  bool _isLoading = true;
  int _currentNavIndex = 0; // Home is active by default

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Fetches values from SharedPreferences and SQLite database helpers
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Load SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      final savedStoreName = prefs.getString('store_name');
      final savedOwnerName = prefs.getString('owner_name');

      if (mounted) {
        setState(() {
          _storeName =
              (savedStoreName != null && savedStoreName.trim().isNotEmpty)
              ? savedStoreName.trim()
              : 'PDW Mart';
          _ownerName =
              (savedOwnerName != null && savedOwnerName.trim().isNotEmpty)
              ? savedOwnerName.trim()
              : 'Pemilik';
        });
      }

      // 2. Fetch SQLite DB Aggregations & Lists
      final totalProductsFuture = DatabaseHelper.instance
          .getTotalProductsCount();
      final lowStockCountFuture = DatabaseHelper.instance.getLowStockCount();
      final todayTxCountFuture = DatabaseHelper.instance
          .getTodayTransactionsCount();
      final suppliersFuture = DatabaseHelper.instance.getSuppliersCount();
      final lowStockListFuture = DatabaseHelper.instance.getLowStockItems();
      final recentTxFuture = DatabaseHelper.instance.getRecentTransactions();

      // Resolve all mock futures asynchronously
      final results = await Future.wait([
        totalProductsFuture,
        lowStockCountFuture,
        todayTxCountFuture,
        suppliersFuture,
        lowStockListFuture,
        recentTxFuture,
      ]);

      if (mounted) {
        setState(() {
          _totalProducts = results[0] as int;
          _lowStockCount = results[1] as int;
          _todayTransactions = results[2] as int;
          _totalSuppliers = results[3] as int;
          _lowStockItems = results[4] as List<Product>;
          _recentTransactions = results[5] as List<TransactionItem>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan memuat data: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  /// Triggered by pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadAllData();
  }

  /// Helper to get initials of the store owner
  String _getInitials(String name) {
    if (name.isEmpty) return 'PM';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Helper to format date beautifully in Indonesian
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

  /// Format transaction date/time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Hari ini, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTheme = Color(0xFF00236F);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTheme))
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: primaryTheme,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP HEADER
                    _buildTopHeader(),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SUMMARY CARDS ROW (Horizontal Scrollable)
                          _buildSummaryCardsSection(),

                          const SizedBox(height: 28),

                          // ALERT SECTION (STOK MENIPIS)
                          _buildLowStockSection(),

                          const SizedBox(height: 28),

                          // RECENT TRANSACTIONS SECTION
                          _buildRecentTransactionsSection(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Builds the top header with stores, owners, date, initials, and search bar
  Widget _buildTopHeader() {
    const Color primaryTheme = Color(0xFF00236F);
    return Container(
      decoration: const BoxDecoration(
        color: primaryTheme,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting & Initials Profile Circle Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat datang,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF93C5FD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _storeName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getFormattedDate(),
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF93C5FD).withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Circular Profile Icon with owner's initials
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_ownerName),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Bar inside header
              Container(
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
                child: const TextField(
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari produk atau transaksi...',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: primaryTheme,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the horizontally scrollable Summary Metrics Cards
  Widget _buildSummaryCardsSection() {
    const Color accentTheme = Color(0xFF2170E4);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMetricCard(
            title: 'Total Produk',
            value: '$_totalProducts',
            icon: Icons.inventory_2,
            iconColor: accentTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              ).then((_) => _loadAllData());
            },
          ),
          _buildMetricCard(
            title: 'Stok Menipis',
            value: '$_lowStockCount',
            icon: Icons.warning,
            iconColor: const Color(0xFFF59E0B), // Warning Color
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              ).then((_) => _loadAllData());
            },
          ),
          _buildMetricCard(
            title: 'Transaksi',
            value: '$_todayTransactions',
            icon: Icons.receipt_long,
            iconColor: accentTheme,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionScreen(),
                ),
              ).then((_) => _loadAllData());
            },
          ),
          _buildMetricCard(
            title: 'Supplier',
            value: '$_totalSuppliers',
            icon: Icons.local_shipping,
            iconColor: const Color(0xFF10B981), // Success Color
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupplierListScreen(),
                ),
              ).then((_) => _loadAllData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 136,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the low stock list section
  Widget _buildLowStockSection() {
    const Color accentTheme = Color(0xFF2170E4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title & "Lihat Semua" row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stok Menipis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                _showLihatSemuaDialog('Stok Menipis');
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentTheme,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Vertical List
        if (_lowStockItems.isEmpty)
          _buildEmptyCard('Tidak ada stok menipis')
        else
          ..._lowStockItems.map((item) => _buildLowStockCard(item)),
      ],
    );
  }

  Widget _buildLowStockCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image placeholder on the left
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Product info in the middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Category Chip tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Orange Badge container on the right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SISA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.stock}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B), // Bold Orange
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the recent transactions list section
  Widget _buildRecentTransactionsSection() {
    const Color accentTheme = Color(0xFF2170E4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title & "Lihat Semua" row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                _showLihatSemuaDialog('Transaksi Terbaru');
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accentTheme,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Vertical List of stock movements
        if (_recentTransactions.isEmpty)
          _buildEmptyCard('Belum ada transaksi hari ini')
        else
          ..._recentTransactions.map((tx) => _buildTransactionRow(tx)),
      ],
    );
  }

  Widget _buildTransactionRow(TransactionItem tx) {
    final isSale = tx.type == 'sale';
    final iconColor = isSale
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final iconBgColor = iconColor.withOpacity(0.1);
    final qtyColor = isSale ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final qtyPrefix = isSale ? '' : '+';
    final qtyText = '$qtyPrefix${tx.quantityChange} pcs';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Icon Container on the left
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSale ? Icons.shopping_cart_outlined : Icons.add_circle_outline,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Transaction info in the middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(tx.dateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Qty difference badge on the right
          Text(
            qtyText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: qtyColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern persistent bottom navigation bar
  Widget _buildBottomNavigationBar() {
    const Color primaryTheme = Color(0xFF00236F);
    final navItems = [
      _BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
      _BottomNavItem(icon: Icons.inventory_2_outlined, label: 'Produk'),
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
                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductListScreen(),
                      ),
                    ).then((_) {
                      _loadAllData();
                    });
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionScreen(),
                      ),
                    ).then((_) {
                      _loadAllData();
                    });
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupplierListScreen(),
                      ),
                    ).then((_) {
                      _loadAllData();
                    });
                  } else if (index == 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ).then((_) {
                      _loadAllData();
                    });
                  } else {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    // Showcase click response
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
                            ? primaryTheme.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        color: isActive
                            ? primaryTheme
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
                            ? primaryTheme
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    // Dot indicator below
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? primaryTheme : Colors.transparent,
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

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showLihatSemuaDialog(String title) {
    const Color primaryTheme = Color(0xFF00236F);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Halaman detail lengkap untuk $title akan segera hadir pada fase pengembangan berikutnya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: primaryTheme,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  const _BottomNavItem({required this.icon, required this.label});
}
