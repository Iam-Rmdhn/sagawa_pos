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
  int _selectedPaymentMethod = -1; // 0 = QRIS, 1 = Cash, 2 = Voucher
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _voucherCodeController = TextEditingController();
  final TextEditingController _voucherAmountController =
      TextEditingController();
  final TextEditingController _additionalPaymentController =
      TextEditingController();
  int _cashAmount = 0;
  int _voucherAmount = 0;
  bool _isVoucherVerified = false;
  String _voucherCode = '';
  bool _isTaxEnabled = false;
  int _taxAmount = 0;
  // Additional payment for voucher shortfall
  int _additionalPaymentMethod = -1; // 0 = QRIS, 1 = Cash
  int _additionalPaymentAmount = 0;

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
    _voucherCodeController.dispose();
    _voucherAmountController.dispose();
    _additionalPaymentController.dispose();
    super.dispose();
  }

  // Helper to check if voucher needs additional payment
  bool get _voucherNeedsAdditionalPayment {
    if (!_isVoucherVerified) return false;
    final total = widget.subtotal + _taxAmount;
    return _voucherAmount < total;
  }

  // Calculate voucher shortfall
  int get _voucherShortfall {
    final total = widget.subtotal + _taxAmount;
    if (_voucherAmount >= total) return 0;
    return total - _voucherAmount;
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

                      // Payment Method Selection (QRIS / Cash / Voucher)
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
                                  _isVoucherVerified = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: AppImages.cashIcon,
                              label: 'Cash',
                              isSelected: _selectedPaymentMethod == 1,
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 1;
                                  _isVoucherVerified = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: AppImages.voucherIcon,
                              label: 'Voucher',
                              isSelected: _selectedPaymentMethod == 2,
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 2;
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
                                    Icons.payments_outlined,
                                    color: Colors.green,
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
                                      color: Colors.lightGreen,
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

                      // Voucher Input (only show when Voucher is selected)
                      if (_selectedPaymentMethod == 2) ...[
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
                                'Masukkan Kode Voucher',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _voucherCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Contoh: VCHR-XXXX-XXXX',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  prefixIcon: SizedBox(
                                    width: 48,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        AppImages.voucherIcon,
                                        width: 22,
                                        height: 22,
                                        colorFilter: ColorFilter.mode(
                                          _isVoucherVerified
                                              ? Colors.green
                                              : const Color(0xFFFF4B4B),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  suffixIcon: _isVoucherVerified
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : null,
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
                                    borderSide: BorderSide(
                                      color: _isVoucherVerified
                                          ? Colors.green
                                          : const Color(0xFFFF4B4B),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isVoucherVerified
                                      ? Colors.green
                                      : const Color(0xFF1F1F1F),
                                  letterSpacing: 1.2,
                                ),
                                enabled: !_isVoucherVerified,
                                onChanged: (value) {
                                  setState(() {
                                    _voucherCode = value.toUpperCase();
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nominal Voucher',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _voucherAmountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Rp 0',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.redeem_outlined,
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
                                    borderSide: BorderSide(
                                      color: _isVoucherVerified
                                          ? Colors.green
                                          : const Color(0xFFFF4B4B),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _isVoucherVerified
                                      ? Colors.green
                                      : const Color(0xFFFF4B4B),
                                ),
                                enabled: !_isVoucherVerified,
                                onChanged: (value) {
                                  final numericValue = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );

                                  if (numericValue.isEmpty) {
                                    setState(() {
                                      _voucherAmount = 0;
                                      _voucherAmountController.clear();
                                    });
                                    return;
                                  }

                                  final amount = int.parse(numericValue);
                                  final formatted = _formatCurrencyInput(
                                    amount,
                                  );

                                  _voucherAmountController.value =
                                      TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );

                                  setState(() {
                                    _voucherAmount = amount;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isVoucherVerified
                                      ? _resetVoucher
                                      : _verifyVoucher,
                                  icon: Icon(
                                    _isVoucherVerified
                                        ? Icons.refresh
                                        : Icons.verified_outlined,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _isVoucherVerified
                                        ? 'Reset Voucher'
                                        : 'Verifikasi Voucher',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isVoucherVerified
                                        ? Colors.orange
                                        : const Color(0xFFFF4B4B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              // Voucher sufficient - show success
                              if (_isVoucherVerified &&
                                  !_voucherNeedsAdditionalPayment) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Voucher valid! Nominal: ${_formatCurrency(_voucherAmount)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Voucher insufficient - show warning and additional payment
                              if (_isVoucherVerified &&
                                  _voucherNeedsAdditionalPayment) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Nominal voucher kurang ${_formatCurrency(_voucherShortfall)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pilih metode pembayaran tambahan:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Additional Payment Method Selection
                                Row(
                                  children: [
                                    Expanded(
                                      child: _AdditionalPaymentCard(
                                        icon: AppImages.qrisIcon,
                                        label: 'QRIS',
                                        isSelected:
                                            _additionalPaymentMethod == 0,
                                        onTap: () {
                                          setState(() {
                                            _additionalPaymentMethod = 0;
                                            _additionalPaymentAmount =
                                                _voucherShortfall;
                                            _additionalPaymentController
                                                .clear();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _AdditionalPaymentCard(
                                        icon: AppImages.cashIcon,
                                        label: 'Cash',
                                        isSelected:
                                            _additionalPaymentMethod == 1,
                                        onTap: () {
                                          setState(() {
                                            _additionalPaymentMethod = 1;
                                            _additionalPaymentAmount = 0;
                                            _additionalPaymentController
                                                .clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // Cash input for additional payment
                                if (_additionalPaymentMethod == 1) ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _additionalPaymentController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Minimal ${_formatCurrency(_voucherShortfall)}',
                                      hintStyle: TextStyle(
                                        color: Colors.black.withOpacity(0.3),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.payments_outlined,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5F5),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
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
                                          color: Colors.lightGreen,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    onChanged: (value) {
                                      final numericValue = value.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );

                                      if (numericValue.isEmpty) {
                                        setState(() {
                                          _additionalPaymentAmount = 0;
                                          _additionalPaymentController.clear();
                                        });
                                        return;
                                      }

                                      final amount = int.parse(numericValue);
                                      final formatted = _formatCurrencyInput(
                                        amount,
                                      );

                                      _additionalPaymentController.value =
                                          TextEditingValue(
                                            text: formatted,
                                            selection: TextSelection.collapsed(
                                              offset: formatted.length,
                                            ),
                                          );

                                      setState(() {
                                        _additionalPaymentAmount = amount;
                                      });
                                    },
                                  ),
                                ],
                                // QRIS info
                                if (_additionalPaymentMethod == 0) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Color(0xFF2196F3),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tambahan QRIS: ${_formatCurrency(_voucherShortfall)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2196F3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
                      if (_selectedPaymentMethod == 2 &&
                          _isVoucherVerified) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Voucher (${_voucherCode})',
                          value: _formatCurrency(_voucherAmount),
                        ),
                        // Show additional payment info if voucher is insufficient
                        if (_voucherNeedsAdditionalPayment &&
                            _additionalPaymentMethod != -1) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: _additionalPaymentMethod == 0
                                ? 'Tambahan QRIS'
                                : 'Tambahan Cash',
                            value: _formatCurrency(
                              _additionalPaymentMethod == 0
                                  ? _voucherShortfall
                                  : _additionalPaymentAmount,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Changes',
                            value: _formatCurrency(
                              _additionalPaymentMethod == 0
                                  ? 0
                                  : (_additionalPaymentAmount >
                                            _voucherShortfall
                                        ? _additionalPaymentAmount -
                                              _voucherShortfall
                                        : 0),
                            ),
                            isChange: true,
                          ),
                        ] else if (!_voucherNeedsAdditionalPayment) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Changes',
                            value: _formatCurrency(_voucherAmount - total),
                            isChange: true,
                          ),
                        ],
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

                                  // Validate voucher if voucher payment
                                  if (_selectedPaymentMethod == 2) {
                                    if (!_isVoucherVerified) {
                                      CustomSnackbar.show(
                                        context,
                                        message:
                                            'Silakan verifikasi voucher terlebih dahulu!',
                                        type: SnackbarType.warning,
                                      );
                                      return;
                                    }
                                    // Check if voucher needs additional payment
                                    if (_voucherNeedsAdditionalPayment) {
                                      if (_additionalPaymentMethod == -1) {
                                        CustomSnackbar.show(
                                          context,
                                          message:
                                              'Pilih metode pembayaran tambahan!',
                                          type: SnackbarType.warning,
                                        );
                                        return;
                                      }
                                      // Validate additional cash amount
                                      if (_additionalPaymentMethod == 1 &&
                                          _additionalPaymentAmount <
                                              _voucherShortfall) {
                                        CustomSnackbar.show(
                                          context,
                                          message:
                                              'Nominal cash tambahan kurang! Minimal ${_formatCurrency(_voucherShortfall)}',
                                          type: SnackbarType.warning,
                                        );
                                        return;
                                      }
                                    }
                                  }

                                  // Prepare receipt data
                                  final orderType = _selectedOrderType == 0
                                      ? 'Dine In'
                                      : 'Take Away';

                                  String paymentMethod;
                                  if (_selectedPaymentMethod == 0) {
                                    paymentMethod = 'QRIS';
                                  } else if (_selectedPaymentMethod == 1) {
                                    paymentMethod = 'Cash';
                                  } else {
                                    // Voucher payment
                                    if (_voucherNeedsAdditionalPayment) {
                                      paymentMethod =
                                          _additionalPaymentMethod == 0
                                          ? 'Voucher + QRIS'
                                          : 'Voucher + Cash';
                                    } else {
                                      paymentMethod = 'Voucher';
                                    }
                                  }

                                  // Debug log
                                  print(
                                    'DEBUG: Selected payment method index = $_selectedPaymentMethod',
                                  );
                                  print(
                                    'DEBUG: Payment method string = $paymentMethod',
                                  );

                                  double cashAmount;
                                  if (_selectedPaymentMethod == 0) {
                                    cashAmount = total.toDouble();
                                  } else if (_selectedPaymentMethod == 1) {
                                    cashAmount = _cashAmount.toDouble();
                                  } else {
                                    // Voucher: total paid = voucher + additional
                                    if (_voucherNeedsAdditionalPayment) {
                                      cashAmount = _additionalPaymentMethod == 0
                                          ? (_voucherAmount + _voucherShortfall)
                                                .toDouble()
                                          : (_voucherAmount +
                                                    _additionalPaymentAmount)
                                                .toDouble();
                                    } else {
                                      cashAmount = _voucherAmount.toDouble();
                                    }
                                  }

                                  // Prepare voucher data for receipt
                                  String? voucherCode;
                                  double? voucherAmountForReceipt;
                                  double? additionalPaymentForReceipt;
                                  String? additionalPaymentMethodForReceipt;

                                  if (_selectedPaymentMethod == 2 &&
                                      _isVoucherVerified) {
                                    voucherCode = _voucherCode;
                                    voucherAmountForReceipt = _voucherAmount
                                        .toDouble();
                                    if (_voucherNeedsAdditionalPayment) {
                                      additionalPaymentForReceipt =
                                          _additionalPaymentMethod == 0
                                          ? _voucherShortfall.toDouble()
                                          : _additionalPaymentAmount.toDouble();
                                      additionalPaymentMethodForReceipt =
                                          _additionalPaymentMethod == 0
                                          ? 'QRIS'
                                          : 'Cash';
                                    }
                                  }

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
                                    voucherCode: voucherCode,
                                    voucherAmount: voucherAmountForReceipt,
                                    additionalPayment:
                                        additionalPaymentForReceipt,
                                    additionalPaymentMethod:
                                        additionalPaymentMethodForReceipt,
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

  // Static voucher verification (will be replaced with API call later)
  void _verifyVoucher() {
    if (_voucherCodeController.text.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Masukkan kode voucher terlebih dahulu!',
        type: SnackbarType.warning,
      );
      return;
    }

    if (_voucherAmount <= 0) {
      CustomSnackbar.show(
        context,
        message: 'Masukkan nominal voucher!',
        type: SnackbarType.warning,
      );
      return;
    }

    // TODO: Replace with actual API validation
    // For now, static validation - any code with minimum 4 characters is valid
    if (_voucherCodeController.text.length >= 4) {
      setState(() {
        _isVoucherVerified = true;
        _voucherCode = _voucherCodeController.text.toUpperCase();
      });
      CustomSnackbar.show(
        context,
        message: 'Voucher berhasil diverifikasi!',
        type: SnackbarType.success,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: 'Kode voucher tidak valid!',
        type: SnackbarType.error,
      );
    }
  }

  void _resetVoucher() {
    setState(() {
      _isVoucherVerified = false;
      _voucherCode = '';
      _voucherAmount = 0;
      _voucherCodeController.clear();
      _voucherAmountController.clear();
      // Reset additional payment
      _additionalPaymentMethod = -1;
      _additionalPaymentAmount = 0;
      _additionalPaymentController.clear();
    });
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

// Additional payment card for voucher shortfall
class _AdditionalPaymentCard extends StatelessWidget {
  const _AdditionalPaymentCard({
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF2196F3) : Colors.grey,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
