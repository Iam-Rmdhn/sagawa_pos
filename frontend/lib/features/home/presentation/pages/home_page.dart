import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';

import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/utils/indonesia_time.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/data/services/category_service.dart';
import 'package:sagawa_pos_new/data/services/settings_service.dart';
import 'package:sagawa_pos_new/data/services/transaction_service.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:sagawa_pos_new/features/home/presentation/widgets/home_app_bar.dart';
import 'package:sagawa_pos_new/features/home/presentation/widgets/home_category_card.dart';
import 'package:sagawa_pos_new/features/order/presentation/pages/order_detail_page.dart';
import 'package:sagawa_pos_new/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/features/receipt/receipt.dart';
import 'package:sagawa_pos_new/features/settings/presentation/widgets/location_dialog.dart';
import 'package:sagawa_pos_new/shared/widgets/app_drawer.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _menuScrollController = ScrollController();
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
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
          // Reset selection if current index is out of bounds
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

  // Build categories list with Best Seller inserted after "Semua" if there are best seller products
  List<String> _buildCategoriesWithBestSeller(List<Product> products) {
    final hasBestSeller = products.any((p) => p.isBestSeller);

    if (!hasBestSeller) {
      return _categories;
    }

    // Insert "Best Seller" after "Semua" (index 0)
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
    final location = prefs.getString(_locationPrefsKey) ?? '';
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

    return Scaffold(
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
          // Use split layout for tablet landscape
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

          // Default mobile/tablet portrait layout
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
                              previous.originalStocks != current.originalStocks;
                        },
                        builder: (context, state) {
                          // Build categories with Best Seller dynamically
                          final allProducts = state.sortedProducts;
                          final displayCategories =
                              _buildCategoriesWithBestSeller(allProducts);

                          // Adjust selected index if categories changed
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

                          // Filter products based on selected category
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
                                      _normalizeCategory(selectedCategoryName),
                                )
                                .toList();
                          }

                          // Show empty state if no products match the category filter
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
                                  timeToFade: const Duration(milliseconds: 800),
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
                                                _getGridCrossAxisCount(context),
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
                                                _calculateAspectRatio(context),
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
                      if (state.cartCount == 0) return const SizedBox.shrink();
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
    );
  }

  double _calculateAspectRatio(BuildContext context) {
    // Use responsive helper for aspect ratio
    return ResponsiveHelper.getProductCardAspectRatio(context);
  }

  /// Get responsive grid cross axis count
  int _getGridCrossAxisCount(BuildContext context) {
    return ResponsiveHelper.getGridCrossAxisCount(
      context,
      mobileCrossAxisCount: 2,
      tabletPortraitCrossAxisCount: 3,
      tabletLandscapeCrossAxisCount: 5, // More columns for compact view
      desktopCrossAxisCount: 6,
    );
  }

  /// Get responsive padding
  double _getResponsivePadding(BuildContext context) {
    return ResponsiveHelper.getPadding(context);
  }

  /// Normalize category string for comparison
  String _normalizeCategory(String category) {
    return category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({super.key, required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

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
                        final img = product.imageAsset;
                        if (img.startsWith('http') || img.startsWith('https')) {
                          return Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Image.asset(
                              AppImages.onboardingIllustration,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        }

                        if (img.startsWith('data:')) {
                          try {
                            final comma = img.indexOf(',');
                            final base64Part = img.substring(comma + 1);
                            final bytes = base64Decode(base64Part);
                            return Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Image.asset(
                                AppImages.onboardingIllustration,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            );
                          } catch (_) {
                            return Image.asset(
                              AppImages.onboardingIllustration,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          }
                        }

                        return Image.asset(
                          img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  // Sold Out Banner
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
                      // Add indicator icon
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

// Search Dialog Widget
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
            // Header with search field
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
            // Search Results
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  // Use sortedProducts for consistent ordering
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

// ============================================================================
// TABLET LANDSCAPE LAYOUT - 60% Menu | 40% Cart & Payment
// ============================================================================

class _TabletLandscapeLayout extends StatefulWidget {
  const _TabletLandscapeLayout({
    required this.onMenuTap,
    required this.onSearchTap,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.menuScrollController,
    required this.onRefresh,
    required this.onAddToCart,
    required this.buildCategoriesWithBestSeller,
    required this.normalizeCategory,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final List<String> categories;
  final int selectedCategory;
  final ValueChanged<int> onCategorySelected;
  final ScrollController menuScrollController;
  final Future<void> Function() onRefresh;
  final void Function(Product) onAddToCart;
  final List<String> Function(List<Product>) buildCategoriesWithBestSeller;
  final String Function(String) normalizeCategory;

  @override
  State<_TabletLandscapeLayout> createState() => _TabletLandscapeLayoutState();
}

class _TabletLandscapeLayoutState extends State<_TabletLandscapeLayout> {
  final _cashierController = TextEditingController();
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  final _cashController = TextEditingController();
  final _cartScrollController = ScrollController();

  int _selectedOrderType = 0;
  int _selectedPaymentMethod = -1;
  int _cashAmount = 0;
  bool _isTaxEnabled = false;
  bool _cashierError = false;
  bool _customerError = false;

  // Receipt states
  Receipt? _currentReceipt;
  ReceiptCubit? _receiptCubit;
  bool _isProcessingPayment = false;
  bool _isPrinted = false;

  @override
  void initState() {
    super.initState();
    _loadTaxSetting();
    _receiptCubit = ReceiptCubit();
  }

  Future<void> _loadTaxSetting() async {
    final taxEnabled = await SettingsService.isTaxEnabled();
    if (mounted) setState(() => _isTaxEnabled = taxEnabled);
  }

  @override
  void dispose() {
    _cashierController.dispose();
    _customerController.dispose();
    _notesController.dispose();
    _cashController.dispose();
    _cartScrollController.dispose();
    _receiptCubit?.close();
    super.dispose();
  }

  Map<Product, int> _groupCartItems(List<Product> cart) {
    final Map<Product, int> grouped = {};
    for (final product in cart) {
      bool found = false;
      for (final existingProduct in grouped.keys) {
        if (existingProduct.id == product.id) {
          grouped[existingProduct] = grouped[existingProduct]! + 1;
          found = true;
          break;
        }
      }
      if (!found) grouped[product] = 1;
    }
    return grouped;
  }

  String _formatCurrency(int value) {
    final s = value.toString();
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  String _formatCurrencyInput(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  void _processPayment(int subtotal, List<Product> cartItems) async {
    setState(() {
      _cashierError = _cashierController.text.trim().isEmpty;
      _customerError = _customerController.text.trim().isEmpty;
    });

    if (_cashierError || _customerError) {
      CustomSnackbar.show(
        context,
        message: 'Mohon isi nama Kasir dan Pelanggan',
        type: SnackbarType.warning,
      );
      return;
    }

    if (_selectedPaymentMethod == -1) {
      CustomSnackbar.show(
        context,
        message: 'Pilih metode pembayaran',
        type: SnackbarType.warning,
      );
      return;
    }

    final taxAmount = _isTaxEnabled ? (subtotal * 0.1).round() : 0;
    final total = subtotal + taxAmount;

    if (_selectedPaymentMethod == 1 && _cashAmount < total) {
      CustomSnackbar.show(
        context,
        message: 'Nominal cash kurang! Minimal ${_formatCurrency(total)}',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final user = await UserService.getUser();
      final orderType = _selectedOrderType == 0 ? 'Dine In' : 'Take Away';
      final paymentMethod = _selectedPaymentMethod == 0 ? 'QRIS' : 'Cash';
      final cashAmount = _selectedPaymentMethod == 0
          ? total.toDouble()
          : _cashAmount.toDouble();

      final tax = _isTaxEnabled ? subtotal * 0.1 : 0.0;
      final afterTax = subtotal + tax;
      final change = cashAmount - afterTax;

      // Group cart items by product
      final groupedCart = _groupCartItems(cartItems);
      final receiptItems = groupedCart.entries.map((entry) {
        final product = entry.key;
        final quantity = entry.value;
        return ReceiptItem(
          name: product.title,
          quantity: quantity,
          price: product.price.toDouble(),
          subtotal: (product.price * quantity).toDouble(),
        );
      }).toList();

      final trxId = PaymentSuccessExample.generateTrxId();

      final receipt = Receipt(
        storeName: user?.kemitraan ?? 'Warung Mas Gaw Nusantara',
        address:
            user?.outlet ??
            'Jl. Mampang Prapatan XI No.3A 7, RT.7/RW.1, Tegal Parang, Kec. Mampang Prpt., Kota Jakarta Selatan',
        type: orderType,
        trxId: trxId,
        cashier: _cashierController.text.trim(),
        customerName: _customerController.text.trim(),
        items: receiptItems,
        subTotal: subtotal.toDouble(),
        tax: tax,
        afterTax: afterTax,
        cash: cashAmount,
        change: change,
        date: IndonesiaTime.now(),
        logoPath: 'assets/logo/logo_pos.png',
        paymentMethod: paymentMethod,
      );

      // Save transaction to backend database
      try {
        final transactionService = TransactionService();
        final transactionItems = groupedCart.entries.map((entry) {
          final product = entry.key;
          final quantity = entry.value;
          return TransactionItemData(
            menuName: product.title,
            qty: quantity,
            price: product.price.toDouble(),
            subtotal: (product.price * quantity).toDouble(),
          );
        }).toList();

        final transactionData = TransactionData(
          trxId: trxId,
          outletId: user?.id ?? '',
          outletName: user?.outlet ?? '',
          items: transactionItems,
          cashier: _cashierController.text.trim(),
          customer: _customerController.text.trim(),
          note: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          type: orderType == 'Dine In' ? 'dine_in' : 'take_away',
          method: paymentMethod.toLowerCase(),
          nominal: paymentMethod == 'Cash' ? cashAmount : 0,
          subtotal: subtotal.toDouble(),
          tax: tax,
          total: afterTax,
          qris: paymentMethod == 'QRIS' ? afterTax : 0,
          changes: paymentMethod == 'Cash' ? change : 0,
        );

        await transactionService.saveTransaction(transactionData);
      } catch (e) {
        print('ERROR: Failed to save transaction to backend: $e');
      }

      // Save to order history (local)
      try {
        final orderHistory = OrderHistory(
          id: PaymentSuccessExample.generateTrxId(),
          trxId: receipt.trxId,
          outletId: user?.id ?? '',
          outletName: user?.outlet ?? '',
          date: receipt.date,
          totalAmount: receipt.afterTax,
          status: 'completed',
          receipt: receipt,
        );

        final repository = OrderHistoryRepository();
        await repository.saveOrder(orderHistory);
      } catch (e) {
        print('ERROR: Failed to save order to history: $e');
      }

      // Clear cart
      if (mounted) {
        context.read<HomeCubit>().clearCart();
      }

      // Show receipt in cart area
      if (mounted) {
        setState(() {
          _currentReceipt = receipt;
          _isProcessingPayment = false;
          _isPrinted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        CustomSnackbar.show(
          context,
          message: 'Gagal memproses pembayaran: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  void _resetToNewOrder() {
    setState(() {
      _cashierController.clear();
      _customerController.clear();
      _notesController.clear();
      _cashController.clear();
      _selectedOrderType = 0;
      _selectedPaymentMethod = -1;
      _cashAmount = 0;
      _cashierError = false;
      _customerError = false;
      _currentReceipt = null;
      _isPrinted = false;
    });
  }

  Future<void> _printReceipt() async {
    if (_currentReceipt == null || _receiptCubit == null) return;

    // Ensure receipt is generated first
    if (_receiptCubit!.state is! ReceiptGenerated) {
      await _receiptCubit!.generateReceipt(_currentReceipt!);
    }

    await _receiptCubit!.printViaBluetooth();
    if (mounted) {
      setState(() => _isPrinted = true);
    }
  }

  Future<void> _downloadReceipt() async {
    if (_currentReceipt == null || _receiptCubit == null) return;

    // Ensure receipt is generated first
    if (_receiptCubit!.state is! ReceiptGenerated) {
      await _receiptCubit!.generateReceipt(_currentReceipt!);
    }

    await _receiptCubit!.downloadPdf();
  }

  Widget _buildReceiptView() {
    return BlocListener<ReceiptCubit, ReceiptState>(
      bloc: _receiptCubit,
      listener: (context, state) {
        if (state is ReceiptPrinted) {
          CustomSnackbar.show(
            context,
            message: 'Struk berhasil dicetak',
            type: SnackbarType.success,
          );
        } else if (state is ReceiptDownloaded) {
          CustomSnackbar.show(
            context,
            message: 'Struk berhasil diunduh',
            type: SnackbarType.success,
          );
        } else if (state is ReceiptError) {
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'Pembayaran Berhasil!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TRX: ${_currentReceipt!.trxId}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Receipt Preview
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ReceiptPreview(
                  receipt: _currentReceipt!,
                  isBottomSheet: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<ReceiptCubit, ReceiptState>(
                    bloc: _receiptCubit,
                    builder: (context, state) {
                      final isLoading = state is ReceiptPrinting;
                      return ElevatedButton.icon(
                        onPressed: isLoading ? null : _printReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isPrinted ? Icons.print_disabled : Icons.print,
                                color: Colors.white,
                                size: 18,
                              ),
                        label: Text(
                          isLoading
                              ? 'Mencetak...'
                              : (_isPrinted ? 'Cetak Ulang' : 'Cetak Struk'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BlocBuilder<ReceiptCubit, ReceiptState>(
                    bloc: _receiptCubit,
                    builder: (context, state) {
                      final isLoading = state is ReceiptDownloading;
                      return ElevatedButton.icon(
                        onPressed: isLoading ? null : _downloadReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 18,
                              ),
                        label: Text(
                          isLoading ? 'Mengunduh...' : 'Download PDF',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // New Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetToNewOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Order Baru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SafeArea(
      top: false,
      child: Row(
        children: [
          // LEFT SIDE - MENU (60%)
          Expanded(
            flex: 60,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: topPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onMenuTap,
                          icon: const Icon(
                            Icons.menu,
                            size: 22,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onSearchTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 18,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cari menu lainnya',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<HomeCubit, HomeState>(
                    buildWhen: (previous, current) =>
                        previous.isLoading != current.isLoading ||
                        previous.products != current.products ||
                        previous.originalStocks != current.originalStocks,
                    builder: (context, state) {
                      final allProducts = state.sortedProducts;
                      final displayCategories = widget
                          .buildCategoriesWithBestSeller(allProducts);
                      final safeSelectedIndex =
                          widget.selectedCategory < displayCategories.length
                          ? widget.selectedCategory
                          : 0;
                      final selectedCategoryName = displayCategories.isNotEmpty
                          ? displayCategories[safeSelectedIndex]
                          : 'Semua';

                      if (state.isLoading) {
                        return Column(
                          children: [
                            HomeCategoryCard(
                              categories: displayCategories,
                              selectedIndex: safeSelectedIndex,
                              onSelected: widget.onCategorySelected,
                            ),
                            const Expanded(child: _MenuGridSkeleton()),
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
                                  widget.normalizeCategory(p.kategori) ==
                                  widget.normalizeCategory(
                                    selectedCategoryName,
                                  ),
                            )
                            .toList();
                      }

                      return Column(
                        children: [
                          HomeCategoryCard(
                            categories: displayCategories,
                            selectedIndex: safeSelectedIndex,
                            onSelected: widget.onCategorySelected,
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: const Color(0xFFFF4B4B),
                              onRefresh: widget.onRefresh,
                              child: products.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Lottie.asset(
                                            'assets/animations/no_data.json',
                                            width: 120,
                                            height: 120,
                                            repeat: false,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Tidak ada menu',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GridView.builder(
                                      controller: widget.menuScrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        8,
                                        12,
                                        12,
                                      ),
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics(),
                                          ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 0.78,
                                          ),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) =>
                                          _ProductCard(
                                            key: ValueKey(products[index].id),
                                            product: products[index],
                                            onAdd: () => widget.onAddToCart(
                                              products[index],
                                            ),
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
          ),
          Container(width: 1, color: Colors.grey.shade300),
          // RIGHT SIDE - CART & PAYMENT (40%)
          Expanded(
            flex: 40,
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: topPadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            _currentReceipt != null
                                ? Icons.receipt_long
                                : Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _currentReceipt != null ? 'Struk' : 'Keranjang',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (_currentReceipt == null)
                            BlocBuilder<HomeCubit, HomeState>(
                              builder: (context, state) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${state.cartCount} item',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF4B4B),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _currentReceipt != null
                        ? _buildReceiptView()
                        : BlocBuilder<HomeCubit, HomeState>(
                            builder: (context, state) {
                              if (state.cart.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/empty_cart.json',
                                        width: 140,
                                        height: 140,
                                        repeat: false,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Keranjang kosong',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Pilih menu untuk memulai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final cartItems = _groupCartItems(state.cart);
                              final subtotal = state.cartTotal;
                              final taxAmount = _isTaxEnabled
                                  ? (subtotal * 0.1).round()
                                  : 0;
                              final total = subtotal + taxAmount;
                              final changes = _selectedPaymentMethod == 1
                                  ? _cashAmount - total
                                  : 0;

                              return SingleChildScrollView(
                                controller: _cartScrollController,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cart Items
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: cartItems.entries.map((
                                          entry,
                                        ) {
                                          final product = entry.key;
                                          final quantity = entry.value;
                                          final isLast =
                                              entry.key == cartItems.keys.last;
                                          return Column(
                                            children: [
                                              _CompactCartItem(
                                                product: product,
                                                quantity: quantity,
                                                onIncrement: () {
                                                  final success = context
                                                      .read<HomeCubit>()
                                                      .addToCart(product);
                                                  if (!success)
                                                    CustomSnackbar.show(
                                                      context,
                                                      message:
                                                          'Stok ${product.title} tidak mencukupi',
                                                      type:
                                                          SnackbarType.warning,
                                                    );
                                                },
                                                onDecrement: () => context
                                                    .read<HomeCubit>()
                                                    .removeFromCart(product.id),
                                                onDelete: () => context
                                                    .read<HomeCubit>()
                                                    .removeAllFromCart(
                                                      product.id,
                                                    ),
                                              ),
                                              if (!isLast)
                                                Divider(
                                                  height: 1,
                                                  color: Colors.grey.shade200,
                                                ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Kasir & Pelanggan
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _CompactInputField(
                                            controller: _cashierController,
                                            label: 'Kasir',
                                            hasError: _cashierError,
                                            onChanged: (_) {
                                              if (_cashierError)
                                                setState(
                                                  () => _cashierError = false,
                                                );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _CompactInputField(
                                            controller: _customerController,
                                            label: 'Pelanggan',
                                            hasError: _customerError,
                                            onChanged: (_) {
                                              if (_customerError)
                                                setState(
                                                  () => _customerError = false,
                                                );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _CompactInputField(
                                      controller: _notesController,
                                      label: 'Catatan (opsional)',
                                    ),
                                    const SizedBox(height: 12),
                                    // Order Type
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _CompactOrderTypeChip(
                                            label: 'Dine In',
                                            icon: Icons.restaurant,
                                            isSelected: _selectedOrderType == 0,
                                            onTap: () => setState(
                                              () => _selectedOrderType = 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _CompactOrderTypeChip(
                                            label: 'Take Away',
                                            icon: Icons.shopping_bag_outlined,
                                            isSelected: _selectedOrderType == 1,
                                            onTap: () => setState(
                                              () => _selectedOrderType = 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Payment Method
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _CompactPaymentChip(
                                            label: 'QRIS',
                                            icon: Icons.qr_code,
                                            isSelected:
                                                _selectedPaymentMethod == 0,
                                            onTap: () => setState(
                                              () => _selectedPaymentMethod = 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _CompactPaymentChip(
                                            label: 'Cash',
                                            icon: Icons.payments_outlined,
                                            isSelected:
                                                _selectedPaymentMethod == 1,
                                            onTap: () => setState(
                                              () => _selectedPaymentMethod = 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Cash Input
                                    if (_selectedPaymentMethod == 1) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.payments,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _cashController,
                                                keyboardType:
                                                    TextInputType.number,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      hintText: 'Nominal Cash',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                onChanged: (value) {
                                                  final numericValue = value
                                                      .replaceAll(
                                                        RegExp(r'[^0-9]'),
                                                        '',
                                                      );
                                                  if (numericValue.isEmpty) {
                                                    setState(() {
                                                      _cashAmount = 0;
                                                      _cashController.clear();
                                                    });
                                                    return;
                                                  }
                                                  final amount = int.parse(
                                                    numericValue,
                                                  );
                                                  final formatted =
                                                      _formatCurrencyInput(
                                                        amount,
                                                      );
                                                  _cashController
                                                      .value = TextEditingValue(
                                                    text: formatted,
                                                    selection:
                                                        TextSelection.collapsed(
                                                          offset:
                                                              formatted.length,
                                                        ),
                                                  );
                                                  setState(
                                                    () => _cashAmount = amount,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // Summary
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          _SummaryRow(
                                            label: 'Subtotal',
                                            value: _formatCurrency(subtotal),
                                          ),
                                          if (_isTaxEnabled) ...[
                                            const SizedBox(height: 4),
                                            _SummaryRow(
                                              label: 'PB1 (10%)',
                                              value: _formatCurrency(taxAmount),
                                            ),
                                          ],
                                          if (_selectedPaymentMethod == 1 &&
                                              _cashAmount > 0) ...[
                                            const SizedBox(height: 4),
                                            _SummaryRow(
                                              label: 'Cash',
                                              value: _formatCurrency(
                                                _cashAmount,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            _SummaryRow(
                                              label: 'Kembalian',
                                              value: _formatCurrency(
                                                changes > 0 ? changes : 0,
                                              ),
                                              valueColor: Colors.orange,
                                            ),
                                          ],
                                          const Divider(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                _formatCurrency(total),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF4CAF50),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Process Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            (_selectedPaymentMethod == -1 ||
                                                _isProcessingPayment)
                                            ? null
                                            : () => _processPayment(
                                                subtotal,
                                                state.cart,
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFF4B4B,
                                          ),
                                          disabledBackgroundColor:
                                              Colors.grey.shade400,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: _isProcessingPayment
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.receipt_long,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                        label: Text(
                                          _isProcessingPayment
                                              ? 'Memproses...'
                                              : 'Proses & Cetak Struk',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// COMPACT WIDGETS FOR TABLET LAYOUT

class _CompactCartItem extends StatelessWidget {
  const _CompactCartItem({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });
  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.priceLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniButton(icon: Icons.remove, onTap: onDecrement),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _MiniButton(icon: Icons.add, onTap: onIncrement),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFFFFB74D),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 12),
      ),
    );
  }
}

class _CompactInputField extends StatelessWidget {
  const _CompactInputField({
    required this.controller,
    required this.label,
    this.hasError = false,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? Colors.red : Colors.grey.shade300,
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            color: hasError ? Colors.red : Colors.grey.shade600,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _CompactOrderTypeChip extends StatelessWidget {
  const _CompactOrderTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4B4B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPaymentChip extends StatelessWidget {
  const _CompactPaymentChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
