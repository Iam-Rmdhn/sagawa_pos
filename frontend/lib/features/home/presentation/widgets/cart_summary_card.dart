import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos/features/order/presentation/pages/order_detail_page.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({
    super.key,
    required this.itemCount,
    required this.totalPrice,
  });

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
