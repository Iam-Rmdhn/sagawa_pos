import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';

class OrderDetailAppBar extends StatelessWidget {
  const OrderDetailAppBar({super.key, required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
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
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      AppImages.backArrow,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Detail Pemesanan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
