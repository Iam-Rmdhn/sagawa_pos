import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_configuration.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_settings.dart';
import 'package:sagawa_pos_new/features/receipt/domain/services/bluetooth_printer_service.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/bloc/receipt_state.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptCubit extends Cubit<ReceiptState> {
  ReceiptCubit() : super(ReceiptInitial());

  File? _pdfFile;
  Receipt? _currentReceipt;
  final BluetoothPrinterService _bluetoothService = BluetoothPrinterService();

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> generateReceipt(Receipt receipt) async {
    try {
      emit(ReceiptGenerating());

      _currentReceipt = receipt;

      // Load printer configuration
      final config = await PrinterConfiguration.load();

      final pdf = pw.Document();

      // Load logo
      pw.ImageProvider? logoImage;
      try {
        final logoData = await rootBundle.load('assets/logo/logo_pos.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        print('Logo not found: $e');
      }

      // Build PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 5 * PdfPageFormat.mm,
          ),
          build: (context) => _buildReceiptContent(receipt, logoImage, config),
        ),
      );

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/receipt_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      _pdfFile = file;
      emit(ReceiptGenerated(pdfFile: file, filePath: file.path));
    } catch (e) {
      emit(ReceiptError(message: 'Gagal membuat struk: $e'));
    }
  }

  pw.Widget _buildReceiptContent(
    Receipt receipt,
    pw.ImageProvider? logo,
    PrinterConfiguration config,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            config.restaurantName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            config.outletAddress,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        if (config.phoneNumber.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              config.phoneNumber,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
        pw.SizedBox(height: 8),

        // Receipt info (Left aligned)
        pw.Text(
          'Trx ID: ${receipt.trxId}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Date: ${dateFormat.format(receipt.date)}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Cashier: ${receipt.cashier}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        if (receipt.customerName.isNotEmpty)
          pw.Text(
            'Customer: ${receipt.customerName}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        pw.SizedBox(height: 8),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),

        ...receipt.groupedItems.map(
          (item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.quantity > 1
                      ? '${item.name} x${item.quantity}'
                      : item.name,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      currencyFormat.format(item.price),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      currencyFormat.format(item.subtotal),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 8),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              currencyFormat.format(receipt.subTotal),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tax:', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              currencyFormat.format(receipt.tax),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),

        // Total (Horizontal, Bold)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              currencyFormat.format(receipt.afterTax),
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Divider
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),

        // Payment info
        pw.Text(
          'Type: ${receipt.type}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Payment: ${receipt.paymentMethod}',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Paid:', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              currencyFormat.format(receipt.cash),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Change:', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              currencyFormat.format(receipt.change),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 16),

        // Footer (Center, Bold)
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Terima Kasih',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Atas Kunjungan Anda',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> printReceipt() async {
    try {
      if (_pdfFile == null) {
        emit(ReceiptError(message: 'PDF belum di-generate'));
        return;
      }

      emit(ReceiptPrinting());

      // Try to print using system print dialog
      final pdfBytes = await _pdfFile!.readAsBytes();

      try {
        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
        emit(ReceiptPrinted(message: 'Struk berhasil dicetak'));
      } catch (printError) {
        // Fallback: Share PDF if printing not supported
        await Printing.sharePdf(bytes: pdfBytes, filename: 'receipt.pdf');
        emit(ReceiptPrinted(message: 'Struk siap untuk dicetak/dibagikan'));
      }
    } catch (e) {
      emit(ReceiptError(message: 'Gagal mencetak struk: $e'));
    }
  }

  Future<void> shareReceipt() async {
    try {
      if (_pdfFile == null) {
        emit(ReceiptError(message: 'PDF belum di-generate'));
        return;
      }

      emit(ReceiptSharing());

      // Share PDF file
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        subject: 'Struk Transaksi',
        text: 'Berikut adalah struk transaksi Anda',
      );

      emit(ReceiptShared(message: 'Struk berhasil dibagikan'));
    } catch (e) {
      emit(ReceiptError(message: 'Gagal membagikan struk: $e'));
    }
  }

  // Bluetooth Printer Methods
  Future<List<BluetoothDevice>> getBluetoothDevices() async {
    try {
      return await _bluetoothService.getDevices();
    } catch (e) {
      print('Error getting bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> connectBluetoothPrinter(BluetoothDevice device) async {
    try {
      return await _bluetoothService.connect(device);
    } catch (e) {
      print('Error connecting to bluetooth: $e');
      return false;
    }
  }

  Future<bool> connectBluetoothByAddress(String macAddress) async {
    try {
      return await _bluetoothService.connectByAddress(macAddress);
    } catch (e) {
      print('Error connecting by address: $e');
      return false;
    }
  }

  Future<void> disconnectBluetooth() async {
    try {
      await _bluetoothService.disconnect();
    } catch (e) {
      print('Error disconnecting bluetooth: $e');
    }
  }

  Future<bool> isBluetoothConnected() async {
    try {
      return await _bluetoothService.isConnected();
    } catch (e) {
      print('Error checking bluetooth connection: $e');
      return false;
    }
  }

  Future<void> printViaBluetooth() async {
    try {
      if (_currentReceipt == null) {
        emit(ReceiptError(message: 'Data struk tidak tersedia'));
        return;
      }

      emit(ReceiptPrinting());

      // Load printer configuration
      final config = await PrinterConfiguration.load();

      // Check if bluetooth address is configured
      if (config.bluetoothAddress.isEmpty) {
        emit(
          ReceiptError(
            message:
                'Printer belum dikonfigurasi. Silakan atur di Settings → Konfigurasi Printer',
          ),
        );
        return;
      }

      // Check if already connected
      bool connected = await _bluetoothService.isConnected();

      // If not connected, try to connect using configured address
      if (!connected) {
        connected = await _bluetoothService.connectByAddress(
          config.bluetoothAddress,
        );

        if (!connected) {
          emit(
            ReceiptError(
              message:
                  'Gagal terhubung ke printer ${config.bluetoothDeviceName}. Pastikan printer sudah menyala dan Bluetooth aktif.',
            ),
          );
          return;
        }
      }

      // Load printer settings
      final settings = await PrinterSettings.load();

      final success = await _bluetoothService.printReceipt(
        _currentReceipt!,
        settings,
      );

      if (success) {
        emit(ReceiptPrinted(message: 'Struk berhasil dicetak via Bluetooth'));
        // Auto disconnect setelah print berhasil
        await Future.delayed(const Duration(milliseconds: 500));
        await _bluetoothService.disconnect();
      } else {
        emit(ReceiptError(message: 'Gagal mencetak struk via Bluetooth'));
      }
    } catch (e) {
      emit(ReceiptError(message: 'Error Bluetooth printing: $e'));
      // Disconnect jika terjadi error
      try {
        await _bluetoothService.disconnect();
      } catch (_) {}
    }
  }

  Future<bool> printTestPage() async {
    try {
      final connected = await _bluetoothService.isConnected();
      if (!connected) {
        emit(ReceiptError(message: 'Printer Bluetooth tidak terhubung'));
        return false;
      }

      // Load printer settings
      final settings = await PrinterSettings.load();

      final success = await _bluetoothService.printTestPage(settings);

      if (success) {
        emit(ReceiptPrinted(message: 'Test print berhasil'));
        // Auto disconnect setelah test print
        await Future.delayed(const Duration(milliseconds: 500));
        await _bluetoothService.disconnect();
      } else {
        emit(ReceiptError(message: 'Test print gagal'));
      }

      return success;
    } catch (e) {
      emit(ReceiptError(message: 'Error test print: $e'));
      // Disconnect jika terjadi error
      try {
        await _bluetoothService.disconnect();
      } catch (_) {}
      return false;
    }
  }

  void reset() {
    _pdfFile = null;
    _currentReceipt = null;
    emit(ReceiptInitial());
  }
}
