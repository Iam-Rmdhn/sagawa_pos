import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';

class HomeCategoryCard extends StatefulWidget {
  const HomeCategoryCard({
    super.key,
    required this.categories,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  State<HomeCategoryCard> createState() => _HomeCategoryCardState();
}

class _HomeCategoryCardState extends State<HomeCategoryCard>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  String? _getCategorySvgIcon(String category) {
    final normalized = category.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    // Semua / All
    if (normalized.contains('semua') || normalized == 'all') {
      return AppImages.allcategoryIcon;
    }

    // Best Seller
    if (normalized.contains('bestseller') ||
        normalized.contains('bestsaller')) {
      return AppImages.bestsallercategoryIcon;
    }

    // Paket Ayam (Bakar/Goreng)
    if (normalized.contains('paketayam') ||
        normalized.contains('ayambakar') ||
        normalized.contains('ayamgoreng') ||
        normalized.contains('ayam')) {
      return AppImages.ayamcategoryIcon;
    }

    // Ala Carte
    if (normalized.contains('alacarte')) {
      return AppImages.alacartecategoryIcon;
    }

    // Aneka Nasi / Nasi
    if (normalized.contains('anekanasi') || normalized.contains('nasi')) {
      return AppImages.ricecategoryIcon;
    }

    // Coffee
    if (normalized.contains('coffee') || normalized.contains('kopi')) {
      if (normalized.contains('non')) {
        return AppImages.noncoffeescategoryIcon;
      }
      return AppImages.coffeescategoryIcon;
    }

    // Donuts
    if (normalized.contains('donut')) {
      return AppImages.donutscategoryIcon;
    }

    // Makanan / Ricebowl
    if (normalized.contains('makanan') || normalized.contains('ricebowl')) {
      return AppImages.ricebowlcategoryIcon;
    }

    // Sambel / Sambal
    if (normalized.contains('sambel') ||
        normalized.contains('sambal') ||
        normalized.contains('ekstra')) {
      return AppImages.sambelcategoryIcon;
    }

    // Minuman
    if (normalized.contains('minuman')) {
      return AppImages.noncoffeescategoryIcon;
    }

    // Menu Harian - use all category as default
    if (normalized.contains('menuharian') || normalized.contains('harian')) {
      return AppImages.allcategoryIcon;
    }

    return null; // Use default icon
  }

  // Fallback Material icon for categories without SVG
  IconData _getFallbackIcon(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('best seller'))
      return Icons.local_fire_department_rounded;
    if (normalized.contains('snack')) return Icons.fastfood_rounded;
    if (normalized.contains('dessert')) return Icons.cake_rounded;

    return Icons.category_rounded;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Kategori',
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.categories.length} kategori',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 44,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = index == widget.selectedIndex;
                final svgIcon = _getCategorySvgIcon(category);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < widget.categories.length - 1 ? 8 : 0,
                  ),
                  child: _CategoryChip(
                    label: category,
                    svgIconPath: svgIcon,
                    fallbackIcon: svgIcon == null
                        ? _getFallbackIcon(category)
                        : null,
                    isSelected: isSelected,
                    onTap: () => widget.onSelected?.call(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    this.svgIconPath,
    this.fallbackIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? svgIconPath;
  final IconData? fallbackIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4B4B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconColor = isSelected ? Colors.white : Colors.grey.shade600;

    if (svgIconPath != null) {
      return SvgPicture.asset(
        svgIconPath!,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }

    return Icon(
      fallbackIcon ?? Icons.category_rounded,
      size: 16,
      color: iconColor,
    );
  }
}
