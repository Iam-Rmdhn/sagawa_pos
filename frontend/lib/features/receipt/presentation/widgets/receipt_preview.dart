import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_configuration.dart';

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

        // Divider
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        // Totals
        _buildDetailRow('Subtotal', currencyFormat.format(receipt.subTotal)),
        _buildDetailRow('PB1', currencyFormat.format(receipt.tax)),
        const SizedBox(height: 8),

        // Divider
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              currencyFormat.format(receipt.afterTax),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Divider
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 8),

        const SizedBox(height: 4),
        // Payment method display
        if (receipt.isVoucherPayment) ...[
          // Voucher payment section
          Text(
            'Payment: Voucher',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          _buildDetailRow('Kode Voucher', receipt.voucherCode ?? '-'),
          _buildDetailRow(
            'Nominal Voucher',
            currencyFormat.format(receipt.voucherAmount ?? 0),
          ),
          if (receipt.hasAdditionalPayment) ...[
            const SizedBox(height: 4),
            _buildDetailRow(
              'Tambahan ${receipt.additionalPaymentMethod ?? ''}',
              currencyFormat.format(receipt.additionalPayment ?? 0),
            ),
          ],
          const SizedBox(height: 4),
          _buildDetailRow('Change', currencyFormat.format(receipt.change)),
        ] else ...[
          // Regular payment (Cash/QRIS)
          Text(
            'Payment: ${receipt.paymentMethod}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          _buildDetailRow('Paid', currencyFormat.format(receipt.cash)),
          _buildDetailRow('Change', currencyFormat.format(receipt.change)),
        ],
        const SizedBox(height: 16),

        // Date and Transaction ID
        Text(
          'Date: ${dateFormat.format(receipt.date)}',
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        const SizedBox(height: 4),

        // Footer
        const Text(
          'Terima Kasih',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
