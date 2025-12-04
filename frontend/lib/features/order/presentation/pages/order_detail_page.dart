import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:sagawa_pos_new/features/order/presentation/widgets/order_detail_app_bar.dart';
import 'package:sagawa_pos_new/features/payment/presentation/pages/payment_method_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _notesController = TextEditingController();
  final _cashierController = TextEditingController();
  final _customerController = TextEditingController();
  bool _cashierError = false;
  bool _customerError = false;

  @override
  void dispose() {
    _notesController.dispose();
    _cashierController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _validateAndProceed(int subtotal, List<Product> cartItems) {
    setState(() {
      _cashierError = _cashierController.text.trim().isEmpty;
      _customerError = _customerController.text.trim().isEmpty;
    });

    if (_cashierError || _customerError) {
      CustomSnackbar.show(
        context,
        message: 'Mohon isi nama Kasir dan Pelanggan terlebih dahulu',
        type: SnackbarType.warning,
      );
      return;
    }

    // Convert cart items to map format
    final cartItemsMap = cartItems.map((product) {
      return {
        'name': product.title,
        'quantity': 1, // Each product in cart is 1 item
        'price': product.price.toDouble(),
        'subtotal': product.price.toDouble(),
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(
          subtotal: subtotal,
          cashierName: _cashierController.text.trim(),
          customerName: _customerController.text.trim(),
          cartItems: cartItemsMap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveHelper.isTabletLandscape(context);
    final contentPadding = isCompact ? 12.0 : 16.0;
    final appBarHeight = isCompact ? 56.0 : 64.0;
    final topOffset =
        MediaQuery.of(context).padding.top +
        appBarHeight +
        (isCompact ? 8 : 16);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, appBarConstraints) {
                    return OrderDetailAppBar(
                      onBackTap: () => Navigator.pop(context),
                      isCompact: isCompact,
                    );
                  },
                ),
              ),
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    final cartItems = _groupCartItems(state.cart);
                    final subtotal = state.cartTotal;

                    return Column(
                      children: [
                        // Scrollable cart items section
                        Expanded(
                          child: state.cart.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Lottie.asset(
                                          'assets/animations/empty_cart.json',
                                          width: isCompact ? 100 : 150,
                                          height: isCompact ? 100 : 150,
                                        ),
                                        SizedBox(height: isCompact ? 8 : 12),
                                        Text(
                                          'Keranjang kosong',
                                          style: TextStyle(
                                            fontSize: isCompact ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF757575),
                                          ),
                                        ),
                                        SizedBox(height: isCompact ? 2 : 4),
                                        Text(
                                          'Tambahkan produk untuk memulai',
                                          style: TextStyle(
                                            fontSize: isCompact ? 11 : 13,
                                            color: const Color(0xFFB0B0B0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: contentPadding,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        ...cartItems.entries.map((entry) {
                                          final product = entry.key;
                                          final quantity = entry.value;
                                          final index = cartItems.keys
                                              .toList()
                                              .indexOf(product);

                                          return Column(
                                            children: [
                                              _CartItemTile(
                                                product: product,
                                                quantity: quantity,
                                                isCompact: isCompact,
                                                onIncrement: () {
                                                  final success = context
                                                      .read<HomeCubit>()
                                                      .addToCart(product);

                                                  if (!success) {
                                                    CustomSnackbar.show(
                                                      context,
                                                      message:
                                                          'Stok ${product.title} tidak mencukupi',
                                                      type:
                                                          SnackbarType.warning,
                                                    );
                                                  }
                                                },
                                                onDecrement: () {
                                                  context
                                                      .read<HomeCubit>()
                                                      .removeFromCart(
                                                        product.id,
                                                      );
                                                },
                                                onDelete: () {
                                                  context
                                                      .read<HomeCubit>()
                                                      .removeAllFromCart(
                                                        product.id,
                                                      );
                                                },
                                              ),
                                              if (index < cartItems.length - 1)
                                                const Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        // Fixed bottom section - constrained to available space
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: isCompact ? 180 : 220,
                          ),
                          child: SingleChildScrollView(
                            child: Container(
                              color: const Color(0xFFF5F5F5),
                              padding: EdgeInsets.all(contentPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kasir and Pelanggan input fields
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              isCompact ? 12 : 16,
                                            ),
                                            border: Border.all(
                                              color: _cashierError
                                                  ? Colors.red
                                                  : const Color(0xFFE0E0E0),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: isCompact ? 6 : 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 12 : 16,
                                            vertical: isCompact ? 2 : 4,
                                          ),
                                          child: TextField(
                                            controller: _cashierController,
                                            onChanged: (value) {
                                              if (_cashierError &&
                                                  value.isNotEmpty) {
                                                setState(
                                                  () => _cashierError = false,
                                                );
                                              }
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Kasir',
                                              labelStyle: TextStyle(
                                                color: _cashierError
                                                    ? Colors.red
                                                    : const Color(0xFF757575),
                                                fontSize: isCompact ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              border: InputBorder.none,
                                              isDense: isCompact,
                                              contentPadding: isCompact
                                                  ? const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    )
                                                  : null,
                                              errorText: _cashierError
                                                  ? ''
                                                  : null,
                                              errorStyle: const TextStyle(
                                                height: 0,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: isCompact ? 14 : 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isCompact ? 8 : 12),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              isCompact ? 12 : 16,
                                            ),
                                            border: Border.all(
                                              color: _customerError
                                                  ? Colors.red
                                                  : const Color(0xFFE0E0E0),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: isCompact ? 6 : 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 12 : 16,
                                            vertical: isCompact ? 2 : 4,
                                          ),
                                          child: TextField(
                                            controller: _customerController,
                                            onChanged: (value) {
                                              if (_customerError &&
                                                  value.isNotEmpty) {
                                                setState(
                                                  () => _customerError = false,
                                                );
                                              }
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Pelanggan',
                                              labelStyle: TextStyle(
                                                color: _customerError
                                                    ? Colors.red
                                                    : const Color(0xFF757575),
                                                fontSize: isCompact ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              border: InputBorder.none,
                                              isDense: isCompact,
                                              contentPadding: isCompact
                                                  ? const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    )
                                                  : null,
                                              errorText: _customerError
                                                  ? ''
                                                  : null,
                                              errorStyle: const TextStyle(
                                                height: 0,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: isCompact ? 14 : 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isCompact ? 8 : 12),
                                  // Request field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        isCompact ? 12 : 16,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: isCompact ? 6 : 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 12 : 16,
                                      vertical: isCompact ? 2 : 4,
                                    ),
                                    child: TextField(
                                      controller: _notesController,
                                      maxLines: isCompact ? 1 : 2,
                                      decoration: InputDecoration(
                                        labelText: 'Request / Catatan',
                                        labelStyle: TextStyle(
                                          color: const Color(0xFF757575),
                                          fontSize: isCompact ? 12 : 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        hintText: 'Contoh: pedas level 5',
                                        hintStyle: TextStyle(
                                          color: Colors.black.withOpacity(0.3),
                                          fontSize: isCompact ? 12 : 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: isCompact,
                                        contentPadding: isCompact
                                            ? const EdgeInsets.symmetric(
                                                vertical: 8,
                                              )
                                            : null,
                                      ),
                                      style: TextStyle(
                                        fontSize: isCompact ? 14 : 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 8 : 12),
                                  // Subtotal and Button Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Subtotal',
                                              style: TextStyle(
                                                fontSize: isCompact ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF757575),
                                              ),
                                            ),
                                            Text(
                                              _formatCurrency(subtotal),
                                              style: TextStyle(
                                                fontSize: isCompact ? 18 : 22,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF4CAF50),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: isCompact ? 40 : 50,
                                        child: ElevatedButton(
                                          onPressed: () => _validateAndProceed(
                                            subtotal,
                                            state.cart,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFFF4B4B,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isCompact ? 12 : 16,
                                                  ),
                                            ),
                                            elevation: 2,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isCompact ? 14 : 20,
                                            ),
                                          ),
                                          child: Text(
                                            'Metode Pembayaran',
                                            style: TextStyle(
                                              fontSize: isCompact ? 13 : 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Map<Product, int> _groupCartItems(List<Product> cart) {
    final Map<Product, int> grouped = {};
    for (final product in cart) {
      bool found = false;
      for (final existingProduct in grouped.keys) {
        if (existingProduct.id == product.id) {
          grouped[existingProduct] = grouped[existingProduct]! + 1;
          found = true;
          break;
        }
      }
      if (!found) {
        grouped[product] = 1;
      }
    }
    return grouped;
  }

  String _formatCurrency(int value) {
    final s = value.toString();
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    this.isCompact = false,
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 10 : 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                SizedBox(height: isCompact ? 2 : 4),
                Text(
                  product.priceLabel,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: onDecrement,
                  isCompact: isCompact,
                ),
                Container(
                  constraints: BoxConstraints(minWidth: isCompact ? 24 : 32),
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onTap: onIncrement,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 6 : 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: isCompact ? 26 : 32,
              height: isCompact ? 26 : 32,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: isCompact ? 14 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.isCompact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCompact ? 26 : 32,
        height: isCompact ? 26 : 32,
        decoration: const BoxDecoration(
          color: Color(0xFFFFB74D),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: isCompact ? 14 : 18),
      ),
    );
  }
}
