import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/domain/models/printer_configuration.dart'
    hide PaperSize;
import 'package:sagawa_pos/features/receipt/domain/models/printer_settings.dart'
    as settings;

/// Bluetooth device model for the new package
class BluetoothPrinterDevice {
  final String name;
  final String address;

  BluetoothPrinterDevice({required this.name, required this.address});

  @override
  String toString() => 'BluetoothPrinterDevice(name: $name, address: $address)';
}

class BluetoothPrinterService {
  // Singleton pattern
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();

  factory BluetoothPrinterService() {
    return _instance;
  }

  BluetoothPrinterService._internal();

  // Static connection state - persists across instances
  static bool _isConnected = false;
  static String? _connectedAddress;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Get list of bonded/paired Bluetooth devices
  Future<List<BluetoothPrinterDevice>> getDevices() async {
    try {
      print('📱 Getting paired Bluetooth devices...');
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      print('📱 Found ${devices.length} paired devices');

      final mappedDevices = devices.map((d) {
        print('📱 Device: ${d.name} (${d.macAdress})');
        return BluetoothPrinterDevice(name: d.name, address: d.macAdress);
      }).toList();

      return mappedDevices;
    } catch (e) {
      print('❌ Error getting devices: $e');
      return [];
    }
  }

  /// Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    // Skip Bluetooth check due to package issues
    // Let connection attempt handle availability
    print('📱 Skipping Bluetooth enabled check');
    return true;
  }

  /// Check if Bluetooth is connected
  Future<bool> isConnected() async {
    // Package print_bluetooth_thermal doesn't have reliable connection status
    // We track it manually through _isConnected flag
    print('📱 Connection status (cached): $_isConnected');
    return _isConnected;
  }

  /// Connect to a Bluetooth device via MAC address
  Future<bool> connect(BluetoothPrinterDevice device) async {
    return await connectByAddress(device.address);
  }

  /// Connect directly via MAC address with enhanced error handling
  Future<bool> connectByAddress(String macAddress) async {
    try {
      print('📱 Attempting to connect to: $macAddress');

      // Check Bluetooth is enabled
      final isEnabled = await isBluetoothAvailable();
      if (!isEnabled) {
        print('❌ Bluetooth is not enabled');
        return false;
      }

      // Disconnect if already connected to another device
      if (_isConnected) {
        print('📱 Disconnecting from current device...');
        await disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('📱 Connecting to $macAddress...');

      // Attempt connection with retry
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('📱 Connection attempt $attempt/3');

          final result = await PrintBluetoothThermal.connect(
            macPrinterAddress: macAddress,
          );

          if (result) {
            _isConnected = true;
            _connectedAddress = macAddress;
            print('✅ Connected successfully to $macAddress');

            // Wait for connection to stabilize
            await Future.delayed(const Duration(milliseconds: 800));
            print('✅ Connection established');
            return true;
          } else {
            print('⚠️ Connection returned false');
          }
        } catch (e) {
          print('❌ Attempt $attempt failed: $e');
        }

        if (attempt < 3) {
          print('📱 Waiting before retry...');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      print('❌ All connection attempts failed');
      _isConnected = false;
      _connectedAddress = null;
      return false;
    } catch (e) {
      print('❌ Error connecting by address: $e');
      _isConnected = false;
      _connectedAddress = null;
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      print('📱 Disconnecting...');
      await PrintBluetoothThermal.disconnect;
      _isConnected = false;
      _connectedAddress = null;
      print('✅ Disconnected');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('❌ Error disconnecting: $e');
      _isConnected = false;
      _connectedAddress = null;
    }
  }

  /// Get paper size based on settings
  PaperSize _getPaperSize(settings.PaperSize paperSize) {
    return paperSize == settings.PaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
  }

  /// Print test page
  Future<bool> printTestPage(settings.PrinterSettings printerSettings) async {
    try {
      if (!await isConnected()) {
        print('Printer not connected');
        return false;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(
        _getPaperSize(printerSettings.paperSize),
        profile,
      );

      List<int> bytes = [];

      // Initialize
      bytes += generator.reset();

      // Header
      bytes += generator.text(
        'TEST PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      bytes += generator.text(
        'Sagawa POS',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.text(
        dateFormat.format(IndonesiaTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.feed(1);

      // Printer info
      bytes += generator.text(
        'Printer: ${printerSettings.printerType == settings.PrinterType.bluetooth ? 'Bluetooth' : 'Network'}',
      );
      bytes += generator.text(
        'Paper: ${printerSettings.paperSize == settings.PaperSize.mm58 ? '58mm' : '80mm'}',
      );
      if (printerSettings.printerType == settings.PrinterType.bluetooth) {
        bytes += generator.text('MAC: ${printerSettings.bluetoothAddress}');
      }

      bytes += generator.feed(2);

      // Cut paper
      bytes += generator.cut();

      // Send to printer
      final result = await PrintBluetoothThermal.writeBytes(bytes);

      return result;
    } catch (e) {
      print('Error printing test page: $e');
      return false;
    }
  }

  /// Print receipt to thermal printer
  Future<bool> printReceipt(
    Receipt receipt,
    settings.PrinterSettings printerSettings,
  ) async {
    try {
      if (!await isConnected()) {
        print('Printer not connected');
        return false;
      }

      // Load printer configuration
      final config = await PrinterConfiguration.load();

      final profile = await CapabilityProfile.load();
      final generator = Generator(
        _getPaperSize(printerSettings.paperSize),
        profile,
      );

      List<int> bytes = [];

      // Initialize
      bytes += generator.reset();

      // Header - Restaurant Name
      bytes += generator.text(
        config.restaurantName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      // Address
      bytes += generator.text(
        config.outletAddress,
        styles: const PosStyles(align: PosAlign.center),
      );

      // Phone Number
      if (config.phoneNumber.isNotEmpty) {
        bytes += generator.text(
          config.phoneNumber,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.feed(1);

      // Receipt info
      bytes += generator.text('Trx ID: ${receipt.trxId}');
      bytes += generator.text('Date: ${dateFormat.format(receipt.date)}');
      bytes += generator.text('Cashier: ${receipt.cashier}');
      if (receipt.customerName.isNotEmpty) {
        bytes += generator.text('Customer: ${receipt.customerName}');
      }

      bytes += generator.feed(1);
      bytes += generator.hr();
      bytes += generator.feed(1);

      // Items
      for (final item in receipt.groupedItems) {
        final productName = item.quantity > 1
            ? '${item.name} x${item.quantity}'
            : item.name;

        bytes += generator.text(
          productName,
          styles: const PosStyles(bold: true),
        );

        bytes += generator.row([
          PosColumn(text: currencyFormat.format(item.price), width: 6),
          PosColumn(
            text: currencyFormat.format(item.subtotal),
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      }

      bytes += generator.feed(1);

      // Catatan setelah list menu
      if (receipt.notes != null && receipt.notes!.isNotEmpty) {
        bytes += generator.text(
          'Catatan:',
          styles: const PosStyles(bold: true),
        );
        bytes += generator.text(receipt.notes!);
        bytes += generator.feed(1);
      }

      bytes += generator.hr();
      bytes += generator.feed(1);

      // Totals
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(
          text: currencyFormat.format(receipt.subTotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: 'PB1:', width: 6),
        PosColumn(
          text: currencyFormat.format(receipt.tax),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.feed(1);
      bytes += generator.hr();
      bytes += generator.feed(1);

      // Total
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: currencyFormat.format(receipt.afterTax),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.feed(1);
      bytes += generator.hr();
      bytes += generator.feed(1);

      // Payment info
      bytes += generator.text('Type: ${receipt.type}');
      bytes += generator.text(
        'Payment: ${receipt.paymentMethod}',
        styles: const PosStyles(bold: true),
      );

      // Voucher payment details
      if (receipt.isVoucherPayment) {
        bytes += generator.row([
          PosColumn(text: 'Voucher Code:', width: 6),
          PosColumn(
            text: receipt.voucherCode ?? '-',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        bytes += generator.row([
          PosColumn(text: 'Voucher:', width: 6),
          PosColumn(
            text: currencyFormat.format(receipt.voucherAmount ?? 0),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        if (receipt.hasAdditionalPayment) {
          bytes += generator.row([
            PosColumn(
              text: 'Add. ${receipt.additionalPaymentMethod ?? ''}:',
              width: 6,
            ),
            PosColumn(
              text: currencyFormat.format(receipt.additionalPayment ?? 0),
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]);
        }
      } else {
        bytes += generator.row([
          PosColumn(text: 'Paid:', width: 6),
          PosColumn(
            text: currencyFormat.format(receipt.cash),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(text: 'Change:', width: 6),
        PosColumn(
          text: currencyFormat.format(receipt.change),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Footer
      bytes += generator.feed(2);
      bytes += generator.text(
        'Terima Kasih',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Atas Kunjungan Anda',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.feed(2);

      // Cut paper
      bytes += generator.cut();

      // Send to printer
      final result = await PrintBluetoothThermal.writeBytes(bytes);

      // Wait for print to complete
      await Future.delayed(const Duration(seconds: 2));

      return result;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }
}
