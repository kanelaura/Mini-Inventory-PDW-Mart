import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart'; // Import to logout back to login phase
import 'product_list_screen.dart';
import 'transaction_screen.dart';
import 'supplier_list_screen.dart';
import '../data/database_helper.dart';
import '../data/supplier_database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preference States
  String _storeName = 'PDW Mart';
  String _ownerName = 'John Doe';
  String _location = 'Bandung, Jawa Barat';
  bool _isDarkMode = false;
  bool _isSyncActive = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Load store preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _storeName = prefs.getString('store_name') ?? 'PDW Mart';
          _ownerName = prefs.getString('owner_name') ?? 'John Doe';
          _location = prefs.getString('store_location') ?? 'Bandung, Jawa Barat';
          _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
          _isSyncActive = prefs.getBool('is_sync_active') ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Save edited store preferences
  Future<void> _savePreferences(
      String storeName, String ownerName, String location) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_name', storeName);
      await prefs.setString('owner_name', ownerName);
      await prefs.setString('store_location', location);
      if (mounted) {
        setState(() {
          _storeName = storeName;
          _ownerName = ownerName;
          _location = location;
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  /// Get profile initials
  String _getInitials(String name) {
    if (name.isEmpty) return 'PM';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Trigger Modal Bottom Sheet to edit store details
  void _showEditStoreSheet() {
    final storeController = TextEditingController(text: _storeName);
    final ownerController = TextEditingController(text: _ownerName);
    final locationController = TextEditingController(text: _location);
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
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.0,
            24.0,
            20.0,
            MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ubah Informasi Toko',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00236F),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: storeController,
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Nama Toko',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.storefront, color: Color(0xFF00236F)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama toko wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ownerController,
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Nama Pemilik',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF00236F)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama pemilik wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Lokasi / Kota',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF00236F)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final store = storeController.text.trim();
                      final owner = ownerController.text.trim();
                      final loc = locationController.text.trim();
                      await _savePreferences(store, owner, loc);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Informasi toko berhasil disimpan!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00236F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog modal to confirm database reset safety
  void _confirmDeleteAllData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Hapus Semua Data',
            style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF4444),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua data? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.hankenGrotesk(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.hankenGrotesk(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                navigator.pop();
                
                try {
                  // Delete all products
                  final products = await DatabaseHelper.instance.getProducts();
                  for (final product in products) {
                    await DatabaseHelper.instance.deleteProduct(product.id);
                  }
                  
                  // Delete all categories
                  final categories = await DatabaseHelper.instance.getCategories();
                  for (final cat in categories) {
                    await DatabaseHelper.instance.deleteCategory(cat.id);
                  }
                  
                  // Delete all suppliers
                  final suppliers = await SupplierDatabaseHelper.instance.getSuppliers();
                  for (final sup in suppliers) {
                    await SupplierDatabaseHelper.instance.deleteSupplier(sup.id);
                  }
                  
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Semua data berhasil dihapus!'),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus data: $e'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Hapus Semua',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Triggers local backup operation
  void _triggerBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berhasil dicadangkan ke penyimpanan lokal'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  /// Triggers logout navigation
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear local preferences

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Specs colors palette
    const Color headerPrimary = Color(0xFF00236F);
    const Color accentWarning = Color(0xFFEF4444);
    const Color cleanBackground = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: cleanBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: headerPrimary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Canvas with overlapping card
                        _buildHeaderCanvas(headerPrimary),
                        const SizedBox(height: 60), // Space to compensate for the overlapping card (height: 100, bottom: -50)
                        
                        // Settings List Panel
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // SECTION TOKO
                              _buildSectionHeader('TOKO'),
                              _buildSettingsGroupCard([
                                _buildTileItem(
                                  icon: Icons.storefront,
                                  title: 'Informasi Toko',
                                  onTap: _showEditStoreSheet,
                                ),
                                _buildTileItem(
                                  icon: Icons.balance,
                                  title: 'Satuan Produk',
                                  trailing: 'pcs',
                                ),
                                _buildTileItem(
                                  icon: Icons.warning_amber_rounded,
                                  title: 'Batas Stok Minimum',
                                  trailing: '5',
                                ),
                                _buildTileItem(
                                  icon: Icons.receipt,
                                  title: 'Format Struk',
                                  trailing: 'A4',
                                ),
                              ]),

                              const SizedBox(height: 20),

                              // SECTION TAMPILAN
                              _buildSectionHeader('TAMPILAN'),
                              _buildSettingsGroupCard([
                                SettingsToggleTile(
                                  icon: Icons.dark_mode,
                                  title: 'Mode Gelap',
                                  value: _isDarkMode,
                                  activeColor: const Color(0xFF2170E4),
                                  onChanged: (val) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setBool('is_dark_mode', val);
                                    if (mounted) {
                                      setState(() { _isDarkMode = val; });
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Mode Gelap ${val ? "Aktif" : "Nonaktif"}'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                _buildTileItem(
                                  icon: Icons.translate,
                                  title: 'Bahasa',
                                  trailing: 'Indonesia',
                                ),
                                _buildTileItem(
                                  icon: Icons.color_lens,
                                  title: 'Tema Warna',
                                  widgetTrailing: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: headerPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 20),

                              // SECTION DATA & KEAMANAN
                              _buildSectionHeader('DATA & KEAMANAN'),
                              _buildSettingsGroupCard([
                                _buildTileItem(
                                  icon: Icons.lock_outline,
                                  title: 'PIN Keamanan',
                                  widgetTrailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'AKTIF',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildTileItem(
                                  icon: Icons.backup_outlined,
                                  title: 'Backup Data',
                                  subtitle: 'Terakhir: 1 hari lalu',
                                  onTap: _triggerBackup,
                                ),
                                SettingsToggleTile(
                                  icon: Icons.sync,
                                  title: 'Sinkronisasi',
                                  value: _isSyncActive,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (val) async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setBool('is_sync_active', val);
                                    setState(() { _isSyncActive = val; });
                                  },
                                ),
                                _buildTileItem(
                                  icon: Icons.delete_forever_outlined,
                                  title: 'Hapus Semua Data',
                                  titleColor: accentWarning,
                                  onTap: _confirmDeleteAllData,
                                ),
                              ]),

                              const SizedBox(height: 20),

                              // SECTION TENTANG
                              _buildSectionHeader('TENTANG'),
                              _buildSettingsGroupCard([
                                _buildTileItem(
                                  icon: Icons.info_outline,
                                  title: 'Versi Aplikasi',
                                  trailing: 'v1.0.0',
                                ),
                                _buildTileItem(
                                  icon: Icons.privacy_tip_outlined,
                                  title: 'Kebijakan Privasi',
                                  onTap: () {},
                                ),
                                _buildTileItem(
                                  icon: Icons.star_rate_outlined,
                                  title: 'Beri Rating',
                                  onTap: () {},
                                ),
                                _buildTileItem(
                                  icon: Icons.chat_bubble_outline,
                                  title: 'Hubungi Kami',
                                  onTap: () {},
                                ),
                              ]),

                              const SizedBox(height: 28),

                              // Full width logout button
                              _buildLogoutButton(accentWarning),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky System Navigation Bar
                _buildSystemNavigationBar(headerPrimary),
              ],
            ),
    );
  }

  /// Curved app bar solid banner
  Widget _buildHeaderCanvas(Color headerPrimary) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: headerPrimary,
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pengaturan',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlapping store profile card
          Positioned(
            bottom: -50,
            left: 20,
            right: 20,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Gradient initials avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00236F), Color(0xFF2170E4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_ownerName),
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Store Owner stack
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _storeName,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pemilik: $_ownerName',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              _location,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Edit launch button
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Color(0xFF2170E4), size: 20),
                    onPressed: _showEditStoreSheet,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// White background card grouping lists
  Widget _buildSettingsGroupCard(List<Widget> children) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(children.length, (idx) {
          final child = children[idx];
          if (idx == children.length - 1) {
            return child;
          }
          return Column(
            children: [
              child,
              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 48),
            ],
          );
        }),
      ),
    );
  }

  /// Single tile setting list
  Widget _buildTileItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    Color? titleColor,
    Widget? widgetTrailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: titleColor ?? const Color(0xFF64748B), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (widgetTrailing != null)
              widgetTrailing
            else if (trailing != null)
              Text(
                trailing,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                ),
              )
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }

  /// Bold Logout button
  Widget _buildLogoutButton(Color accentWarning) {
    return SizedBox(
      height: 52,
      child: TextButton.icon(
        onPressed: _logout,
        icon: Icon(Icons.logout, color: accentWarning, size: 18),
        label: Text(
          'Keluar dari Aplikasi',
          style: GoogleFonts.hankenGrotesk(
            color: accentWarning,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: accentWarning.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// System Navigation Bar
  Widget _buildSystemNavigationBar(Color headerPrimary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                Navigator.of(context).popUntil((route) => route.isFirst);
              }),
              _buildNavItem(Icons.inventory_2_outlined, 'Produk', false, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductListScreen()),
                );
              }),
              _buildNavItem(Icons.receipt_long_rounded, 'Transaksi', false, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionScreen()),
                );
              }),
              _buildNavItem(Icons.local_shipping_outlined, 'Supplier', false, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierListScreen()),
                );
              }),
              _buildNavItem(Icons.settings_outlined, 'Settings', true, () {
                // Stays on settings
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    final Color primaryTheme = const Color(0xFF00236F);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? primaryTheme.withValues(alpha: 0.08) : Colors.transparent,
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

/// Custom Widget: SettingsToggleTile
/// An animated settings tile with slide gesture support
/// Slide right to activate, slide left to deactivate
class SettingsToggleTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF2170E4),
  });

  @override
  State<SettingsToggleTile> createState() => _SettingsToggleTileState();
}

class _SettingsToggleTileState extends State<SettingsToggleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _bgAnim;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.value ? 1.0 : 0.0,
    );
    _bgAnim = ColorTween(
      begin: Colors.transparent,
      end: widget.activeColor.withValues(alpha: 0.06),
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(SettingsToggleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Custom gesture: horizontal drag to toggle
      onHorizontalDragStart: (details) {
        _dragStartX = details.localPosition.dx;
      },
      onHorizontalDragEnd: (details) {
        final dragDistance = details.localPosition.dx - _dragStartX;
        if (dragDistance > 30 && !widget.value) {
          widget.onChanged(true);
        } else if (dragDistance < -30 && widget.value) {
          widget.onChanged(false);
        }
      },
      child: AnimatedBuilder(
        animation: _bgAnim,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            color: _bgAnim.value,
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.value
                    ? widget.activeColor
                    : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Switch(
                value: widget.value,
                activeThumbColor: widget.activeColor,
                onChanged: widget.onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
