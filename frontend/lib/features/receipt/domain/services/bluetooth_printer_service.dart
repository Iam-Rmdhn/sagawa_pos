import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_settings.dart';

class BluetoothPrinterService {
  BluetoothConnection? _connection;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // ESC/POS Commands
  static const ESC = 0x1B;
  static const GS = 0x1D;

  /// Get list of bonded/paired Bluetooth devices
  Future<List<BluetoothDevice>> getDevices() async {
    try {
      final bondedDevices = await FlutterBluetoothSerial.instance
          .getBondedDevices();
      return bondedDevices;
    } catch (e) {
      print('Error getting devices: $e');
      return [];
    }
  }

  /// Check if Bluetooth is connected
  Future<bool> isConnected() async {
    return _connection != null && _connection!.isConnected;
  }

  /// Connect to a Bluetooth device via MAC address (RFCOMM/SPP)
  Future<bool> connect(BluetoothDevice device) async {
    try {
      // Disconnect if already connected
      if (_connection != null) {
        await disconnect();
      }

      // Wait a bit before connecting
      await Future.delayed(const Duration(milliseconds: 300));

      // Connect to device with timeout
      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      // Verify connection
      if (_connection != null && _connection!.isConnected) {
        // Wait for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }

      return false;
    } catch (e) {
      print('Error connecting to device: $e');
      _connection = null;
      return false;
    }
  }

  /// Connect directly via MAC address
  Future<bool> connectByAddress(String macAddress) async {
    try {
      // Disconnect if already connected
      if (_connection != null) {
        await disconnect();
      }

      // Wait a bit before connecting
      await Future.delayed(const Duration(milliseconds: 300));

      // Connect to device by address with timeout
      _connection = await BluetoothConnection.toAddress(macAddress).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      // Verify connection
      if (_connection != null && _connection!.isConnected) {
        // Wait for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }

      return false;
    } catch (e) {
      print('Error connecting by address: $e');
      _connection = null;
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        // Flush any remaining data
        await _connection!.output.allSent.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
        // Close connection
        await _connection!.close();
        await _connection!.finish();
        _connection = null;
        // Wait a bit before allowing reconnection
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Error disconnecting: $e');
      _connection = null;
    }
  }

  /// Write bytes to printer
  Future<void> _write(List<int> bytes) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('Printer not connected');
    }
    _connection!.output.add(Uint8List.fromList(bytes));
    await _connection!.output.allSent;
    // Small delay to ensure printer processes the data
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// ESC/POS: Initialize printer
  Future<void> _initPrinter() async {
    await _write([ESC, 0x40]); // ESC @ - Initialize
  }

  /// ESC/POS: Align left
  Future<void> _alignLeft() async {
    await _write([ESC, 0x61, 0]); // ESC a 0
  }

  /// ESC/POS: Align center
  Future<void> _alignCenter() async {
    await _write([ESC, 0x61, 1]); // ESC a 1
  }

  /// ESC/POS: Align right
  Future<void> _alignRight() async {
    await _write([ESC, 0x61, 2]); // ESC a 2
  }

  /// ESC/POS: Set text size (1-8)
  Future<void> _setTextSize(int width, int height) async {
    int size = ((width - 1) << 4) | (height - 1);
    await _write([GS, 0x21, size]); // GS ! n
  }

  /// ESC/POS: Set bold
  Future<void> _setBold(bool enable) async {
    await _write([ESC, 0x45, enable ? 1 : 0]); // ESC E n
  }

  /// ESC/POS: Line feed
  Future<void> _lineFeed(int lines) async {
    for (int i = 0; i < lines; i++) {
      await _write([0x0A]); // LF
    }
  }

  /// ESC/POS: Cut paper
  Future<void> _paperCut() async {
    await _write([GS, 0x56, 0]); // GS V 0 - Full cut
  }

  /// Print text
  Future<void> _printText(String text) async {
    await _write(utf8.encode(text));
  }

  /// Print text with newline
  Future<void> _printLine(String text) async {
    await _printText(text);
    await _lineFeed(1);
  }

  /// Print divider line
  Future<void> _printDivider(int length) async {
    await _printLine('-' * length);
  }

  /// Print test page
  Future<bool> printTestPage(PrinterSettings settings) async {
    try {
      if (!await isConnected()) {
        print('Printer not connected');
        return false;
      }

      final int dividerLength = settings.paperSize == PaperSize.mm58 ? 32 : 48;

      await _initPrinter();

      // Header
      await _alignCenter();
      await _setTextSize(2, 2);
      await _setBold(true);
      await _printLine('TEST PRINT');

      // Reset size
      await _setTextSize(1, 1);
      await _setBold(false);
      await _printLine('Sagawa POS');
      await _printLine(dateFormat.format(DateTime.now()));
      await _lineFeed(1);

      // Printer info
      await _alignLeft();
      await _printLine(
        'Printer: ${settings.printerType == PrinterType.bluetooth ? 'Bluetooth' : 'Network'}',
      );
      await _printLine(
        'Paper: ${settings.paperSize == PaperSize.mm58 ? '58mm' : '80mm'}',
      );
      if (settings.printerType == PrinterType.bluetooth) {
        await _printLine('MAC: ${settings.bluetoothAddress}');
      }
      await _lineFeed(2);

      // Cut paper
      await _paperCut();
      await _lineFeed(2);

      // Wait for print to complete
      await Future.delayed(const Duration(seconds: 1));

      return true;
    } catch (e) {
      print('Error printing test page: $e');
      return false;
    }
  }

  /// Print receipt to thermal printer
  Future<bool> printReceipt(Receipt receipt, PrinterSettings settings) async {
    try {
      if (!await isConnected()) {
        print('Printer not connected');
        return false;
      }

      final int dividerLength = settings.paperSize == PaperSize.mm58 ? 32 : 48;

      await _initPrinter();

      // Header
      await _alignCenter();
      await _setTextSize(2, 2);
      await _setBold(true);
      await _printLine('SAGAWA POS');

      // Reset size
      await _setTextSize(1, 1);
      await _setBold(false);
      await _lineFeed(1);

      // Receipt info
      await _alignLeft();
      await _printLine('No: ${receipt.trxId}');
      await _printLine('Tanggal: ${dateFormat.format(receipt.date)}');
      await _printLine('Kasir: ${receipt.cashier}');
      if (receipt.customerName.isNotEmpty) {
        await _printLine('Pelanggan: ${receipt.customerName}');
      }
      await _lineFeed(1);
      await _printDivider(dividerLength);
      await _lineFeed(1);

      // Items - Format: "Nasi Goreng x3" dan "Rp 20,000    Rp 60,000"
      for (final item in receipt.groupedItems) {
        // Format: "Nasi Goreng x3" (Bold)
        final productName = item.quantity > 1
            ? '${item.name} x${item.quantity}'
            : item.name;

        await _setBold(true);
        await _printLine(productName);
        await _setBold(false);

        // Format: "Rp 20,000    Rp 60,000" (harga satuan & subtotal)
        final pricePerUnit = currencyFormat.format(item.price);
        final subtotal = currencyFormat.format(item.subtotal);
        final spacing =
            ' ' * (dividerLength - pricePerUnit.length - subtotal.length);

        await _printLine(pricePerUnit + spacing + subtotal);
      }

      await _lineFeed(1);
      await _printDivider(dividerLength);
      await _lineFeed(1);

      // Totals
      final subtotalLabel = 'Subtotal:';
      final subtotalValue = currencyFormat.format(receipt.subTotal);
      final subtotalSpacing =
          ' ' * (dividerLength - subtotalLabel.length - subtotalValue.length);
      await _printLine(subtotalLabel + subtotalSpacing + subtotalValue);

      final taxLabel = 'Pajak:';
      final taxValue = currencyFormat.format(receipt.tax);
      final taxSpacing =
          ' ' * (dividerLength - taxLabel.length - taxValue.length);
      await _printLine(taxLabel + taxSpacing + taxValue);

      await _lineFeed(1);
      await _printDivider(dividerLength);
      await _lineFeed(1);

      // Total
      await _alignCenter();
      await _setTextSize(2, 2);
      await _setBold(true);
      await _printLine('TOTAL');
      await _printLine(currencyFormat.format(receipt.afterTax));

      // Reset size
      await _setTextSize(1, 1);
      await _setBold(false);
      await _lineFeed(1);

      // Payment info
      await _printDivider(dividerLength);
      await _lineFeed(1);
      await _alignLeft();
      await _printLine('Tipe: ${receipt.type}');
      await _setBold(true);
      await _printLine('Pembayaran: ${receipt.paymentMethod}');
      await _setBold(false);

      final paidLabel = 'Dibayar:';
      final paidValue = currencyFormat.format(receipt.cash);
      final paidSpacing =
          ' ' * (dividerLength - paidLabel.length - paidValue.length);
      await _printLine(paidLabel + paidSpacing + paidValue);

      final changeLabel = 'Kembali:';
      final changeValue = currencyFormat.format(receipt.change);
      final changeSpacing =
          ' ' * (dividerLength - changeLabel.length - changeValue.length);
      await _printLine(changeLabel + changeSpacing + changeValue);

      // Footer
      await _lineFeed(2);
      await _alignCenter();
      await _setBold(true);
      await _printLine('Terima Kasih');
      await _setBold(false);
      await _printLine('Atas Kunjungan Anda');
      await _lineFeed(2);

      // Cut paper
      await _paperCut();
      await _lineFeed(2);

      // Wait for print to complete
      await Future.delayed(const Duration(seconds: 2));

      return true;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }
}
