import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import 'transaction_screen.dart';
import 'product_list_screen.dart';
import 'supplier_list_screen.dart';
import 'settings_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedFilter =
      'Semua'; // 'Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Custom'
  DateTimeRange? _customDateRange;
  String? _statusFilter; // null = semua status

  bool _isLoading = true;

  // Database states
  double _todayRevenue = 0.0;
  double _weekRevenue = 0.0;
  double _monthRevenue = 0.0;
  List<Map<String, dynamic>> _transactionsList = [];
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};

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

  void _applyStatusFilter(String? status) {
    setState(() {
      _statusFilter = status;
    });
    _loadAllData();
  }

  /// Reloads all reports and lists matching search / filter parameters
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Fetch Aggregated Reports
      final reporting = await DatabaseHelper.instance
          .getTransactionSummaryReporting();

      // 2. Fetch Lists with current filters
      final list = await DatabaseHelper.instance.getTransactions(
        search: _searchQuery,
        dateFilter: _selectedFilter,
        customDateRange: _customDateRange,
        statusFilter: _statusFilter,
      );

      // Group chronologically
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final tx in list) {
        final key = _formatGroupDate(tx['timestamp'] as DateTime);
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(tx);
      }

      if (mounted) {
        setState(() {
          _todayRevenue = reporting['hari_ini'] ?? 0.0;
          _weekRevenue = reporting['minggu_ini'] ?? 0.0;
          _monthRevenue = reporting['bulan_ini'] ?? 0.0;
          _transactionsList = list;
          _groupedTransactions = grouped;
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
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: const Color(0xFFC62828), // Error Accent
          ),
        );
      }
    }
  }

  /// Date header format helper
  String _formatGroupDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (txDate == today) {
      return 'HARI INI, ${_getFormattedDateString(dateTime).toUpperCase()}';
    } else if (txDate == yesterday) {
      return 'KEMARIN, ${_getFormattedDateString(dateTime).toUpperCase()}';
    } else {
      return _getFormattedDateString(dateTime).toUpperCase();
    }
  }

  String _getFormattedDateString(DateTime dateTime) {
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
    final dayName = days[dateTime.weekday % 7];
    final monthName = months[dateTime.month - 1];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  String _formatTimeOnly(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  String _formatCurrency(double value) {
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

  /// Opens Date Range Picker for Custom selection
  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A), // primaryContainer
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedFilter = 'Custom';
        _customDateRange = picked;
      });
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Specs palette layout
    const Color primaryContainer = Color(0xFF1E3A8A);
    const Color primaryContrast = Color(0xFF2170E4);
    const Color successAccent = Color(0xFF2E7D32);
    const Color errorAccent = Color(0xFFC62828);
    const Color warningAccent = Color(0xFFE65100);
    const Color canvasLayer = Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor: canvasLayer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App bar and search container banner
          _buildAppBarHeader(primaryContainer),

          // Core scroll content area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: primaryContainer,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 52.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Period filter chips
                    _buildFilterChips(primaryContainer, primaryContrast),

                    const SizedBox(height: 20),

                    // Results stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Data Transaksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${_transactionsList.length} Transaksi',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Grouped chronological listing
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: CircularProgressIndicator(
                                color: primaryContainer,
                              ),
                            ),
                          )
                        : _groupedTransactions.isEmpty
                        ? _buildEmptyState()
                        : _buildGroupedTrail(
                            primaryContainer,
                            successAccent,
                            errorAccent,
                            warningAccent,
                          ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky system navigator bar
          _buildSystemNavigationBar(primaryContainer),
        ],
      ),
    );
  }

  /// App Bar Header with Slate Blue container background and Integrated Search
  Widget _buildAppBarHeader(Color primaryContainer) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                            onPressed: _showFilterOptionsModal,
                          ),
                          if (_statusFilter != null)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Integrated Search Input (White Background)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFF1E3A8A),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
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
                              hintText: 'Cari ID transaksi atau produk...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pencarian suara (Simulasi)'),
                                ),
                              );
                            }
                          },
                          child: const Icon(
                            Icons.mic,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlapping metrics summaries horizontal cards row
          Positioned(
            bottom: -38,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMetricCard(
                    title: 'Hari Ini',
                    value: _formatCurrency(_todayRevenue),
                    icon: Icons.receipt,
                    iconColor: const Color(0xFF1E3A8A),
                  ),
                  _buildMetricCard(
                    title: 'Minggu Ini',
                    value: _formatCurrency(_weekRevenue),
                    icon: Icons.calendar_today,
                    iconColor: const Color(0xFF2170E4),
                  ),
                  _buildMetricCard(
                    title: 'Bulan Ini',
                    value: _formatCurrency(_monthRevenue),
                    icon: Icons.bar_chart,
                    iconColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single metric card detail layout
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ribbon of chips filters
  Widget _buildFilterChips(Color primaryContainer, Color primaryContrast) {
    final filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini'];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ...filters.map((filter) {
            final isActive = _selectedFilter == filter;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isActive,
                showCheckmark: false,
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                backgroundColor: Colors.white,
                selectedColor: primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isActive
                        ? primaryContainer
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = filter;
                      _customDateRange = null;
                    });
                    _loadAllData();
                  }
                },
              ),
            );
          }),

          // Custom Filter Chip containing Icon tune
          FilterChip(
            selected: _selectedFilter == 'Custom',
            showCheckmark: false,
            label: Row(
              children: [
                const Icon(Icons.tune, size: 14),
                const SizedBox(width: 4),
                Text(
                  _selectedFilter == 'Custom' && _customDateRange != null
                      ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                      : 'Custom',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _selectedFilter == 'Custom'
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: _selectedFilter == 'Custom'
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            selectedColor: primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: _selectedFilter == 'Custom'
                    ? primaryContainer
                    : const Color(0xFFCBD5E1),
              ),
            ),
            onSelected: (selected) {
              _selectCustomDateRange();
            },
          ),
        ],
      ),
    );
  }

  /// Empty State Card layout
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
          children: const [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada riwayat transaksi',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pastikan pencarian dan filter tanggal Anda sesuai',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Chronological group cards renderer
  Widget _buildGroupedTrail(
    Color primaryContainer,
    Color successAccent,
    Color errorAccent,
    Color warningAccent,
  ) {
    final keys = _groupedTransactions.keys.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount:
          keys.length + 1, // Add 1 for the dashed footer button at the end
      itemBuilder: (context, index) {
        if (index == keys.length) {
          return AnimatedDashedButton(
            borderColor: primaryContainer.withOpacity(0.5),
            onTap: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menampilkan transaksi lebih lama'),
                  ),
                );
              }
            },
          );
        }

        final key = keys[index];
        final list = _groupedTransactions[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chronological section header
            Container(
              margin: const EdgeInsets.only(top: 18, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Nested individual cards
            ...list.map((tx) {
              return _buildTransactionCard(
                tx,
                successAccent: successAccent,
                errorAccent: errorAccent,
                warningAccent: warningAccent,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  /// Individual sales transaction card details
  Widget _buildTransactionCard(
    Map<String, dynamic> tx, {
    required Color successAccent,
    required Color errorAccent,
    required Color warningAccent,
  }) {
    final status = tx['status'] as String? ?? 'Selesai';
    final items = tx['items'] as List? ?? [];
    final double totalPay = tx['total_pay'] as double? ?? 0.0;
    final DateTime ts = tx['timestamp'] as DateTime;

    Color badgeBgColor;
    Color badgeTextColor;

    if (status == 'Selesai') {
      badgeBgColor = successAccent.withOpacity(0.12);
      badgeTextColor = successAccent;
    } else if (status == 'Dibatalkan') {
      badgeBgColor = errorAccent.withOpacity(0.12);
      badgeTextColor = errorAccent;
    } else {
      badgeBgColor = warningAccent.withOpacity(0.12);
      badgeTextColor = warningAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row (Invoice details vs Status Badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['id'] ?? 'TRX-UNKNOWN',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeOnly(ts),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Mid Row (Wraps pills of purchased assets)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((item) {
                final String name = item['name'] ?? '';
                final int qty = item['quantity'] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '$name ×$qty',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Divider(height: 24, color: Color(0xFFF1F5F9)),

            // Bottom Row (Total Tagihan summary)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Tagihan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  _formatCurrency(totalPay),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  /// System Navigation Bar
  Widget _buildSystemNavigationBar(Color primaryContainer) {
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
              _buildNavItem(Icons.receipt_long_rounded, 'Transaksi', true, () {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const TransactionScreen(),
                    ),
                  );
                }
              }),
              _buildNavItem(
                Icons.local_shipping_outlined,
                'Supplier',
                false,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupplierListScreen()),
                  );
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
    final Color primaryContainer = const Color(0xFF1E3A8A);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryContainer.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? primaryContainer : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? primaryContainer : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }


  /// Trailing filter options bottom modal sheet
  void _showFilterOptionsModal() {
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
              const Text(
                'Urutkan Status',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Color(0xFF1E3A8A)),
                title: const Text('Semua Status',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _statusFilter == null
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter(null);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text(
                  'Selesai',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: _statusFilter == 'Selesai'
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter('Selesai');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.cancel_outlined,
                  color: Color(0xFFC62828),
                ),
                title: const Text(
                  'Dibatalkan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: _statusFilter == 'Dibatalkan'
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter('Dibatalkan');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.pending_actions,
                  color: Color(0xFFE65100),
                ),
                title: const Text(
                  'Pending',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: _statusFilter == 'Pending'
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _applyStatusFilter('Pending');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Widget: AnimatedDashedButton
/// A button with dashed border using CustomPainter and
/// scale animation gesture feedback
class AnimatedDashedButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color borderColor;

  const AnimatedDashedButton({
    super.key,
    required this.onTap,
    required this.borderColor,
  });

  @override
  State<AnimatedDashedButton> createState() => _AnimatedDashedButtonState();
}

class _AnimatedDashedButtonState extends State<AnimatedDashedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          height: 52,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: widget.borderColor,
              borderRadius: 12.0,
              gap: 6.0,
              dashLength: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lihat Transaksi Sebelumnya',
                  style: TextStyle(
                    color: widget.borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.expand_more, color: widget.borderColor, size: 20),
              ],
            ),
          ),
        ),
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
