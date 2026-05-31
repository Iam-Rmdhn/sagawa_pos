import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sagawa_pos/core/network/api_config.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos/data/services/category_service.dart';
import 'package:sagawa_pos/data/services/menu_sync_websocket_service.dart';
import 'package:sagawa_pos/data/services/settings_service.dart';
import 'package:sagawa_pos/data/services/transaction_service.dart';
import 'package:sagawa_pos/data/services/user_service.dart';
import 'package:sagawa_pos/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos/features/home/domain/models/product.dart';
import 'package:sagawa_pos/features/home/presentation/widgets/home_app_bar.dart';
import 'package:sagawa_pos/features/home/presentation/widgets/home_category_card.dart';
import 'package:sagawa_pos/features/order/presentation/pages/order_detail_page.dart';
import 'package:sagawa_pos/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos/features/receipt/receipt.dart';
import 'package:sagawa_pos/features/settings/presentation/widgets/location_dialog.dart';
import 'package:sagawa_pos/shared/widgets/app_drawer.dart';
import 'package:sagawa_pos/shared/widgets/exit_confirmation_dialog.dart';
import 'package:sagawa_pos/shared/widgets/shimmer_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tablet_landscape_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _menuScrollController = ScrollController();
  StreamSubscription<int>? _menuSyncSubscription;
  List<String> _categories = ['Semua'];
  int _selectedCategory = 0;
  String _location = '';
  static const String _locationPrefsKey = 'user_location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocation();
    _loadProducts();
    _loadCategories();
    MenuSyncWebSocketService.instance.connect();
    _menuSyncSubscription = MenuSyncWebSocketService.instance.onMenuChanged
        .listen((_) {
          if (!mounted) return;
          _loadProducts();
          _loadCategories();
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _menuSyncSubscription?.cancel();
    _searchController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      MenuSyncWebSocketService.instance.connect();
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    context.read<HomeCubit>().loadMockProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;

          if (_selectedCategory >= _categories.length) {
            _selectedCategory = 0;
          }
        });
      }
      print('DEBUG HomePage: Loaded categories: $_categories');
    } catch (e) {
      print('DEBUG HomePage: Error loading categories: $e');
    }
  }

  List<String> _buildCategoriesWithBestSeller(List<Product> products) {
    final hasBestSeller = products.any((p) => p.isBestSeller);

    if (!hasBestSeller) {
      return _categories;
    }

    final result = List<String>.from(_categories);
    if (!result.contains('Best Seller')) {
      if (result.isNotEmpty && result[0].toLowerCase() == 'semua') {
        result.insert(1, 'Best Seller');
      } else {
        result.insert(0, 'Best Seller');
      }
    }
    return result;
  }

  Future<void> _onRefresh() async {
    await Future.wait([_loadProducts(), _loadCategories()]);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();

    String location = prefs.getString(_locationPrefsKey) ?? '';

    if (location.isEmpty) {
      location = prefs.getString('printer_outletAddress') ?? '';

      if (location.isNotEmpty && location != 'Jl. Example No. 123, Jakarta') {
        await prefs.setString(_locationPrefsKey, location);
      }
    }

    setState(() {
      _location = location;
    });

    if (location.isEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog();
      });
    }
  }

  Future<void> _showLocationDialog() async {
    final result = await showLocationDialog(
      context,
      currentLocation: _location.isNotEmpty ? _location : null,
    );
    if (result != null) {
      await _saveLocation(result);
    }
  }

  Future<void> _saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_locationPrefsKey, location);

    await prefs.setString('printer_outletAddress', location);

    setState(() {
      _location = location;
    });

    if (!mounted) return;
    CustomSnackbar.show(
      context,
      message: 'Lokasi berhasil disimpan',
      type: SnackbarType.success,
    );
  }

  void _addToCart(Product product) {
    final success = context.read<HomeCubit>().addToCart(product);

    if (!success) {
      CustomSnackbar.show(
        context,
        message: 'Stok ${product.title} tidak mencukupi',
        type: SnackbarType.warning,
      );
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SearchDialog(
        onProductTap: (product) {
          Navigator.pop(context);
          _addToCart(product);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape = ResponsiveHelper.isTabletLandscape(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: AppDrawer(
          onMenuManagementClosed: () {
            print(
              'DEBUG HomePage: Menu management closed, reloading products...',
            );
            context.read<HomeCubit>().loadMockProducts();
          },
        ),
        body: Builder(
          builder: (scaffoldContext) {
            if (isTabletLandscape) {
              return _TabletLandscapeLayout(
                onMenuTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                onSearchTap: _showSearchDialog,
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (index) {
                  setState(() => _selectedCategory = index);
                },
                menuScrollController: _menuScrollController,
                onRefresh: _onRefresh,
                onAddToCart: _addToCart,
                buildCategoriesWithBestSeller: _buildCategoriesWithBestSeller,
                normalizeCategory: _normalizeCategory,
              );
            }

            return SafeArea(
              top: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      HomeAppBarCard(
                        onMenuTap: () {
                          Scaffold.of(scaffoldContext).openDrawer();
                        },
                        onSearchTap: _showSearchDialog,
                      ),
                      Expanded(
                        child: BlocBuilder<HomeCubit, HomeState>(
                          buildWhen: (previous, current) {
                            return previous.isLoading != current.isLoading ||
                                previous.products != current.products ||
                                previous.originalStocks !=
                                    current.originalStocks;
                          },
                          builder: (context, state) {
                            final allProducts = state.sortedProducts;
                            final displayCategories =
                                _buildCategoriesWithBestSeller(allProducts);

                            final safeSelectedIndex =
                                _selectedCategory < displayCategories.length
                                ? _selectedCategory
                                : 0;

                            final selectedCategoryName =
                                displayCategories.isNotEmpty
                                ? displayCategories[safeSelectedIndex]
                                : 'Semua';

                            if (state.isLoading) {
                              return Column(
                                children: [
                                  HomeCategoryCard(
                                    categories: displayCategories,
                                    selectedIndex: safeSelectedIndex,
                                    onSelected: (index) {
                                      setState(() => _selectedCategory = index);
                                    },
                                  ),
                                  const Expanded(child: _MenuGridSkeleton()),
                                ],
                              );
                            }

                            if (state.isEmptyProducts) {
                              return Column(
                                children: [
                                  HomeCategoryCard(
                                    categories: displayCategories,
                                    selectedIndex: safeSelectedIndex,
                                    onSelected: (index) {
                                      setState(() => _selectedCategory = index);
                                    },
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Lottie.asset(
                                            'assets/animations/no_data.json',
                                            width: 180,
                                            height: 180,
                                            repeat: false,
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'Menu belum tersedia',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Silakan tambahkan item terlebih dahulu.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            List<Product> products;
                            if (selectedCategoryName == 'Semua') {
                              products = allProducts;
                            } else if (selectedCategoryName == 'Best Seller') {
                              products = allProducts
                                  .where((p) => p.isBestSeller)
                                  .toList();
                            } else {
                              products = allProducts
                                  .where(
                                    (p) =>
                                        _normalizeCategory(p.kategori) ==
                                        _normalizeCategory(
                                          selectedCategoryName,
                                        ),
                                  )
                                  .toList();
                            }

                            if (products.isEmpty && allProducts.isNotEmpty) {
                              return Column(
                                children: [
                                  HomeCategoryCard(
                                    categories: displayCategories,
                                    selectedIndex: safeSelectedIndex,
                                    onSelected: (index) {
                                      setState(() => _selectedCategory = index);
                                    },
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Lottie.asset(
                                            'assets/animations/no_data.json',
                                            width: 150,
                                            height: 150,
                                            repeat: false,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tidak ada menu di kategori "$selectedCategoryName"',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Coba pilih kategori lain',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                HomeCategoryCard(
                                  categories: displayCategories,
                                  selectedIndex: safeSelectedIndex,
                                  onSelected: (index) {
                                    setState(() => _selectedCategory = index);
                                  },
                                ),
                                Expanded(
                                  child: RawScrollbar(
                                    controller: _menuScrollController,
                                    thumbVisibility: false,
                                    radius: const Radius.circular(4),
                                    thickness: 4,
                                    thumbColor: Colors.grey.withValues(
                                      alpha: 0.5,
                                    ),
                                    fadeDuration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    timeToFade: const Duration(
                                      milliseconds: 800,
                                    ),
                                    child: RefreshIndicator(
                                      color: const Color(0xFFFF4B4B),
                                      onRefresh: _onRefresh,
                                      child: GridView.builder(
                                        key: const ValueKey('menu_grid'),
                                        controller: _menuScrollController,
                                        padding: EdgeInsets.fromLTRB(
                                          _getResponsivePadding(context),
                                          _getResponsivePadding(context),
                                          _getResponsivePadding(context),
                                          140,
                                        ),
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics(),
                                            ),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  _getGridCrossAxisCount(
                                                    context,
                                                  ),
                                              crossAxisSpacing:
                                                  ResponsiveHelper.getSpacing(
                                                    context,
                                                    mobile: 12,
                                                    tablet: 16,
                                                    desktop: 20,
                                                  ),
                                              mainAxisSpacing:
                                                  ResponsiveHelper.getSpacing(
                                                    context,
                                                    mobile: 12,
                                                    tablet: 16,
                                                    desktop: 20,
                                                  ),
                                              childAspectRatio:
                                                  _calculateAspectRatio(
                                                    context,
                                                  ),
                                            ),
                                        itemCount: products.length,
                                        itemBuilder: (context, index) {
                                          final product = products[index];
                                          return _ProductCard(
                                            key: ValueKey(product.id),
                                            product: product,
                                            onAdd: () => _addToCart(product),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) {
                        if (state.cartCount == 0)
                          return const SizedBox.shrink();
                        return _CartSummaryCard(
                          itemCount: state.cartCount,
                          totalPrice: state.cartTotalLabel,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _calculateAspectRatio(BuildContext context) {
    return ResponsiveHelper.getProductCardAspectRatio(context);
  }

  int _getGridCrossAxisCount(BuildContext context) {
    return ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobileCrossAxisCount: 2,
      tabletPortraitCrossAxisCount: 3,
      tabletLandscapeCrossAxisCount: 5,
      desktopCrossAxisCount: 6,
    );
  }

  double _getResponsivePadding(BuildContext context) {
    return ResponsiveHelper.getPadding(context);
  }

  String _normalizeCategory(String category) {
    return category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF1F2F4),
      child: Icon(Icons.restaurant_rounded, size: 46, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveHelper.isTabletLandscape(context);
    final borderRadius = isCompact ? 16.0 : 22.0;
    final cardPadding = isCompact ? 10.0 : 14.0;
    final titleFontSize = isCompact ? 12.0 : 14.0;
    final priceFontSize = isCompact ? 12.0 : 14.0;
    final stockFontSize = isCompact ? 10.0 : 11.0;
    final addButtonSize = isCompact ? 28.0 : 36.0;
    final addIconSize = isCompact ? 18.0 : 22.0;

    return GestureDetector(
      onTap: product.stock > 0 ? onAdd : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: isCompact ? 10 : 18,
              offset: Offset(0, isCompact ? 5 : 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius),
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final img = product.imageAsset.trim();
                        if (img.isEmpty) {
                          return _buildImagePlaceholder();
                        }

                        if (img.startsWith('http') || img.startsWith('https')) {
                          return Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          );
                        }

                        if (img.startsWith('data:')) {
                          try {
                            final comma = img.indexOf(',');
                            if (comma < 0) {
                              return _buildImagePlaceholder();
                            }
                            final base64Part = img.substring(comma + 1);
                            final bytes = base64Decode(base64Part);
                            return Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(),
                            );
                          } catch (_) {
                            return _buildImagePlaceholder();
                          }
                        }

                        return Image.asset(
                          img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
                        );
                      },
                    ),
                  ),

                  if (product.stock == 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(borderRadius),
                          ),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 16 : 24,
                                vertical: isCompact ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4B4B),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 14 : 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: titleFontSize,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.priceLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: priceFontSize,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: isCompact ? 2 : 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: isCompact ? 10 : 12,
                                  color: product.stock > 0
                                      ? Colors.grey.shade600
                                      : Colors.red.shade400,
                                ),
                                SizedBox(width: isCompact ? 2 : 4),
                                Text(
                                  'Stok: ${product.stock}',
                                  style: TextStyle(
                                    fontSize: stockFontSize,
                                    color: product.stock > 0
                                        ? Colors.grey.shade600
                                        : Colors.red.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        height: addButtonSize,
                        width: addButtonSize,
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? const Color(0xFFFFB000)
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isCompact ? 8 : 12),
                            bottomRight: Radius.circular(isCompact ? 8 : 12),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: addIconSize,
                          color: product.stock > 0
                              ? Colors.white
                              : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({required this.itemCount, required this.totalPrice});

  final int itemCount;
  final String totalPrice;

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveHelper.isTabletLandscape(context);
    final horizontalPadding = isCompact ? 14.0 : 20.0;
    final verticalPadding = isCompact ? 10.0 : 16.0;
    final itemFontSize = isCompact ? 16.0 : 20.0;
    final priceFontSize = isCompact ? 16.0 : 20.0;
    final subTextFontSize = isCompact ? 11.0 : 14.0;
    final iconSize = isCompact ? 24.0 : 30.0;
    final containerSize = isCompact ? 34.0 : 44.0;

    return GestureDetector(
      onTap: () {
        final cubit = context.read<HomeCubit>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const OrderDetailPage(),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isCompact ? 28 : 40),
          border: Border.all(color: const Color(0x1A000000), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0x26000000),
              blurRadius: isCompact ? 12 : 18,
              offset: Offset(0, isCompact ? 8 : 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$itemCount Item',
                    style: TextStyle(
                      color: const Color(0xFFFF4B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: itemFontSize,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    'Ketuk untuk melihat',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: subTextFontSize,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              totalPrice,
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
                fontSize: priceFontSize,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            SizedBox(
              width: containerSize,
              height: containerSize,
              child: Center(
                child: Image.asset(
                  'assets/icons/bag.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final Function(Product) onProductTap;

  const _SearchDialog({required this.onProductTap});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4B4B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari menu...',
                          hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                          icon: Icon(Icons.search, color: Color(0xFF444444)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  final allProducts = state.sortedProducts;
                  final results = _searchQuery.isEmpty
                      ? allProducts
                      : allProducts
                            .where(
                              (p) => p.title.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Menu tidak ditemukan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final product = results[index];
                      return _SearchResultItem(
                        product: product,
                        onTap: () => widget.onProductTap(product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _SearchResultItem({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSoldOut = product.stock == 0;

    return InkWell(
      onTap: isSoldOut ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSoldOut ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.priceLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSoldOut
                              ? Colors.grey
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: isSoldOut ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSoldOut ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSoldOut)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'HABIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _MenuGridSkeleton extends StatelessWidget {
  const _MenuGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: _calculateAspectRatio(context),
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const _MenuCardSkeleton(),
      ),
    );
  }

  double _calculateAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) return 0.85;
    if (width >= 400) return 0.80;
    return 0.75;
  }
}

class _MenuCardSkeleton extends StatelessWidget {
  const _MenuCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 50,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
