import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/domain/models/printer_configuration.dart'
    hide PaperSize;
import 'package:sagawa_pos/features/receipt/domain/models/printer_settings.dart'
    as settings;

class BluetoothPrinterDevice {
  final String name;
  final String address;

  BluetoothPrinterDevice({required this.name, required this.address});

  @override
  String toString() => 'BluetoothPrinterDevice(name: $name, address: $address)';
}

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();

  factory BluetoothPrinterService() {
    return _instance;
  }

  BluetoothPrinterService._internal();

  static bool _isConnected = false;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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

  Future<bool> isBluetoothAvailable() async {
    try {
      print('📱 Checking if Bluetooth is enabled...');
      final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      print('📱 Bluetooth enabled: $isEnabled');
      return isEnabled;
    } catch (e) {
      print('⚠️ Error checking Bluetooth status: $e');

      return true;
    }
  }

  Future<bool> hasBluetoothPermission() async {
    try {
      await PrintBluetoothThermal.pairedBluetooths;
      return true;
    } catch (e) {
      if (e.toString().contains('permission') ||
          e.toString().contains('SecurityException')) {
        print('❌ Bluetooth permission not granted: $e');
        return false;
      }

      return true;
    }
  }

  Future<bool> isConnected() async {
    print('📱 Connection status (cached): $_isConnected');
    return _isConnected;
  }

  Future<bool> connect(BluetoothPrinterDevice device) async {
    return await connectByAddress(device.address);
  }

  Future<bool> connectByAddress(String macAddress) async {
    try {
      print('📱 Attempting to connect to: $macAddress');

      final isEnabled = await isBluetoothAvailable();
      if (!isEnabled) {
        print('❌ Bluetooth is not enabled. Please turn on Bluetooth.');
        return false;
      }

      final hasPermission = await hasBluetoothPermission();
      if (!hasPermission) {
        print('❌ Bluetooth permission not granted');
        return false;
      }

      if (_isConnected) {
        print('📱 Disconnecting from current device...');
        await disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('📱 Connecting to $macAddress...');

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('📱 Connection attempt $attempt/3');

          final result = await PrintBluetoothThermal.connect(
            macPrinterAddress: macAddress,
          );

          if (result) {
            _isConnected = true;
            print('✅ Connected successfully to $macAddress');

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
      return false;
    } catch (e) {
      print('❌ Error connecting by address: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      print('📱 Disconnecting...');
      await PrintBluetoothThermal.disconnect;
      _isConnected = false;
      print('✅ Disconnected');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('❌ Error disconnecting: $e');
      _isConnected = false;
    }
  }

  PaperSize _getPaperSize(settings.PaperSize paperSize) {
    return paperSize == settings.PaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
  }

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

      bytes += generator.reset();

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

      bytes += generator.cut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);

      return result;
    } catch (e) {
      print('Error printing test page: $e');
      return false;
    }
  }

  Future<bool> printReceipt(
    Receipt receipt,
    settings.PrinterSettings printerSettings,
  ) async {
    try {
      if (!await isConnected()) {
        print('Printer not connected');
        return false;
      }

      final config = await PrinterConfiguration.load();

      final profile = await CapabilityProfile.load();
      final generator = Generator(
        _getPaperSize(printerSettings.paperSize),
        profile,
      );

      List<int> bytes = [];

      bytes += generator.reset();

      bytes += generator.text(
        config.restaurantName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      bytes += generator.text(
        config.outletAddress,
        styles: const PosStyles(align: PosAlign.center),
      );

      if (config.phoneNumber.isNotEmpty) {
        bytes += generator.text(
          config.phoneNumber,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.feed(1);

      bytes += generator.text('Trx ID: ${receipt.trxId}');
      bytes += generator.text('Date: ${dateFormat.format(receipt.date)}');
      bytes += generator.text('Cashier: ${receipt.cashier}');
      if (receipt.customerName.isNotEmpty) {
        bytes += generator.text('Customer: ${receipt.customerName}');
      }

      bytes += generator.feed(1);
      bytes += generator.hr();
      bytes += generator.feed(1);

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

      bytes += generator.row([
        PosColumn(
          text: 'Total Pembelian:',
          width: 6,
          styles: const PosStyles(bold: false),
        ),
        PosColumn(
          text: currencyFormat.format(receipt.totalPembelian),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: false),
        ),
      ]);

      bytes += generator.feed(1);
      bytes += generator.hr();

      if (receipt.isVoucherPayment && receipt.voucherAmount != null) {
        bytes += generator.row([
          PosColumn(text: 'Voucher:', width: 6),
          PosColumn(
            text: '-${currencyFormat.format(receipt.voucherAmount!)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        bytes += generator.row([
          PosColumn(text: 'Sub total:', width: 6),
          PosColumn(
            text: currencyFormat.format(receipt.totalSetelahPotongan),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      } else if (receipt.isDiscountPayment && receipt.discountAmount != null) {
        bytes += generator.row([
          PosColumn(
            text: 'Discount ${receipt.discountPercent ?? 0}%:',
            width: 6,
          ),
          PosColumn(
            text: '-${currencyFormat.format(receipt.discountAmount!)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        bytes += generator.row([
          PosColumn(text: 'Sub total:', width: 6),
          PosColumn(
            text: currencyFormat.format(receipt.totalSetelahPotongan),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: 'Sub total:', width: 6),
          PosColumn(
            text: currencyFormat.format(receipt.totalPembelian),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.feed(1);

      if (receipt.tax > 0 || receipt.calculatedTax > 0) {
        bytes += generator.row([
          PosColumn(text: 'Tax 10%:', width: 6),
          PosColumn(
            text: currencyFormat.format(
              receipt.hasPotongan ? receipt.calculatedTax : receipt.tax,
            ),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.feed(1);

      bytes += generator.text('After Tax', styles: const PosStyles(bold: true));
      bytes += generator.hr();

      bytes += generator.row([
        PosColumn(
          text: 'Total:',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: currencyFormat.format(receipt.subTotalFinal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: 'Type:', width: 6),
        PosColumn(
          text: receipt.type,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (!receipt.isFreeTransaction) {
        final isQris = receipt.paymentMethodDisplay.contains('QRIS');
        final paidAmount = isQris ? receipt.subTotalFinal : receipt.amountPaid;

        bytes += generator.row([
          PosColumn(text: 'Paid:', width: 6),
          PosColumn(
            text: currencyFormat.format(paidAmount),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(text: 'Payment:', width: 6),
        PosColumn(
          text: receipt.paymentMethodDisplay,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      final isCash = receipt.paymentMethodDisplay.contains('Cash');
      final calculatedChange = receipt.calculatedChange;

      if (!receipt.isFreeTransaction && isCash && calculatedChange > 0) {
        bytes += generator.row([
          PosColumn(text: 'Change:', width: 6),
          PosColumn(
            text: currencyFormat.format(calculatedChange),
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

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

      bytes += generator.cut();

      final result = await PrintBluetoothThermal.writeBytes(bytes);

      await Future.delayed(const Duration(seconds: 2));

      return result;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }
}
