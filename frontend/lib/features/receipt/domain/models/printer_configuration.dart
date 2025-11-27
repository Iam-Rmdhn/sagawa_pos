import 'package:shared_preferences/shared_preferences.dart';

enum PrinterType { bluetooth, usb }

enum PaperSize { mm58, mm80 }

class PrinterConfiguration {
  // Header Configuration
  final String logoPath;
  final String restaurantName;
  final String outletAddress;
  final String phoneNumber;

  // Printer Connection
  final PrinterType printerType;
  final String bluetoothAddress;
  final String bluetoothDeviceName;

  // Paper Settings
  final PaperSize paperSize;

  // Network Settings (if needed)
  final String networkIp;
  final int networkPort;

  PrinterConfiguration({
    required this.logoPath,
    required this.restaurantName,
    required this.outletAddress,
    required this.phoneNumber,
    required this.printerType,
    required this.bluetoothAddress,
    required this.bluetoothDeviceName,
    required this.paperSize,
    required this.networkIp,
    required this.networkPort,
  });

  factory PrinterConfiguration.defaults() {
    return PrinterConfiguration(
      logoPath: '',
      restaurantName: 'SAGAWA POS',
      outletAddress: 'Jl. Example No. 123, Jakarta',
      phoneNumber: '021-12345678',
      printerType: PrinterType.bluetooth,
      bluetoothAddress: '86:67:7A:A7:91:6C',
      bluetoothDeviceName: 'RPP02N',
      paperSize: PaperSize.mm80,
      networkIp: '192.168.1.100',
      networkPort: 9100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logoPath': logoPath,
      'restaurantName': restaurantName,
      'outletAddress': outletAddress,
      'phoneNumber': phoneNumber,
      'printerType': printerType.index,
      'bluetoothAddress': bluetoothAddress,
      'bluetoothDeviceName': bluetoothDeviceName,
      'paperSize': paperSize.index,
      'networkIp': networkIp,
      'networkPort': networkPort,
    };
  }

  factory PrinterConfiguration.fromJson(Map<String, dynamic> json) {
    return PrinterConfiguration(
      logoPath: json['logoPath'] ?? '',
      restaurantName: json['restaurantName'] ?? 'SAGAWA POS',
      outletAddress: json['outletAddress'] ?? 'Jl. Example No. 123, Jakarta',
      phoneNumber: json['phoneNumber'] ?? '021-12345678',
      printerType: PrinterType.values[json['printerType'] ?? 0],
      bluetoothAddress: json['bluetoothAddress'] ?? '86:67:7A:A7:91:6C',
      bluetoothDeviceName: json['bluetoothDeviceName'] ?? 'RPP02N',
      paperSize: PaperSize.values[json['paperSize'] ?? 1],
      networkIp: json['networkIp'] ?? '192.168.1.100',
      networkPort: json['networkPort'] ?? 9100,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_logoPath', logoPath);
    await prefs.setString('printer_restaurantName', restaurantName);
    await prefs.setString('printer_outletAddress', outletAddress);
    await prefs.setString('printer_phoneNumber', phoneNumber);
    await prefs.setInt('printer_printerType', printerType.index);
    await prefs.setString('printer_bluetoothAddress', bluetoothAddress);
    await prefs.setString('printer_bluetoothDeviceName', bluetoothDeviceName);
    await prefs.setInt('printer_paperSize', paperSize.index);
    await prefs.setString('printer_networkIp', networkIp);
    await prefs.setInt('printer_networkPort', networkPort);
  }

  static Future<PrinterConfiguration> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterConfiguration(
      logoPath: prefs.getString('printer_logoPath') ?? '',
      restaurantName: prefs.getString('printer_restaurantName') ?? 'SAGAWA POS',
      outletAddress:
          prefs.getString('printer_outletAddress') ??
          'Jl. Example No. 123, Jakarta',
      phoneNumber: prefs.getString('printer_phoneNumber') ?? '021-12345678',
      printerType: PrinterType.values[prefs.getInt('printer_printerType') ?? 0],
      bluetoothAddress:
          prefs.getString('printer_bluetoothAddress') ?? '86:67:7A:A7:91:6C',
      bluetoothDeviceName:
          prefs.getString('printer_bluetoothDeviceName') ?? 'RPP02N',
      paperSize: PaperSize.values[prefs.getInt('printer_paperSize') ?? 1],
      networkIp: prefs.getString('printer_networkIp') ?? '192.168.1.100',
      networkPort: prefs.getInt('printer_networkPort') ?? 9100,
    );
  }

  PrinterConfiguration copyWith({
    String? logoPath,
    String? restaurantName,
    String? outletAddress,
    String? phoneNumber,
    PrinterType? printerType,
    String? bluetoothAddress,
    String? bluetoothDeviceName,
    PaperSize? paperSize,
    String? networkIp,
    int? networkPort,
  }) {
    return PrinterConfiguration(
      logoPath: logoPath ?? this.logoPath,
      restaurantName: restaurantName ?? this.restaurantName,
      outletAddress: outletAddress ?? this.outletAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      printerType: printerType ?? this.printerType,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      paperSize: paperSize ?? this.paperSize,
      networkIp: networkIp ?? this.networkIp,
      networkPort: networkPort ?? this.networkPort,
    );
  }
}
