import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header with Logo
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
            ),
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: Image.asset(
                AppImages.appLogo,
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.store,
                    size: 80,
                    color: Color(0xFFFF4B4B),
                  );
                },
              ),
            ),
          ),

          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),

          // Menu Utama Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Menu Items
          _DrawerMenuItem(
            icon: AppImages.menuManager,
            label: 'Kelola Menu',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Menu Management
            },
          ),
          _DrawerMenuItem(
            icon: AppImages.orderHistory,
            label: 'Riwayat Pemesanan',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Order History
            },
          ),
          _DrawerMenuItem(
            icon: AppImages.moneyReport,
            label: 'Laporan Keuangan',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Financial Report
            },
          ),

          const Spacer(),

          // Aksesibilitas Section (Footer)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aksesibilitas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Settings
          _DrawerMenuItem(
            icon: AppImages.settingsIcon,
            label: 'Pengaturan',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Settings
            },
          ),

          // Profile
          _DrawerMenuItem(
            icon: AppImages.profileIcon,
            label: 'Profil',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Profile
            },
          ),

          const SizedBox(height: 12),

          // Logout Button
          Padding(
            padding: const EdgeInsets.only(bottom: 24, right: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: const Color(0xFFFF4B4B),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SvgPicture.asset(
                          AppImages.logOut,
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement logout logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
