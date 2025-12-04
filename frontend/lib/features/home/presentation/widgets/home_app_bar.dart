import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';

class HomeAppBarCard extends StatelessWidget {
  const HomeAppBarCard({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.searchController,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isCompact = ResponsiveHelper.isTabletLandscape(context);

    final horizontalPadding = isCompact ? 14.0 : 20.0;
    final bottomPadding = isCompact ? 14.0 : 20.0;
    final topInnerPadding = isCompact ? 8.0 : 12.0;
    final borderRadius = isCompact ? 24.0 : 32.0;
    final buttonSize = isCompact ? 36.0 : 44.0;
    final searchPaddingH = isCompact ? 12.0 : 16.0;
    final searchPaddingV = isCompact ? 10.0 : 14.0;
    final searchRadius = isCompact ? 20.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4B4B), Color(0xFFFF4B4B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding + topInnerPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.menu,
            onTap: onMenuTap,
            size: buttonSize,
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(searchRadius),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000),
                      blurRadius: isCompact ? 8 : 12,
                      offset: Offset(0, isCompact ? 4 : 6),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: searchPaddingH,
                  vertical: searchPaddingV,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: const Color(0xFF444444),
                      size: isCompact ? 20 : 24,
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Text(
                      'Cari menu lainnya...',
                      style: TextStyle(
                        color: const Color(0xFF9E9E9E),
                        fontSize: isCompact ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap, this.size = 44});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3A2F2F), size: size * 0.5),
      ),
    );
  }
}
