import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos/features/receipt/presentation/bloc/receipt_cubit.dart';
import 'package:sagawa_pos/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:sagawa_pos/features/receipt/presentation/widgets/receipt_preview.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderHistory order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late ReceiptCubit _receiptCubit;

  @override
  void initState() {
    super.initState();
    _receiptCubit = ReceiptCubit();
  }

  @override
  void dispose() {
    _receiptCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _receiptCubit,
      child: BlocListener<ReceiptCubit, ReceiptState>(
        listener: (context, state) {
          if (state is ReceiptError) {
            CustomSnackbar.show(
              context,
              message: state.message,
              type: SnackbarType.error,
            );
          } else if (state is ReceiptDownloaded) {
            CustomSnackbar.show(
              context,
              message: 'PDF berhasil diunduh ke: ${state.filePath}',
              type: SnackbarType.success,
              duration: const Duration(seconds: 4),
            );
          } else if (state is ReceiptPrinted) {
            CustomSnackbar.show(
              context,
              message: state.message,
              type: SnackbarType.success,
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: const Color(0xFFFF4B4B),
              elevation: 0,
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Detail Pesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: SvgPicture.asset(
                    AppImages.printIcon,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 8,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Preview Struk',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  child: ReceiptPreview(
                                    receipt: widget.order.receipt,
                                    isBottomSheet: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(66, 64, 224, 32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(255, 35, 244, 84),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.invoiceIcon,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ID Transaksi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.order.trxId,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppImages.calenderIcon,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF757575),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.order.formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const _SectionTitle(title: 'Informasi Pesanan'),
                const SizedBox(height: 12),
                _InfoRow(label: 'Kasir', value: widget.order.receipt.cashier),
                _InfoRow(
                  label: 'Pelanggan',
                  value: widget.order.receipt.customerName,
                ),
                _InfoRow(label: 'Tipe', value: widget.order.receipt.type),
                _InfoRow(
                  label: 'Metode Pembayaran',
                  value: widget.order.receipt.paymentMethodDisplay,
                ),

                const SizedBox(height: 24),

                const _SectionTitle(title: 'Item Pesanan'),
                const SizedBox(height: 12),
                ...widget.order.receipt.groupedItems.map(
                  (item) => _ItemRow(
                    name: item.name,
                    quantity: item.quantity,
                    price: item.price,
                    subtotal: item.subtotal,
                  ),
                ),

                const SizedBox(height: 24),

                const _SectionTitle(title: 'Ringkasan Pembayaran'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _PaymentRow(
                        label: 'Total Pembelian',
                        value: _formatCurrency(
                          widget.order.receipt.totalPembelian,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      if (widget.order.receipt.isVoucherPayment &&
                          (widget.order.receipt.totalPotongan > 0 ||
                              (widget.order.receipt.voucherAmount != null &&
                                  widget.order.receipt.voucherAmount! >
                                      0))) ...[
                        _PaymentRow(
                          label: widget.order.receipt.voucherCode != null
                              ? 'Voucher (${widget.order.receipt.voucherCode})'
                              : 'Voucher',
                          value:
                              '-${_formatCurrency(widget.order.receipt.totalPotongan > 0 ? widget.order.receipt.totalPotongan : widget.order.receipt.voucherAmount ?? 0)}',
                          valueColor: Colors.red.shade700,
                        ),

                        const SizedBox(height: 8),
                        _PaymentRow(
                          label: 'Sub total',
                          value: _formatCurrency(
                            widget.order.receipt.totalSetelahPotongan,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else if (widget.order.receipt.isDiscountPayment &&
                          (widget.order.receipt.totalPotongan > 0 ||
                              (widget.order.receipt.discountAmount != null &&
                                  widget.order.receipt.discountAmount! > 0) ||
                              (widget.order.receipt.discountPercent != null &&
                                  widget.order.receipt.discountPercent! >
                                      0))) ...[
                        _PaymentRow(
                          label:
                              'Discount ${widget.order.receipt.discountPercent ?? 0}%',
                          value:
                              '-${_formatCurrency(widget.order.receipt.totalPotongan > 0 ? widget.order.receipt.totalPotongan : widget.order.receipt.discountAmount ?? 0)}',
                          valueColor: Colors.red.shade700,
                        ),

                        const SizedBox(height: 8),
                        _PaymentRow(
                          label: 'Sub total',
                          value: _formatCurrency(
                            widget.order.receipt.totalSetelahPotongan,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        _PaymentRow(
                          label: 'Sub total',
                          value: _formatCurrency(
                            widget.order.receipt.totalPembelian,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (widget.order.receipt.tax > 0 ||
                          widget.order.receipt.calculatedTax > 0) ...[
                        _PaymentRow(
                          label: 'Tax 10%',
                          value: _formatCurrency(
                            widget.order.receipt.hasPotongan
                                ? widget.order.receipt.calculatedTax
                                : widget.order.receipt.tax,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 4),
                      _PaymentRow(
                        label: 'After Tax',
                        value: _formatCurrency(
                          widget.order.receipt.subTotalFinal,
                        ),
                        isBold: true,
                      ),
                      const SizedBox(height: 4),
                      const Divider(),
                      const SizedBox(height: 8),

                      _PaymentRow(
                        label: 'Type',
                        value: widget.order.receipt.type,
                      ),
                      const SizedBox(height: 8),

                      if (!widget.order.receipt.isFreeTransaction) ...[
                        _PaymentRow(
                          label: 'Paid',
                          value: _formatCurrency(
                            widget.order.receipt.paymentMethodDisplay.contains(
                                  'QRIS',
                                )
                                ? widget.order.receipt.subTotalFinal
                                : widget.order.receipt.amountPaid,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      _PaymentRow(
                        label: 'Payment',
                        value: widget.order.receipt.paymentMethodDisplay,
                      ),

                      if (!widget.order.receipt.isFreeTransaction &&
                          widget.order.receipt.hasChange) ...[
                        const SizedBox(height: 8),
                        _PaymentRow(
                          label: 'Change',
                          value: _formatCurrency(
                            widget.order.receipt.calculatedChange,
                          ),
                          valueColor: Colors.green.shade700,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                BlocBuilder<ReceiptCubit, ReceiptState>(
                  builder: (context, state) {
                    final isLoading =
                        state is ReceiptGenerating ||
                        state is ReceiptPrinting ||
                        state is ReceiptDownloading;

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await _receiptCubit.generateReceipt(
                                      widget.order.receipt,
                                    );
                                    if (mounted) {
                                      await _receiptCubit.printViaBluetooth();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4B4B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: state is ReceiptPrinting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.print),
                            label: Text(
                              state is ReceiptPrinting
                                  ? 'Mencetak...'
                                  : 'Print Struk',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await _receiptCubit.generateReceipt(
                                      widget.order.receipt,
                                    );
                                    if (mounted) {
                                      await _receiptCubit.downloadPdf();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFFF4B4B),
                              side: const BorderSide(
                                color: Color(0xFFFF4B4B),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: state is ReceiptDownloading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFF4B4B),
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(
                              state is ReceiptDownloading
                                  ? 'Mengunduh...'
                                  : 'Download PDF',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = amount.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return 'Rp ${parts.join('.')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  const _ItemRow({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${quantity}x ${_formatCurrency(price)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(subtotal),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = amount.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return 'Rp ${parts.join('.')}';
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : const Color(0xFF757575),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? Colors.black87 : Colors.black87),
          ),
        ),
      ],
    );
  }
}
