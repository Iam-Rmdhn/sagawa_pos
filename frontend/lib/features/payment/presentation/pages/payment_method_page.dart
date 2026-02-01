import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/core/network/api_config.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos/data/services/settings_service.dart';
import 'package:sagawa_pos/features/order/presentation/widgets/order_detail_app_bar.dart';
import 'package:sagawa_pos/features/receipt/receipt.dart';

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
  int _selectedOrderType = 0;
  int _selectedPaymentMethod = -1;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _voucherCodeController = TextEditingController();
  final TextEditingController _voucherAmountController =
      TextEditingController();
  final TextEditingController _voucherRedeemedByController =
      TextEditingController();
  final TextEditingController _additionalPaymentController =
      TextEditingController();
  final TextEditingController _discountCashController = TextEditingController();
  int _cashAmount = 0;
  int _voucherAmount = 0;
  bool _isVoucherVerified = false;
  bool _isVoucherUsed = false;
  String _voucherCode = '';
  bool _isTaxEnabled = false;
  int _taxAmount = 0;
  bool _isValidatingVoucher = false;
  bool _isUsingVoucher = false;

  int _additionalPaymentMethod = -1;
  int _additionalPaymentAmount = 0;

  int _selectedDiscountPercent = -1;
  int _discountCashAmount = 0;
  int _discountPaymentMethod = -1;
  final List<int> _discountOptions = [5, 10, 15, 20, 25, 30, 100];

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
    _voucherRedeemedByController.dispose();
    _additionalPaymentController.dispose();
    _discountCashController.dispose();
    super.dispose();
  }

  int get _discountAmount {
    if (_selectedDiscountPercent <= 0) return 0;

    return (widget.subtotal * _selectedDiscountPercent / 100).round();
  }

  int get _subtotalAfterDiscount {
    return widget.subtotal - _discountAmount;
  }

  int get _taxAfterDiscount {
    if (!_isTaxEnabled) return 0;

    return (_subtotalAfterDiscount * 0.1).round();
  }

  int get _totalAfterDiscount {
    return _subtotalAfterDiscount + _taxAfterDiscount;
  }

  bool get _voucherCoversEntireOrder {
    if (!_isVoucherVerified) return false;

    return _voucherAmount >= widget.subtotal;
  }

  bool get _voucherNeedsAdditionalPayment {
    if (!_isVoucherVerified) return false;

    return _voucherAmount < widget.subtotal;
  }

  int get _totalAfterVoucher {
    if (!_isVoucherVerified) return widget.subtotal + _taxAmount;

    if (_voucherAmount >= widget.subtotal) return 0;

    final subtotalAfterVoucher = widget.subtotal - _voucherAmount;
    final taxAfterVoucher = _isTaxEnabled
        ? (subtotalAfterVoucher * 0.1).round()
        : 0;
    return subtotalAfterVoucher + taxAfterVoucher;
  }

  int get _voucherShortfall {
    if (_voucherAmount >= widget.subtotal) return 0;

    return _totalAfterVoucher;
  }

  int get _taxAfterVoucher {
    if (!_isVoucherVerified || !_isTaxEnabled) return _taxAmount;

    if (_voucherAmount >= widget.subtotal) return 0;

    final subtotalAfterVoucher = widget.subtotal - _voucherAmount;
    return (subtotalAfterVoucher * 0.1).round();
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

                      Text(
                        'Pilih metode pembayaran:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                                  _selectedDiscountPercent = -1;
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
                                  _selectedDiscountPercent = -1;
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
                                  _selectedDiscountPercent = -1;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: AppImages.discontIcon,
                              label: 'Discount',
                              isSelected: _selectedPaymentMethod == 3,
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 3;
                                  _isVoucherVerified = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_selectedPaymentMethod == 3) ...[
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
                                'Pilih Persentase Diskon',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _discountOptions.map((percent) {
                                    final isSelected =
                                        _selectedDiscountPercent == percent;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: percent != _discountOptions.last
                                            ? 8
                                            : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDiscountPercent = percent;
                                            _discountCashAmount = 0;
                                            _discountCashController.clear();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFFF4B4B)
                                                : const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFFFF4B4B)
                                                  : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            '$percent%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              if (_selectedDiscountPercent > 0) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF4B4B,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF4B4B,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Diskon $_selectedDiscountPercent%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFFF4B4B),
                                            ),
                                          ),
                                          Text(
                                            '- ${_formatCurrency(_discountAmount)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFFF4B4B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Subtotal Setelah Diskon',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(
                                              _subtotalAfterDiscount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_isTaxEnabled) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'PB1 10%',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              _formatCurrency(
                                                _taxAfterDiscount,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total Setelah Diskon',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(
                                              _totalAfterDiscount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                if (_selectedDiscountPercent < 100) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Pilih Metode Pembayaran Tambahan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _discountPaymentMethod = 0;
                                              _discountCashAmount = 0;
                                              _discountCashController.clear();
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _discountPaymentMethod == 0
                                                  ? const Color(0xFFFF4B4B)
                                                  : const Color(0xFFF5F5F5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    _discountPaymentMethod == 0
                                                    ? const Color(0xFFFF4B4B)
                                                    : Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SvgPicture.asset(
                                                  AppImages.qrisIcon,
                                                  width: 24,
                                                  height: 24,
                                                  colorFilter:
                                                      _discountPaymentMethod ==
                                                          0
                                                      ? const ColorFilter.mode(
                                                          Colors.white,
                                                          BlendMode.srcIn,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'QRIS',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _discountPaymentMethod ==
                                                            0
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _discountPaymentMethod = 1;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _discountPaymentMethod == 1
                                                  ? const Color(0xFFFF4B4B)
                                                  : const Color(0xFFF5F5F5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    _discountPaymentMethod == 1
                                                    ? const Color(0xFFFF4B4B)
                                                    : Colors.grey.shade300,
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SvgPicture.asset(
                                                  AppImages.cashIcon,
                                                  width: 24,
                                                  height: 24,
                                                  colorFilter:
                                                      _discountPaymentMethod ==
                                                          1
                                                      ? const ColorFilter.mode(
                                                          Colors.white,
                                                          BlendMode.srcIn,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Cash',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _discountPaymentMethod ==
                                                            1
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_discountPaymentMethod == 1) ...[
                                    const SizedBox(height: 16),
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
                                      controller: _discountCashController,
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                        final numericValue = value.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        );

                                        if (numericValue.isEmpty) {
                                          setState(() {
                                            _discountCashAmount = 0;
                                            _discountCashController.clear();
                                          });
                                          return;
                                        }

                                        final amount = int.parse(numericValue);
                                        final formatted = _formatCurrencyInput(
                                          amount,
                                        );

                                        _discountCashController
                                            .value = TextEditingValue(
                                          text: formatted,
                                          selection: TextSelection.collapsed(
                                            offset: formatted.length,
                                          ),
                                        );

                                        setState(() {
                                          _discountCashAmount = amount;
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],

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

                                  final amount = int.parse(numericValue);

                                  final formatted = _formatCurrencyInput(
                                    amount,
                                  );

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
                                textCapitalization: TextCapitalization.words,
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

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isVoucherVerified
                                      ? _resetVoucher
                                      : (_isValidatingVoucher
                                            ? null
                                            : _verifyVoucher),
                                  icon: _isValidatingVoucher
                                      ? const SizedBox()
                                      : Icon(
                                          _isVoucherVerified
                                              ? Icons.refresh
                                              : Icons.verified_outlined,
                                          size: 20,
                                        ),
                                  label: _isValidatingVoucher
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
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

                              if (_isVoucherVerified) ...[
                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Voucher Terverifikasi',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Nominal: ${_formatCurrency(_voucherAmount)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Text(
                                  'Nama Pemakai Voucher (Opsional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _voucherRedeemedByController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    hintText: 'Contoh: John Doe',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF2196F3),
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
                                        color: Color(0xFF2196F3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                  enabled: !_isVoucherUsed,
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        (_isVoucherUsed || _isUsingVoucher)
                                        ? null
                                        : _useVoucher,
                                    icon: _isUsingVoucher
                                        ? const SizedBox()
                                        : Icon(
                                            _isVoucherUsed
                                                ? Icons.check_circle
                                                : Icons.redeem,
                                            size: 20,
                                          ),
                                    label: _isUsingVoucher
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            _isVoucherUsed
                                                ? 'Voucher Sudah Digunakan'
                                                : 'Gunakan Voucher',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isVoucherUsed
                                          ? Colors.grey
                                          : Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],

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

                      if (_selectedPaymentMethod == 2 &&
                          _isVoucherVerified) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Voucher',

                          value:
                              '- ${_formatCurrency(_voucherAmount > widget.subtotal ? widget.subtotal : _voucherAmount)}',
                          isDiscount: true,
                        ),

                        if (_voucherAmount < widget.subtotal) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Subtotal Setelah Voucher',
                            value: _formatCurrency(
                              widget.subtotal - _voucherAmount,
                            ),
                          ),
                        ],

                        if (_isTaxEnabled &&
                            _voucherAmount < widget.subtotal) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'PB1 10%',
                            value: _formatCurrency(_taxAfterVoucher),
                          ),
                        ],
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
                        ] else if (_voucherCoversEntireOrder) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Changes',
                            value: _formatCurrency(0),
                            isChange: true,
                          ),
                        ],
                      ],

                      if (_selectedPaymentMethod == 3 &&
                          _selectedDiscountPercent > 0) ...[
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Diskon $_selectedDiscountPercent%',
                          value: '- ${_formatCurrency(_discountAmount)}',
                          isDiscount: true,
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Subtotal Setelah Diskon',
                          value: _formatCurrency(_subtotalAfterDiscount),
                        ),
                        if (_isTaxEnabled) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'PB1 10% (setelah diskon)',
                            value: _formatCurrency(_taxAfterDiscount),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Total Setelah Diskon',
                          value: _formatCurrency(_totalAfterDiscount),
                        ),
                        if (_discountCashAmount > 0) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Cash',
                            value: _formatCurrency(_discountCashAmount),
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Changes',
                            value: _formatCurrency(
                              _discountCashAmount > _totalAfterDiscount
                                  ? _discountCashAmount - _totalAfterDiscount
                                  : 0,
                            ),
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
                            _selectedPaymentMethod == 2 && _isVoucherVerified
                                ? _formatCurrency(
                                    _voucherCoversEntireOrder
                                        ? 0
                                        : _totalAfterVoucher,
                                  )
                                : (_selectedPaymentMethod == 3 &&
                                          _selectedDiscountPercent > 0
                                      ? _formatCurrency(_totalAfterDiscount)
                                      : _formatCurrency(total)),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _selectedPaymentMethod == -1
                              ? null
                              : () async {
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

                                  if (_selectedPaymentMethod == 3) {
                                    if (_selectedDiscountPercent == 0) {
                                      CustomSnackbar.show(
                                        context,
                                        message:
                                            'Pilih persentase diskon terlebih dahulu!',
                                        type: SnackbarType.warning,
                                      );
                                      return;
                                    }

                                    if (_selectedDiscountPercent < 100) {
                                      if (_discountPaymentMethod == -1) {
                                        CustomSnackbar.show(
                                          context,
                                          message:
                                              'Pilih metode pembayaran untuk sisa tagihan!',
                                          type: SnackbarType.warning,
                                        );
                                        return;
                                      }

                                      if (_discountPaymentMethod == 1 &&
                                          _discountCashAmount <
                                              _totalAfterDiscount) {
                                        CustomSnackbar.show(
                                          context,
                                          message:
                                              'Nominal cash kurang! Minimal ${_formatCurrency(_totalAfterDiscount)}',
                                          type: SnackbarType.warning,
                                        );
                                        return;
                                      }
                                    }
                                  }

                                  final orderType = _selectedOrderType == 0
                                      ? 'Dine In'
                                      : 'Take Away';

                                  String paymentMethod;
                                  if (_selectedPaymentMethod == 0) {
                                    paymentMethod = 'QRIS';
                                  } else if (_selectedPaymentMethod == 1) {
                                    paymentMethod = 'Cash';
                                  } else if (_selectedPaymentMethod == 3) {
                                    if (_selectedDiscountPercent == 100) {
                                      paymentMethod = 'Discount 100%';
                                    } else {
                                      paymentMethod =
                                          _discountPaymentMethod == 0
                                          ? 'Discount + QRIS'
                                          : 'Discount + Cash';
                                    }
                                  } else {
                                    if (_voucherNeedsAdditionalPayment) {
                                      paymentMethod =
                                          _additionalPaymentMethod == 0
                                          ? 'Voucher + QRIS'
                                          : 'Voucher + Cash';
                                    } else {
                                      paymentMethod = 'Voucher';
                                    }
                                  }

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
                                  } else if (_selectedPaymentMethod == 3) {
                                    if (_selectedDiscountPercent == 100) {
                                      cashAmount = 0.0;
                                    } else if (_discountPaymentMethod == 0) {
                                      cashAmount = _totalAfterDiscount
                                          .toDouble();
                                    } else {
                                      cashAmount = _discountCashAmount
                                          .toDouble();
                                    }
                                  } else {
                                    if (_voucherNeedsAdditionalPayment) {
                                      cashAmount = _additionalPaymentMethod == 0
                                          ? _voucherShortfall.toDouble()
                                          : _additionalPaymentAmount.toDouble();
                                    } else {
                                      cashAmount = 0.0;
                                    }
                                  }

                                  int? discountPercentForReceipt;
                                  double? discountAmountForReceipt;
                                  if (_selectedPaymentMethod == 3 &&
                                      _selectedDiscountPercent > 0) {
                                    discountPercentForReceipt =
                                        _selectedDiscountPercent;
                                    discountAmountForReceipt = _discountAmount
                                        .toDouble();
                                  }

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
                                    discountPercent: discountPercentForReceipt,
                                    discountAmount: discountAmountForReceipt,
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

  Future<void> _verifyVoucher() async {
    if (_voucherCodeController.text.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Masukkan kode voucher terlebih dahulu!',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _isValidatingVoucher = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/vouchers/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code_voucher': _voucherCodeController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _isVoucherVerified = true;
          _isVoucherUsed = false;
          _voucherCode = data['code_voucher'];
          _voucherAmount = data['nominal'];
          _voucherAmountController.text = _formatCurrencyInput(_voucherAmount);
        });
        CustomSnackbar.show(
          context,
          message: data['message'] ?? 'Voucher berhasil diverifikasi!',
          type: SnackbarType.success,
        );
      } else {
        CustomSnackbar.show(
          context,
          message: data['message'] ?? 'Voucher tidak valid',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        message: 'Gagal memverifikasi voucher: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isValidatingVoucher = false);
    }
  }

  Future<void> _useVoucher() async {
    if (!_isVoucherVerified) {
      CustomSnackbar.show(
        context,
        message: 'Verifikasi voucher terlebih dahulu!',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _isUsingVoucher = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/vouchers/use'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code_voucher': _voucherCode,
          'redeemed_by': _voucherRedeemedByController.text.trim().isEmpty
              ? null
              : _voucherRedeemedByController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _isVoucherUsed = true;
        });
        CustomSnackbar.show(
          context,
          message: data['message'] ?? 'Voucher berhasil digunakan!',
          type: SnackbarType.success,
        );
      } else {
        CustomSnackbar.show(
          context,
          message: data['message'] ?? 'Gagal menggunakan voucher',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        message: 'Gagal menggunakan voucher: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isUsingVoucher = false);
    }
  }

  void _resetVoucher() {
    setState(() {
      _isVoucherVerified = false;
      _isVoucherUsed = false;
      _voucherCode = '';
      _voucherAmount = 0;
      _voucherCodeController.clear();
      _voucherAmountController.clear();
      _voucherRedeemedByController.clear();

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
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              placeholderBuilder: (BuildContext context) => Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.8),
                ),
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
    this.isDiscount = false,
  });

  final String label;
  final String value;
  final bool isChange;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = isChange || isDiscount;
    final Color highlightColor = isDiscount
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF4B4B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isHighlighted ? highlightColor : const Color(0xFF757575),
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? highlightColor : const Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}

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
