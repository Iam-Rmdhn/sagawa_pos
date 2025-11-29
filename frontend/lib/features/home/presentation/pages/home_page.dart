import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';

import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:sagawa_pos_new/features/home/presentation/widgets/home_app_bar.dart';
import 'package:sagawa_pos_new/features/home/presentation/widgets/home_category_card.dart';
import 'package:sagawa_pos_new/features/order/presentation/pages/order_detail_page.dart';
import 'package:sagawa_pos_new/features/settings/presentation/widgets/location_dialog.dart';
import 'package:sagawa_pos_new/shared/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final List<String> _categories = const [
    'Semua',
    'Best Seller',
    'Ala Carte',
    'Coffee',
    'Non Coffee',
  ];
  int _selectedCategory = 0;
  String _location = '';
  static const String _locationPrefsKey = 'user_location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocation();
    _loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload products when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    context.read<HomeCubit>().loadMockProducts();
  }

  Future<void> _onRefresh() async {
    await _loadProducts();
    // Wait a bit for smooth animation
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString(_locationPrefsKey) ?? '';
    setState(() {
      _location = location;
    });

    // Show location dialog if empty
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
    context.read<HomeCubit>().addToCart(product);
    CustomSnackbar.show(
      context,
      message: '${product.title} ditambahkan ke keranjang',
      type: SnackbarType.success,
    );
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      drawer: AppDrawer(
        onMenuManagementClosed: () {
          print(
            'DEBUG HomePage: Menu management closed, reloading products...',
          );
          // Reload products when returning from menu management
          context.read<HomeCubit>().loadMockProducts();
        },
      ),
      body: Builder(
        builder: (scaffoldContext) {
          return SafeArea(
            top: false,
            child: Stack(
              children: [
                Container(color: Colors.white),
                Column(
                  children: [
                    // Fixed AppBar
                    HomeAppBarCard(
                      locationLabel: _location.isEmpty
                          ? 'Tambahkan lokasi'
                          : _location,
                      onMenuTap: () {
                        Scaffold.of(scaffoldContext).openDrawer();
                      },
                      onFilterTap: () {},
                      onLocationTap: _showLocationDialog,
                      onSearchTap: _showSearchDialog,
                    ),
                    // Fixed Category
                    HomeCategoryCard(
                      categories: _categories,
                      selectedIndex: _selectedCategory,
                      onSelected: (index) {
                        setState(() => _selectedCategory = index);
                      },
                    ),
                    // Scrollable Menu Grid
                    Expanded(
                      child: BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          if (state.isEmptyProducts) {
                            return Center(
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
                            );
                          }
                          final products = state.products;
                          return RefreshIndicator(
                            color: const Color(0xFFFF4B4B),
                            onRefresh: _onRefresh,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                140,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: _calculateAspectRatio(
                                      context,
                                    ),
                                  ),
                              itemCount: products.length,
                              itemBuilder: (context, index) => _ProductCard(
                                product: products[index],
                                onAdd: () => _addToCart(products[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    if (state.cartCount == 0) return const SizedBox();
                    return Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _CartSummaryCard(
                        itemCount: state.cartCount,
                        totalPrice: state.cartTotalLabel,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Calculate responsive aspect ratio based on screen width
  double _calculateAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) {
      // Tablet or larger screens
      return 0.85;
    } else if (width >= 400) {
      // Large phones
      return 0.80;
    } else {
      // Small phones
      return 0.75;
    }
  }
}

// _ProductData removed; using Product model from domain layer.

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
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

                      // support data URL (base64) images
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
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
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
                            child: const Text(
                              'SOLD OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.priceLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 12,
                                color: product.stock > 0
                                    ? Colors.grey.shade600
                                    : Colors.red.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stok: ${product.stock}',
                                style: TextStyle(
                                  fontSize: 11,
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
                    GestureDetector(
                      onTap: product.stock > 0 ? onAdd : null,
                      child: Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? const Color(0xFFFFB000)
                              : Colors.grey.shade400,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: product.stock > 0
                              ? Colors.white
                              : Colors.grey.shade300,
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

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({required this.itemCount, required this.totalPrice});

  final int itemCount;
  final String totalPrice;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0x1A000000), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, 12),
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
                    style: const TextStyle(
                      color: Color(0xFFFF4B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ketuk untuk melihat',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              totalPrice,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Image.asset(
                  'assets/icons/bag.png',
                  width: 30,
                  height: 30,
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
                  final results = _searchQuery.isEmpty
                      ? state.products
                      : state.products
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

// Simple Search Result Item
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
