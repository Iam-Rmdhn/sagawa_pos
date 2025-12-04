import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';

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
    final isCompact = ResponsiveHelper.isTabletLandscape(context);
    final titleFontSize = isCompact ? 14.0 : 16.0;
    final badgeFontSize = isCompact ? 10.0 : 12.0;
    final categoryHeight = isCompact ? 36.0 : 44.0;
    final topPadding = isCompact ? 10.0 : 16.0;
    final bottomPadding = isCompact ? 8.0 : 14.0;
    final sidePadding = isCompact ? 14.0 : 24.0;

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
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              topPadding,
              sidePadding - 4,
              isCompact ? 8 : 12,
            ),
            child: Row(
              children: [
                Text(
                  'Kategori',
                  style: TextStyle(
                    color: const Color(0xFF1F1F1F),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 10,
                    vertical: isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                  ),
                  child: Text(
                    '${widget.categories.length} kategori',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: categoryHeight,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = index == widget.selectedIndex;
                final svgIcon = _getCategorySvgIcon(category);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < widget.categories.length - 1
                        ? (isCompact ? 6 : 8)
                        : 0,
                  ),
                  child: _CategoryChip(
                    label: category,
                    svgIconPath: svgIcon,
                    fallbackIcon: svgIcon == null
                        ? _getFallbackIcon(category)
                        : null,
                    isSelected: isSelected,
                    onTap: () => widget.onSelected?.call(index),
                    isCompact: isCompact,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: bottomPadding),
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
    this.isCompact = false,
  });

  final String label;
  final String? svgIconPath;
  final IconData? fallbackIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isCompact
        ? (isSelected ? 12.0 : 10.0)
        : (isSelected ? 16.0 : 14.0);
    final verticalPadding = isCompact ? 6.0 : 10.0;
    final fontSize = isCompact ? 11.0 : 13.0;
    final iconSize = isCompact ? 14.0 : 18.0;
    final borderRadius = isCompact ? 16.0 : 22.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(borderRadius),
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
            _buildIcon(iconSize),
            SizedBox(width: isCompact ? 4 : 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: fontSize,
                letterSpacing: -0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(double size) {
    final iconColor = isSelected ? Colors.white : Colors.grey.shade600;

    if (svgIconPath != null) {
      return SvgPicture.asset(
        svgIconPath!,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }

    return Icon(
      fallbackIcon ?? Icons.category_rounded,
      size: size - 2,
      color: iconColor,
    );
  }
}
