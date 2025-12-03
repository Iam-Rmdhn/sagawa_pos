import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/menu/domain/models/menu_item.dart';
import 'package:sagawa_pos_new/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  bool _wasSaving = false;
  List<String> _categories = ['Semua'];
  int _selectedCategory = 0;

  /// Extract unique categories from menu items
  void _extractCategoriesFromItems(List<MenuItem> items) {
    final Set<String> uniqueCategories = {};

    // Check if any item is best seller
    bool hasBestSeller = items.any((item) => item.isBestSeller);

    for (final item in items) {
      if (item.kategori.isNotEmpty) {
        uniqueCategories.add(item.kategori);
      }
    }

    // Sort categories alphabetically
    final sortedCategories = uniqueCategories.toList()..sort();

    if (mounted) {
      setState(() {
        // Add "Best Seller" category if there are best seller items
        _categories = [
          'Semua',
          if (hasBestSeller) 'Best Seller',
          ...sortedCategories,
        ];
        // Reset selection if out of bounds
        if (_selectedCategory >= _categories.length) {
          _selectedCategory = 0;
        }
      });
    }

    print('DEBUG MenuManagement: Extracted categories: $_categories');
  }

  /// Normalize category string for comparison
  String _normalizeCategory(String category) {
    return category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  /// Filter items by selected category
  List<MenuItem> _filterByCategory(List<MenuItem> items) {
    if (_selectedCategory == 0 || _selectedCategory >= _categories.length) {
      return items; // "Semua" - show all
    }

    final selectedCategoryName = _categories[_selectedCategory];

    // Special filter for Best Seller
    if (_normalizeCategory(selectedCategoryName) == 'bestseller') {
      return items.where((item) => item.isBestSeller).toList();
    }

    return items
        .where(
          (item) =>
              _normalizeCategory(item.kategori) ==
              _normalizeCategory(selectedCategoryName),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MenuCubit, MenuState>(
      listener: (context, state) {
        if (state is MenuError) {
          _wasSaving = false;
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
        if (state is MenuSaving) {
          _wasSaving = true;
        }
        // Extract categories when menu is loaded
        if (state is MenuLoaded) {
          _extractCategoriesFromItems(state.items);

          if (_wasSaving) {
            _wasSaving = false;
            CustomSnackbar.show(
              context,
              message: 'Perubahan berhasil disimpan',
              type: SnackbarType.success,
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _buildAppBar(context),
              _buildCategoryFilter(),
              Expanded(child: _buildBody(context, state)),
              if (state is MenuLoaded && state.hasChanges)
                _buildSaveButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
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
              const Expanded(
                child: Text(
                  'Kelola Menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Get SVG icon path for category
  String? _getCategorySvgIcon(String category) {
    final normalized = category.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    if (normalized.contains('semua') || normalized == 'all') {
      return AppImages.allcategoryIcon;
    }
    if (normalized.contains('bestseller') ||
        normalized.contains('bestsaller')) {
      return AppImages.bestsallercategoryIcon;
    }
    if (normalized.contains('paketayam') ||
        normalized.contains('ayambakar') ||
        normalized.contains('ayamgoreng') ||
        normalized.contains('ayam')) {
      return AppImages.ayamcategoryIcon;
    }
    if (normalized.contains('alacarte')) {
      return AppImages.alacartecategoryIcon;
    }
    if (normalized.contains('anekanasi') || normalized.contains('nasi')) {
      return AppImages.ricecategoryIcon;
    }
    if (normalized.contains('coffee') || normalized.contains('kopi')) {
      if (normalized.contains('non')) {
        return AppImages.noncoffeescategoryIcon;
      }
      return AppImages.coffeescategoryIcon;
    }
    if (normalized.contains('donut')) {
      return AppImages.donutscategoryIcon;
    }
    if (normalized.contains('makanan') || normalized.contains('ricebowl')) {
      return AppImages.ricebowlcategoryIcon;
    }
    if (normalized.contains('sambel') ||
        normalized.contains('sambal') ||
        normalized.contains('ekstra')) {
      return AppImages.sambelcategoryIcon;
    }
    if (normalized.contains('minuman')) {
      return AppImages.noncoffeescategoryIcon;
    }
    if (normalized.contains('menuharian') || normalized.contains('harian')) {
      return AppImages.allcategoryIcon;
    }
    return null;
  }

  Widget _buildCategoryFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                const Text(
                  'Filter Kategori',
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_categories.length} kategori',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = index == _selectedCategory;
                final svgIcon = _getCategorySvgIcon(category);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _categories.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF4B4B)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF4B4B)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF4B4B,
                                  ).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (svgIcon != null)
                            SvgPicture.asset(
                              svgIcon,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                BlendMode.srcIn,
                              ),
                            )
                          else
                            Icon(
                              Icons.category_rounded,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, MenuState state) {
    if (state is MenuLoading || state is MenuSaving) {
      return const _MenuManagementSkeleton();
    }

    if (state is MenuError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<MenuCubit>().loadMenuItems();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is MenuLoaded) {
      if (state.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }

      // Filter items by selected category
      final filteredItems = _filterByCategory(state.items);
      final selectedCategoryName = _selectedCategory < _categories.length
          ? _categories[_selectedCategory]
          : 'Semua';

      // Show empty state if no items match the category filter
      if (filteredItems.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada menu di kategori "$selectedCategoryName"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Coba pilih kategori lain',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: filteredItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _MenuCard(item: filteredItems[index]);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            onPressed: () {
              context.read<MenuCubit>().saveChanges();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final MenuItem item;

  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: widget.item.stock.toString(),
    );
  }

  @override
  void didUpdateWidget(_MenuCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller only if stock changed from outside
    if (oldWidget.item.stock != widget.item.stock) {
      _stockController.text = widget.item.stock.toString();
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MenuCubit>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Best Seller icon
            Column(
              children: [
                _buildImage(),
                const SizedBox(height: 8),
                // Best Seller Toggle Button
                _buildBestSellerButton(cubit),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    widget.item.priceLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.item.status == MenuStatus.availed
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status Badge
                  _buildStatusBadge(),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Controls
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Toggle Switch
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: widget.item.isEnabled,
                    onChanged: (value) {
                      cubit.toggleEnabled(widget.item.id, value);
                    },
                    activeColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),

                // Stock Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Jumlah yang tersedia:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (value) {
                          final stock = int.tryParse(value) ?? 0;
                          cubit.updateStock(widget.item.id, stock);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellerButton(MenuCubit cubit) {
    final isBestSeller = widget.item.isBestSeller;

    return GestureDetector(
      onTap: () {
        cubit.toggleBestSeller(widget.item.id, !isBestSeller);
      },
      child: SvgPicture.asset(
        AppImages.bestsallercategoryIcon,
        width: 38,
        height: 38,
        colorFilter: ColorFilter.mode(
          isBestSeller
              ? const Color(0xFFFFB300) // Yellow/amber when ON
              : Colors.grey.shade300, // Grey when OFF
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Check if it's base64 data
    if (widget.item.imageUrl.startsWith('data:image')) {
      try {
        final base64String = widget.item.imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    // Network image
    if (widget.item.imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.item.imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    // Asset image
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        widget.item.imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.restaurant, size: 40, color: Colors.grey.shade400),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;

    switch (widget.item.status) {
      case MenuStatus.availed:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case MenuStatus.outOfStock:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case MenuStatus.notAvailed:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.item.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Skeleton loading untuk menu management dengan efek shimmer
class _MenuManagementSkeleton extends StatelessWidget {
  const _MenuManagementSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => const _MenuManagementCardSkeleton(),
      ),
    );
  }
}

class _MenuManagementCardSkeleton extends StatelessWidget {
  const _MenuManagementCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 70,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
