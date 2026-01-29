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

    // Receipt content column
    final receiptContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Store Name
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

        // Address
        Text(
          _config!.outletAddress,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),

        // Phone Number
        if (_config!.phoneNumber.isNotEmpty)
          Text(
            _config!.phoneNumber,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),

        // Type
        Text(
          receipt.type,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        // Divider
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        // Transaction Details
        _buildDetailRow('Trx ID', receipt.trxId),
        _buildDetailRow('Cashier', receipt.cashier),
        _buildDetailRow('Customer Name', receipt.customerName),
        const SizedBox(height: 8),

        // Divider
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

        // Catatan setelah list menu
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

        // Divider
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        // ============== TOTALS STRUCTURE ==============

        // 1. lian (total dari semua harga menu)
        _buildDetailRow(
          'Total Pembelian',
          currencyFormat.format(receipt.totalPembelian),
        ),

        // Divider
        const SizedBox(height: 4),
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 4),

        // 2. Voucher atau Discount (jika ada)
        if (receipt.isVoucherPayment && receipt.voucherAmount != null) ...[
          // Voucher
          _buildDetailRow(
            'Voucher',
            '-${currencyFormat.format(receipt.voucherAmount!)}',
            isNegative: true,
          ),

          // 3. Sub total (Total Pembelian - Voucher)
          _buildDetailRow(
            'Sub total',
            currencyFormat.format(receipt.totalSetelahPotongan),
          ),
        ] else if (receipt.isDiscountPayment &&
            receipt.discountAmount != null) ...[
          // Discount
          _buildDetailRow(
            'Discount ${receipt.discountPercent ?? 0}%',
            '-${currencyFormat.format(receipt.discountAmount!)}',
            isNegative: true,
          ),

          // 3. Sub total (Total Pembelian - Discount)
          _buildDetailRow(
            'Sub total',
            currencyFormat.format(receipt.totalSetelahPotongan),
          ),
        ] else ...[
          // Jika tidak ada potongan, Sub total sama dengan Total Pembelian
          // Opsional: bisa ditampilkan ulang atau skip.
          // Sesuai request alur, langkah 4 "Sub total" selalu ada setelah langkah 2.
          // Jika tidak ada voucher, maka Sub total = Total Pembelian.
          _buildDetailRow(
            'Sub total',
            currencyFormat.format(receipt.totalPembelian),
          ),
        ],

        const SizedBox(height: 4),

        // 5. Tax 10% (dihitung dari Sub total)
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

        // 6. Label "After Tax"
        const Text(
          'After Tax',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        // 7. Total (Sub total + Tax)
        _buildDetailRow(
          'Total',
          currencyFormat.format(receipt.subTotalFinal),
          isBold: true,
        ),

        const SizedBox(
          height: 16,
        ), // Jarak ke detail pembayaran lebih besar tanpa divider
        // 6. Type
        _buildDetailRow('Type : ${receipt.type}', ''),

        // 8. Paid
        // Logic: Jika QRIS, Paid = Total. Jika Cash, Paid = amountPaid.
        if (!receipt.isFreeTransaction)
          _buildDetailRow(
            'Paid',
            currencyFormat.format(
              receipt.paymentMethodDisplay.contains('QRIS')
                  ? receipt.subTotalFinal
                  : receipt.amountPaid,
            ),
          ),

        // 9. Payment
        _buildDetailRow('Payment : ${receipt.paymentMethodDisplay}', ''),

        // 10. Change - Tampilkan jika ada kembalian
        if (!receipt.isFreeTransaction && receipt.hasChange)
          _buildDetailRow(
            'Change',
            currencyFormat.format(receipt.calculatedChange),
          ),

        const SizedBox(height: 16),

        // ============== DIVIDER BEFORE DATE ==============
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 12),

        // Date
        Center(
          child: Text(
            'Date: ${dateFormat.format(receipt.date)}',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 12),

        // Footer
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

    // If in bottom sheet mode, return just the content
    if (widget.isBottomSheet) {
      return receiptContent;
    }

    // Dialog mode - wrap with container and scroll
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
