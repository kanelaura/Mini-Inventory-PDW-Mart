import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../data/database_helper.dart';
import 'dashboard_screen.dart';
import 'transaction_screen.dart';
import 'supplier_list_screen.dart';
import 'settings_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dialogController = TextEditingController();

  String _searchQuery = '';
  int _currentNavIndex = 1; // "Produk" is active by default (Index 1)

  // Aggregated values
  int _totalCategories = 0;
  int _totalProducts = 0;

  bool _isListLoading = true;
  bool _hasChanges = false; // Tracks changes for parent refresh

  @override
  void initState() {
    super.initState();
    _loadAggregations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dialogController.dispose();
    super.dispose();
  }

  /// Pre-loads SQLite metric totals
  Future<void> _loadAggregations() async {
    final catCount = await DatabaseHelper.instance.getCategoryCount();
    final prodCount = await DatabaseHelper.instance.getTotalProductCount();
    if (mounted) {
      setState(() {
        _totalCategories = catCount;
        _totalProducts = prodCount;
        _isListLoading = false;
      });
    }
  }

  /// Triggers full reload
  Future<void> _reloadScreen() async {
    await _loadAggregations();
  }

  /// Format datetime to match mockup distribution time labels
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'baru saja';
    } else if (difference.inMinutes < 60) {
      return 'modified ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'modified ${difference.inHours}h ago';
    } else {
      return 'modified ${difference.inDays}d ago';
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategoriesWithCounts(
      String search) async {
    final categories =
        await DatabaseHelper.instance.getCategories(search: search);
    final List<Map<String, dynamic>> result = [];
    for (final cat in categories) {
      final count = await DatabaseHelper.instance
          .getProductCountForCategory(cat.name);
      result.add({'category': cat, 'count': count});
    }
    return result;
  }

  Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('minum')) return const Color(0xFF3B82F6);
    if (lower.contains('makan')) return const Color(0xFF10B981);
    if (lower.contains('elektronik')) return const Color(0xFF8B5CF6);
    if (lower.contains('bersih')) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  /// Dialog modal trigger for INSERT Category
  void _showAddCategoryDialog() {
    _dialogController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Kategori Baru',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: _dialogController,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Nama Kategori (Contoh: Sabun)',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF00236F).withOpacity(0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00236F), width: 1.5),
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
              onPressed: () async {
                final name = _dialogController.text.trim();
                if (name.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  setState(() => _isListLoading = true);
                  await DatabaseHelper.instance.insertCategory(name);
                  if (!mounted) return;
                  _hasChanges = true;
                  _reloadScreen();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Kategori "$name" berhasil ditambahkan'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00236F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dialog modal trigger for UPDATE Category
  void _showEditCategoryDialog(CategoryModel category) {
    _dialogController.text = category.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Nama Kategori',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: _dialogController,
            autofocus: true,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Nama Kategori',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF00236F).withOpacity(0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00236F), width: 1.5),
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
              onPressed: () async {
                final newName = _dialogController.text.trim();
                if (newName.isNotEmpty && newName != category.name) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  setState(() => _isListLoading = true);
                  await DatabaseHelper.instance.updateCategory(
                    category.id,
                    newName,
                  );
                  if (!mounted) return;
                  _hasChanges = true;
                  _reloadScreen();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Nama kategori berhasil diperbarui'),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00236F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dialog modal trigger for DELETE Category
  void _showDeleteCategoryConfirm(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Kategori',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"? Semua produk dalam kategori ini akan kehilangan relasinya.',
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                setState(() => _isListLoading = true);
                await DatabaseHelper.instance.deleteCategory(category.id);
                if (!mounted) return;
                _hasChanges = true;
                _reloadScreen();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Kategori "${category.name}" telah dihapus'),
                    backgroundColor: const Color(0xFFBA1A1A),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A), // Error red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors Spec Alignments
    const Color primaryColor = Color(0xFF00236F);
    const Color highlightColor = Color(0xFF2170E4);
    const Color backgroundColor = Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, _hasChanges);
            }
          },
        ),
        title: const Text(
          'Kategori',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TOP HEADER CANVAS WITH SEARCH SECTION
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
              // STANDALONE FLOATING SEARCH CONTAINER BOX
              Positioned(
                bottom: -16,
                left: 20,
                right: 20,
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
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      color: Color(0xFF191C1E),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari kategori...',
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
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // BENTO SUMMARY BAR (2-column layout Grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Box One: Total Kategori
                Expanded(
                  child: _buildBentoMetric(
                    title: 'Total Kategori',
                    value: '$_totalCategories',
                    icon: Icons.grid_view,
                    iconBgColor: const Color(0xFFF3E8FF), // Light violet
                    iconColor: const Color(0xFF7C3AED), // Violet
                  ),
                ),
                const SizedBox(width: 16),
                // Box Two: Total Produk
                Expanded(
                  child: _buildBentoMetric(
                    title: 'Total Produk',
                    value: '$_totalProducts',
                    icon: Icons.inventory_2,
                    iconBgColor: const Color(0xFFEFF6FF), // Light blue
                    iconColor: const Color(0xFF3B82F6), // Blue
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CATEGORY CARD LIST VIEW
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadCategoriesWithCounts(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _isListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final categories = snapshot.data ?? [];

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 80.0),
                  itemCount: categories.length + 1, // list items + ghost card
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      // DASHED GHOST CARD PLACEHOLDER AT FOOTER
                      return _buildGhostCard();
                    }

                    final data = categories[index];
                    final category = data['category'] as CategoryModel;
                    final productCount = data['count'] as int;

                    return _buildCategoryCard(
                      category,
                      productCount: productCount,
                      primaryColor: primaryColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: highlightColor,
        elevation: 4,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        primaryColor: primaryColor,
        highlightColor: highlightColor,
      ),
    );
  }

  /// Bento metric cell widget layout
  Widget _buildBentoMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          // Value Label
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 4),
          // Title Label
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Category row widget card
  Widget _buildCategoryCard(
    CategoryModel category, {
    required int productCount,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
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
          // Left: square badge with emoji and custom painter pattern background
          CategoryEmojiBadge(
            emoji: category.emoji,
            backgroundColor: _getCategoryColor(category.name),
          ),

          const SizedBox(width: 16),

          // Middle: Text descriptions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 6),
                // Distribution details & timestamp
                Row(
                  children: [
                    Text(
                      '$productCount produk',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getRelativeTime(category.modifiedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Popup menu options & subtle structural chevron indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showEditCategoryDialog(category);
                  } else if (action == 'delete') {
                    _showDeleteCategoryConfirm(category);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text('Edit Kategori'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFBA1A1A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hapus Kategori',
                          style: TextStyle(color: Color(0xFFBA1A1A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ghost Card placeholder at footer triggering INSERT operation
  Widget _buildGhostCard() {
    return GestureDetector(
      onTap: _showAddCategoryDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle, color: Color(0xFF2170E4), size: 24),
            SizedBox(width: 10),
            Text(
              'Tambah Kategori Baru',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2170E4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Selection Bar
  Widget _buildBottomNavigationBar({
    required Color primaryColor,
    required Color highlightColor,
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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      (route) => false,
                    );
                  } else if (index == 1) {
                    setState(() { _currentNavIndex = 1; });
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TransactionScreen()),
                    );
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupplierListScreen()),
                    );
                  } else if (index == 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                            ? highlightColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        color: isActive
                            ? highlightColor
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
                            ? highlightColor
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? highlightColor : Colors.transparent,
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

/// Custom Widget: CategoryEmojiBadge
/// Displays category emoji with a colored background that uses
/// CustomPainter to draw a subtle decorative pattern behind it
class CategoryEmojiBadge extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;

  const CategoryEmojiBadge({
    super.key,
    required this.emoji,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BadgeBackgroundPainter(color: backgroundColor),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class _BadgeBackgroundPainter extends CustomPainter {
  final Color color;

  _BadgeBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw rounded rect background
    final bgPaint = Paint()..color = color.withOpacity(0.15);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Draw subtle decorative dots pattern
    final dotPaint = Paint()..color = color.withOpacity(0.12);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15), 6, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.85), 4, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.8), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_BadgeBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  const _BottomNavItem({required this.icon, required this.label});
}
