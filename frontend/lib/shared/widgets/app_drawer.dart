import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/data/services/user_service.dart';
import 'package:sagawa_pos/features/auth/presentation/pages/login_page.dart';
import 'package:sagawa_pos/features/settings/presentation/pages/settings_page.dart';
import 'package:sagawa_pos/features/profile/presentation/pages/profile_page.dart';
import 'package:sagawa_pos/features/menu/presentation/pages/menu_management_page.dart';
import 'package:sagawa_pos/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:sagawa_pos/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:sagawa_pos/features/order_history/presentation/pages/order_history_page.dart';
import 'package:sagawa_pos/features/order_history/presentation/cubit/order_history_cubit.dart';
import 'package:sagawa_pos/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos/features/financial_report/presentation/pages/financial_report_page.dart';
import 'package:sagawa_pos/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:sagawa_pos/features/financial_report/data/repositories/financial_report_repository.dart';

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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppImages.logOut,
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFF4B4B),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Keluar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Apakah Anda yakin ingin keluar dari aplikasi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          await UserService.clearUser();

                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4B4B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
