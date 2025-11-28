import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/data/services/settings_service.dart';
import 'package:sagawa_pos_new/features/order/presentation/widgets/order_detail_app_bar.dart';
import 'package:sagawa_pos_new/features/receipt/receipt.dart';

class PaymentMethodPage extends StatefulWidget {
  final int subtotal;
  final String cashierName;
  final String customerName;
  final List<Map<String, dynamic>> cartItems;

  const PaymentMethodPage({
    super.key,
    required this.subtotal,
    required this.cashierName,
    required this.customerName,
    required this.cartItems,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  int _selectedOrderType = 0; // 0 = Dine In, 1 = Take Away
  int _selectedPaymentMethod = -1; // 0 = QRIS, 1 = Cash
  final TextEditingController _cashController = TextEditingController();
  int _cashAmount = 0;
  bool _isTaxEnabled = false;
  int _taxAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadTaxSetting();
  }

  Future<void> _loadTaxSetting() async {
    final taxEnabled = await SettingsService.isTaxEnabled();
    setState(() {
      _isTaxEnabled = taxEnabled;
      if (_isTaxEnabled) {
        _taxAmount = (widget.subtotal * 0.1).round();
      } else {
        _taxAmount = 0;
      }
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.subtotal + _taxAmount;
    final changes = _selectedPaymentMethod == 1 ? _cashAmount - total : 0;

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
                child: OrderDetailAppBar(
                  onBackTap: () => Navigator.pop(context),
                  title: 'Metode Pembayaran',
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 64 + 16,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtotal Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _formatCurrency(widget.subtotal),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Order Type Selection (Dine In / Take Away)
                      Row(
                        children: [
                          Expanded(
                            child: _OrderTypeCard(
                              icon: AppImages.dineIn,
                              label: 'Dine In',
                              isSelected: _selectedOrderType == 0,
                              onTap: () {
                                setState(() {
                                  _selectedOrderType = 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _OrderTypeCard(
                              icon: AppImages.takeAway,
                              label: 'Take Away',
                              isSelected: _selectedOrderType == 1,
                              onTap: () {
                                setState(() {
                                  _selectedOrderType = 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Payment Method Title
                      Text(
                        'Pilih metode pembayaran:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payment Method Selection (QRIS / Cash)
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: AppImages.qrisIcon,
                              label: 'Qris',
                              isSelected: _selectedPaymentMethod == 0,
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: AppImages.cashIcon,
                              label: 'Cash',
                              isSelected: _selectedPaymentMethod == 1,
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cash Input (only show when Cash is selected)
                      if (_selectedPaymentMethod == 1) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masukkan Nominal Cash',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _cashController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Rp 0',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.payments,
                                    color: Color(0xFFFF4B4B),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFF4B4B),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4CAF50),
                                ),
                                onChanged: (value) {
                                  // Remove all non-digit characters
                                  final numericValue = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );

                                  if (numericValue.isEmpty) {
                                    setState(() {
                                      _cashAmount = 0;
                                      _cashController.clear();
                                    });
                                    return;
                                  }

                                  // Parse the numeric value
                                  final amount = int.parse(numericValue);

                                  // Format with thousand separators
                                  final formatted = _formatCurrencyInput(
                                    amount,
                                  );

                                  // Update controller with formatted value
                                  _cashController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );

                                  setState(() {
                                    _cashAmount = amount;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Summary Section
                      const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 16),
                      const Text(
                        'Nominal Pemesanan:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Subtotal',
                        value: _formatCurrency(widget.subtotal),
                      ),
                      if (_isTaxEnabled) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'PB1 10%',
                          value: _formatCurrency(_taxAmount),
                        ),
                      ],
                      if (_selectedPaymentMethod == 0) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Qris',
                          value: _formatCurrency(total),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Changes',
                          value: _formatCurrency(0),
                          isChange: true,
                        ),
                      ],
                      if (_selectedPaymentMethod == 1 && _cashAmount > 0) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Cash',
                          value: _formatCurrency(_cashAmount),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Changes',
                          value: _formatCurrency(changes),
                          isChange: true,
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            _formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _selectedPaymentMethod == -1
                              ? null
                              : () async {
                                  // Validate cash amount if cash payment
                                  if (_selectedPaymentMethod == 1) {
                                    if (_cashAmount < total) {
                                      CustomSnackbar.show(
                                        context,
                                        message:
                                            'Nominal cash kurang! Minimal ${_formatCurrency(total)}',
                                        type: SnackbarType.warning,
                                      );
                                      return;
                                    }
                                  }

                                  // Prepare receipt data
                                  final orderType = _selectedOrderType == 0
                                      ? 'Dine In'
                                      : 'Take Away';

                                  final paymentMethod =
                                      _selectedPaymentMethod == 0
                                      ? 'QRIS'
                                      : 'Cash';

                                  // Debug log
                                  print(
                                    'DEBUG: Selected payment method index = $_selectedPaymentMethod',
                                  );
                                  print(
                                    'DEBUG: Payment method string = $paymentMethod',
                                  );

                                  final cashAmount = _selectedPaymentMethod == 0
                                      ? total.toDouble()
                                      : _cashAmount.toDouble();

                                  // Navigate to receipt page
                                  if (!context.mounted) return;
                                  await PaymentSuccessExample.showReceipt(
                                    context,
                                    orderType: orderType,
                                    customerName: widget.customerName,
                                    cashierName: widget.cashierName,
                                    cartItems: widget.cartItems,
                                    subTotal: widget.subtotal.toDouble(),
                                    taxPercent: _isTaxEnabled ? 10.0 : 0.0,
                                    cashAmount: cashAmount,
                                    paymentMethod: paymentMethod,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4B4B),
                            disabledBackgroundColor: const Color(0xFFBDBDBD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Selesaikan dan Cetak Struk',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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

  String _formatCurrencyInput(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }
}

class _OrderTypeCard extends StatelessWidget {
  const _OrderTypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD966) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB000) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.black : Colors.black54,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.black : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD966) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD966)
                : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              placeholderBuilder: (BuildContext context) => Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isChange = false,
  });

  final String label;
  final String value;
  final bool isChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isChange ? const Color(0xFFFF4B4B) : const Color(0xFF757575),
            fontWeight: isChange ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isChange ? const Color(0xFFFF4B4B) : const Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}
