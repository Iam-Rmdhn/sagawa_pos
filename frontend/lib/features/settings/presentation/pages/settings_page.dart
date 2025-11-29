import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/auth/presentation/pages/login_page.dart';
import 'package:sagawa_pos_new/features/profile/presentation/pages/profile_page.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/pages/printer_configuration_page.dart';
import 'package:sagawa_pos_new/features/settings/presentation/widgets/location_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isTaxEnabled = false;
  String _location = '';
  static const String _taxPrefsKey = 'tax_enabled';
  static const String _locationPrefsKey = 'user_location';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTaxEnabled = prefs.getBool(_taxPrefsKey) ?? false;
      _location = prefs.getString(_locationPrefsKey) ?? '';
    });
  }

  Future<void> _saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationPrefsKey, location);
    setState(() {
      _location = location;
    });
  }

  Future<void> _saveTaxPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taxPrefsKey, value);
  }

  Future<void> _clearCache() async {
    // Save the context before opening dialog
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Cache',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua cache aplikasi? Data login dan pengaturan Anda akan tetap tersimpan.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // Clear temporary directory
                final tempDir = await getTemporaryDirectory();
                if (tempDir.existsSync()) {
                  await tempDir.delete(recursive: true);
                  await tempDir.create();
                }

                // Clear application cache directory
                final cacheDir = await getApplicationCacheDirectory();
                if (cacheDir.existsSync()) {
                  await cacheDir.delete(recursive: true);
                  await cacheDir.create();
                }

                if (!mounted) return;
                CustomSnackbar.show(
                  scaffoldContext,
                  message: 'Cache berhasil dihapus',
                  type: SnackbarType.success,
                );
              } catch (e) {
                if (!mounted) return;
                CustomSnackbar.show(
                  scaffoldContext,
                  message: 'Gagal menghapus cache: $e',
                  type: SnackbarType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Clear user data from SharedPreferences
              await UserService.clearUser();

              // Navigate to login and remove all previous routes
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom AppBar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFF4B4B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: SvgPicture.asset(
                        AppImages.backArrow,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Title
                    const Expanded(
                      child: Text(
                        'Pengaturan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Profile Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        AppImages.profileIcon,
                        width: 30,
                        height: 30,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Bahasa
                _SettingsItem(
                  icon: AppImages.languageIcon,
                  title: 'Bahasa',
                  onTap: () {
                    // TODO: Navigate to language selection page
                    CustomSnackbar.show(
                      context,
                      message: 'Fitur bahasa akan segera hadir',
                      type: SnackbarType.info,
                    );
                  },
                ),

                // Lokasi
                _SettingsItem(
                  icon: AppImages.locationIcon,
                  title: 'Lokasi',
                  onTap: () async {
                    final result = await showLocationDialog(
                      context,
                      currentLocation: _location.isNotEmpty ? _location : null,
                    );
                    if (result != null) {
                      await _saveLocation(result);
                      if (!mounted) return;
                      CustomSnackbar.show(
                        context,
                        message: 'Lokasi berhasil disimpan',
                        type: SnackbarType.success,
                      );
                    }
                  },
                ),

                // Konfigurasi Printer
                _SettingsItem(
                  icon: AppImages.print2Icon,
                  title: 'Konfigurasi Printer',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrinterConfigurationPage(),
                      ),
                    );
                  },
                ),

                // Hapus Cache
                _SettingsItemWithIcon(
                  iconPath: AppImages.trashIcon,
                  title: 'Hapus Cache',
                  subtitle: 'Bersihkan data sementara aplikasi',
                  onTap: _clearCache,
                ),

                // PB1 (Tax) 10% - with toggle
                _SettingsItemWithToggle(
                  icon: AppImages.taxIcon,
                  title: 'PB1 10%',
                  value: _isTaxEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _isTaxEnabled = value;
                    });
                    await _saveTaxPreference(value);

                    if (!mounted) return;
                    CustomSnackbar.show(
                      context,
                      message: value
                          ? 'Tax 10% diaktifkan'
                          : 'Tax 10% dinonaktifkan',
                      type: value ? SnackbarType.success : SnackbarType.info,
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Button - Sticky Bottom
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              top: 2,
              right: 20,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.0),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B4B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings item widget with arrow indicator
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final String icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Icon
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}

// Settings item widget with Material icon
class _SettingsItemWithIcon extends StatelessWidget {
  const _SettingsItemWithIcon({
    required this.iconPath,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String iconPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Icon
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 16),
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
      ],
    );
  }
}

// Settings item widget with toggle switch
class _SettingsItemWithToggle extends StatelessWidget {
  const _SettingsItemWithToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon
          SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.black87,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          // Toggle Switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFD966),
            activeTrackColor: const Color(0xFFFF4B4B),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
