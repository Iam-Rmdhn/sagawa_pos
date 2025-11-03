import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as custom;
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/utils/app_image_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import 'manage_menu_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products using Bloc - use addPostFrameCallback to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(LoadProductsEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLogoWidget() {
    try {
      return SvgPicture.asset(
        AppImageAssets.logo,
        height: 80.h,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Container(
          height: 80.h,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      );
    } catch (e) {
      // Fallback jika SVG gagal load
      return Container(
        height: 80.h,
        alignment: Alignment.center,
        child: Text(
          'SAGAWA POS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header dengan logo - Background Primary Dark
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryDark),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: Center(child: _buildLogoWidget()),
          ),

          // Menu items
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.square_list,
                    title: 'Kelola Menu',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageMenuPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.person_crop_circle,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to profile page
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: CupertinoIcons.settings,
                    title: 'Pengaturan',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to settings page
                    },
                  ),
                ],
              ),
            ),
          ),

          // Logout button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(
                CupertinoIcons.square_arrow_right,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(CupertinoIcons.sidebar_left),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sagawa POS'),
            Text(
              'Point of Sale System',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
              BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  int itemCount = 0;
                  if (state is CartLoaded) {
                    itemCount = state.itemCount;
                  }

                  if (itemCount == 0) return const SizedBox.shrink();

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const LoadingWidget(message: 'Memuat produk...');
          }

          if (state is ProductError) {
            return custom.ErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<ProductBloc>().add(LoadProductsEvent());
              },
            );
          }

          if (state is! ProductLoaded) {
            return const EmptyWidget(
              message: 'Belum ada produk tersedia',
              icon: Icons.inventory_2_outlined,
            );
          }

          final productState = state;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(16.w),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductBloc>().add(
                                ClearSearchEvent(),
                              );
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    context.read<ProductBloc>().add(SearchProductsEvent(value));
                  },
                ),
              ),

              // Categories
              Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: productState.categories.length,
                  itemBuilder: (context, index) {
                    final category = productState.categories[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: CategoryChip(
                        label: category,
                        isSelected: category == productState.selectedCategory,
                        onTap: () {
                          context.read<ProductBloc>().add(
                            FilterProductsByCategoryEvent(category),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Products Grid
              Expanded(
                child: productState.filteredProducts.isEmpty
                    ? const EmptyWidget(
                        message: 'Tidak ada produk di kategori ini',
                        icon: Icons.inventory_2_outlined,
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 16.h,
                        ),
                        itemCount: productState.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = productState.filteredProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              if (product.stock > 0) {
                                // Add to cart using Bloc
                                context.read<CartBloc>().add(
                                  AddToCartEvent(
                                    productId: product.id,
                                    name: product.name,
                                    quantity: 1,
                                    price: product.price,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.name} ditambahkan ke keranjang',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Produk habis'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
