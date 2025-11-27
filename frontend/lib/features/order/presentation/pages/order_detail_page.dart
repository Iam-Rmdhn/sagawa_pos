import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi nama Kasir dan Pelanggan terlebih dahulu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
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
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 64 + 16,
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    final cartItems = _groupCartItems(state.cart);
                    final subtotal = state.cartTotal;

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: state.cart.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Lottie.asset(
                                          'assets/animations/empty_cart.json',
                                          width: 200,
                                          height: 200,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Keranjang kosong',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Tambahkan produk untuk memulai pesanan',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFB0B0B0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
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
                                                  onIncrement: () {
                                                    context
                                                        .read<HomeCubit>()
                                                        .addToCart(product);
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
                                                        .removeFromCart(
                                                          product.id,
                                                        );
                                                  },
                                                ),
                                                if (index <
                                                    cartItems.length - 1)
                                                  const Divider(
                                                    height: 1,
                                                    thickness: 1,
                                                  ),
                                              ],
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Fixed bottom sections
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 1),
                              // Kasir and Pelanggan input fields
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
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
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          border: InputBorder.none,
                                          errorText: _cashierError ? '' : null,
                                          errorStyle: const TextStyle(
                                            height: 0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
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
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          border: InputBorder.none,
                                          errorText: _customerError ? '' : null,
                                          errorStyle: const TextStyle(
                                            height: 0,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Request',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0F0),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: TextField(
                                  controller: _notesController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText:
                                        'catatan..\n(cabenya 1 truck ya mas...)',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.2),
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Subtotal :',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatCurrency(subtotal),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _validateAndProceed(subtotal, state.cart),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4B4B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Pilih Metode Pembayaran',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 0.1),
                            ],
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
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityButton(icon: Icons.remove, onTap: onDecrement),
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                _QuantityButton(icon: Icons.add, onTap: onIncrement),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFFFB74D),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
