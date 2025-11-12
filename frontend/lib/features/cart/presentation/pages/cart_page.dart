import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../widgets/cart_item_card.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _selectedPaymentMethod = 'Cash';

  Future<void> _processOrder(CartLoaded cartState) async {
    final orderProvider = context.read<OrderProvider>();

    if (cartState.itemCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang kosong')));
      return;
    }

    try {
      await orderProvider.createOrder(
        items: cartState.cartItems,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        // Clear cart using Bloc
        context.read<CartBloc>().add(ClearCartEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Belanja')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          // Handle initial state
          if (state is CartInitial) {
            return const EmptyWidget(
              message: 'Keranjang belanja Anda kosong',
              icon: Icons.shopping_cart_outlined,
            );
          }

          // Handle loaded state
          if (state is! CartLoaded) {
            return const EmptyWidget(
              message: 'Keranjang belanja Anda kosong',
              icon: Icons.shopping_cart_outlined,
            );
          }

          final cartState = state;

          if (cartState.itemCount == 0) {
            return const EmptyWidget(
              message: 'Keranjang belanja Anda kosong',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) {
                    final item = cartState.items.values.toList()[index];
                    return CartItemCard(
                      item: item,
                      onIncrease: () {
                        context.read<CartBloc>().add(
                          UpdateCartQuantityEvent(
                            productId: item.productId,
                            quantity: item.quantity + 1,
                          ),
                        );
                      },
                      onDecrease: () {
                        context.read<CartBloc>().add(
                          UpdateCartQuantityEvent(
                            productId: item.productId,
                            quantity: item.quantity - 1,
                          ),
                        );
                      },
                      onRemove: () {
                        context.read<CartBloc>().add(
                          RemoveFromCartEvent(item.productId),
                        );
                      },
                    );
                  },
                ),
              ),

              // Payment Method
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.containerLight,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: AppConstants.paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Total and Checkout
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyHelper.formatIDR(cartState.totalAmount),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkPrice
                                : AppColors.price,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () => _processOrder(cartState),
                        child: const Text(
                          'Proses Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
