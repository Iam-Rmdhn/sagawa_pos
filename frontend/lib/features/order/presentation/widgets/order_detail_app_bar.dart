import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';

class OrderDetailAppBar extends StatelessWidget {
  const OrderDetailAppBar({
    super.key,
    required this.onBackTap,
    this.title = 'Pemesanan',
  });

  final VoidCallback onBackTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Container(
        color: const Color(0xFFFF4B4B),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(color: Color(0xFFFF4B4B)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBackTap,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      AppImages.backArrow,
                      width: 35,
                      height: 35,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
