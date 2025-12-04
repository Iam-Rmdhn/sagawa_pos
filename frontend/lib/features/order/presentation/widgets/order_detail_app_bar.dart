import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';

class OrderDetailAppBar extends StatelessWidget {
  const OrderDetailAppBar({
    super.key,
    required this.onBackTap,
    this.title = 'Keranjang',
    this.isCompact = false,
  });

  final VoidCallback onBackTap;
  final String title;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final borderRadius = isCompact ? 24.0 : 30.0;
    final horizontalPadding = isCompact ? 12.0 : 16.0;
    final topPadding = isCompact ? 4.0 : 8.0;
    final bottomPadding = isCompact ? 10.0 : 16.0;
    final titleFontSize = isCompact ? 17.0 : 20.0;
    final iconSize = isCompact ? 20.0 : 24.0;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      child: Container(
        color: const Color(0xFFFF4B4B),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            decoration: const BoxDecoration(color: Color(0xFFFF4B4B)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBackTap,
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: SvgPicture.asset(
                      AppImages.backArrow,
                      width: isCompact ? 28 : 35,
                      height: isCompact ? 28 : 35,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 32 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
