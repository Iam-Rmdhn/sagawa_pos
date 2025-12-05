import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/auth/presentation/pages/login_page.dart';
import 'package:sagawa_pos_new/features/settings/presentation/pages/settings_page.dart';
import 'package:sagawa_pos_new/features/profile/presentation/pages/profile_page.dart';
import 'package:sagawa_pos_new/features/menu/presentation/pages/menu_management_page.dart';
import 'package:sagawa_pos_new/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:sagawa_pos_new/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:sagawa_pos_new/features/order_history/presentation/pages/order_history_page.dart';
import 'package:sagawa_pos_new/features/order_history/presentation/cubit/order_history_cubit.dart';
import 'package:sagawa_pos_new/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos_new/features/financial_report/presentation/pages/financial_report_page.dart';
import 'package:sagawa_pos_new/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:sagawa_pos_new/features/financial_report/data/repositories/financial_report_repository.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onMenuManagementClosed});

  final VoidCallback? onMenuManagementClosed;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = ResponsiveHelper.getDrawerWidth(context);

    return Drawer(
      backgroundColor: Colors.white,
      width: drawerWidth,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = ResponsiveHelper.isLandscape(context);
            final logoSize = isLandscape
                ? 60.0
                : (ResponsiveHelper.isMobile(context) ? 100.0 : 120.0);

            return Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header with Logo
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: isLandscape ? 12 : 24,
                          ),
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Center(
                            child: Image.asset(
                              AppImages.appLogo,
                              width: logoSize,
                              height: logoSize,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.store,
                                  size: logoSize * 0.8,
                                  color: const Color(0xFFFF4B4B),
                                );
                              },
                            ),
                          ),
                        ),

                        // Divider
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE0E0E0),
                        ),

                        // Menu Utama Section
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            isLandscape ? 8 : 10,
                            24,
                            0,
                          ),
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
                          compact: isLandscape,
                          onTap: () async {
                            Navigator.pop(context);
                            print(
                              'DEBUG AppDrawer: Navigating to Menu Management...',
                            );
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) =>
                                      MenuCubit(MenuRepositoryImpl())
                                        ..loadMenuItems(),
                                  child: const MenuManagementPage(),
                                ),
                              ),
                            );
                            print(
                              'DEBUG AppDrawer: Returned from Menu Management, calling callback...',
                            );
                            onMenuManagementClosed?.call();
                            print('DEBUG AppDrawer: Callback called');
                          },
                        ),
                        _DrawerMenuItem(
                          icon: AppImages.orderHistory,
                          label: 'Riwayat Pemesanan',
                          compact: isLandscape,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) => OrderHistoryCubit(
                                    OrderHistoryRepository(),
                                  )..loadOrders(),
                                  child: const OrderHistoryPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        _DrawerMenuItem(
                          icon: AppImages.moneyReport,
                          label: 'Laporan Penjualan',
                          compact: isLandscape,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) => FinancialReportCubit(
                                    FinancialReportRepository(),
                                  )..loadReport(),
                                  child: const FinancialReportPage(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Section - Aksesibilitas + Logout Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Aksesibilitas Section - Fixed at bottom
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isLandscape ? 8 : 10,
                        24,
                        0,
                      ),
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
                      compact: isLandscape,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),

                    // Profile
                    _DrawerMenuItem(
                      icon: AppImages.profileIcon,
                      label: 'Akun',
                      compact: isLandscape,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                    ),

                    // Logout Button (fixed at bottom)
                    Padding(
                      padding: EdgeInsets.only(
                        top: isLandscape ? 8 : 12,
                        bottom: isLandscape ? 12 : 24,
                      ),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 24 : 32,
                                vertical: isLandscape ? 12 : 16,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Keluar',
                                    style: TextStyle(
                                      fontSize: isLandscape ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SvgPicture.asset(
                                    AppImages.logOut,
                                    width: isLandscape ? 20 : 24,
                                    height: isLandscape ? 20 : 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color.fromARGB(255, 255, 255, 255),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  SizedBox(width: isLandscape ? 16 : 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
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
              onPressed: () async {
                Navigator.pop(context);

                // Clear user data from SharedPreferences
                await UserService.clearUser();

                // Navigate to login and remove all previous routes
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
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
    this.compact = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: compact ? 12 : 16,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                icon,
                width: compact ? 20 : 24,
                height: compact ? 20 : 24,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
