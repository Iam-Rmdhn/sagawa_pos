import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_configuration.dart';

class ReceiptPreview extends StatefulWidget {
  final Receipt receipt;

  const ReceiptPreview({super.key, required this.receipt});

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

    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child:
                _config!.logoPath.isNotEmpty &&
                    File(_config!.logoPath).existsSync()
                ? Image.file(
                    File(_config!.logoPath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.store,
                        size: 60,
                        color: Color(0xFFFF4B4B),
                      );
                    },
                  )
                : Image.asset(
                    AppImages.appLogo,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.store,
                        size: 60,
                        color: Color(0xFFFF4B4B),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

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

          // Items List - Format: "Nasi Goreng x3" dan "Rp 20,000    Rp 60,000"
          ...receipt.groupedItems.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name with quantity: "Nasi Goreng x3" (Bold)
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
                  // Price per unit and subtotal: "Rp 20,000    Rp 60,000"
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
          _buildDetailRow('Pajak', currencyFormat.format(receipt.tax)),
          const SizedBox(height: 8),

          // Divider
          const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 8),

          // Total (Center, Bold, Large)
          Center(
            child: Column(
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(receipt.afterTax),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Divider
          const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 8),

          // Payment info
          Text(
            'Tipe: ${receipt.type}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Pembayaran: ${receipt.paymentMethod}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          _buildDetailRow('Dibayar', currencyFormat.format(receipt.cash)),
          _buildDetailRow('Kembali', currencyFormat.format(receipt.change)),
          const SizedBox(height: 16),

          // Date and Transaction ID
          Text(
            'Tanggal: ${dateFormat.format(receipt.date)}',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 4),

          // Transaction details
          Text(
            'No: ${receipt.trxId}',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 16),

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
