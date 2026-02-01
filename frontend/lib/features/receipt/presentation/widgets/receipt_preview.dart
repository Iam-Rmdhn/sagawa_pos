import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/domain/models/printer_configuration.dart';

class ReceiptPreview extends StatefulWidget {
  final Receipt receipt;
  final bool isBottomSheet;

  const ReceiptPreview({
    super.key,
    required this.receipt,
    this.isBottomSheet = false,
  });

  @override
  State<ReceiptPreview> createState() => _ReceiptPreviewState();
}

class _ReceiptPreviewState extends State<ReceiptPreview> {
  PrinterConfiguration? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await PrinterConfiguration.load();
      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _config = PrinterConfiguration.defaults();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final receipt = widget.receipt;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final receiptContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _config!.restaurantName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        Text(
          _config!.outletAddress,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),

        if (_config!.phoneNumber.isNotEmpty)
          Text(
            _config!.phoneNumber,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),

        Text(
          receipt.type,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        _buildDetailRow('Trx ID', receipt.trxId),
        _buildDetailRow('Cashier', receipt.cashier),
        _buildDetailRow('Customer Name', receipt.customerName),
        const SizedBox(height: 8),

        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 12),

        ...receipt.groupedItems.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.quantity > 1
                      ? '${item.name} x${item.quantity}'
                      : item.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(item.price),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.subtotal),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  receipt.notes!,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        _buildDetailRow(
          'Total Pembelian',
          currencyFormat.format(receipt.totalPembelian),
        ),

        const SizedBox(height: 4),
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 4),

        if (receipt.isVoucherPayment && receipt.voucherAmount != null) ...[
          _buildDetailRow(
            'Voucher',
            '-${currencyFormat.format(receipt.voucherAmount!)}',
            isNegative: true,
          ),

          _buildDetailRow(
            'Sub total',
            currencyFormat.format(receipt.totalSetelahPotongan),
          ),
        ] else if (receipt.isDiscountPayment &&
            receipt.discountAmount != null) ...[
          _buildDetailRow(
            'Discount ${receipt.discountPercent ?? 0}%',
            '-${currencyFormat.format(receipt.discountAmount!)}',
            isNegative: true,
          ),

          _buildDetailRow(
            'Sub total',
            currencyFormat.format(receipt.totalSetelahPotongan),
          ),
        ] else ...[
          _buildDetailRow(
            'Sub total',
            currencyFormat.format(receipt.totalPembelian),
          ),
        ],

        const SizedBox(height: 4),

        if (receipt.tax > 0 || receipt.calculatedTax > 0)
          _buildDetailRow(
            'Tax 10%',
            currencyFormat.format(
              receipt.hasPotongan ? receipt.calculatedTax : receipt.tax,
            ),
          ),

        const SizedBox(height: 4),
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 4),

        const Text(
          'After Tax',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        _buildDetailRow(
          'Total',
          currencyFormat.format(receipt.subTotalFinal),
          isBold: true,
        ),

        const SizedBox(height: 16),

        _buildDetailRow('Type : ${receipt.type}', ''),

        if (!receipt.isFreeTransaction)
          _buildDetailRow(
            'Paid',
            currencyFormat.format(
              receipt.paymentMethodDisplay.contains('QRIS')
                  ? receipt.subTotalFinal
                  : receipt.amountPaid,
            ),
          ),

        _buildDetailRow('Payment : ${receipt.paymentMethodDisplay}', ''),

        if (!receipt.isFreeTransaction && receipt.hasChange)
          _buildDetailRow(
            'Change',
            currencyFormat.format(receipt.calculatedChange),
          ),

        const SizedBox(height: 16),

        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 12),

        Center(
          child: Text(
            'Date: ${dateFormat.format(receipt.date)}',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 12),

        const Center(
          child: Text(
            'Terima Kasih Atas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const Center(
          child: Text(
            'Kunjungan Anda',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );

    if (widget.isBottomSheet) {
      return receiptContent;
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: receiptContent,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isBold = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              color: isNegative ? Colors.red.shade700 : Colors.black87,
              fontWeight: isBold || isNegative
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
