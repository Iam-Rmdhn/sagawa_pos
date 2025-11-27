import 'package:shared_preferences/shared_preferences.dart';

enum PrinterType { bluetooth, network }

enum PaperSize { mm58, mm80 }

class PrinterSettings {
  final PrinterType printerType;
  final String bluetoothAddress;
  final String networkIp;
  final int networkPort;
  final PaperSize paperSize;

  PrinterSettings({
    required this.printerType,
    required this.bluetoothAddress,
    required this.networkIp,
    required this.networkPort,
    required this.paperSize,
  });

  factory PrinterSettings.defaults() {
    return PrinterSettings(
      printerType: PrinterType.bluetooth,
      bluetoothAddress: '86:67:7A:A7:91:6C', // RPP02N default
      networkIp: '192.168.1.100',
      networkPort: 9100,
      paperSize: PaperSize.mm80,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'printerType': printerType.index,
      'bluetoothAddress': bluetoothAddress,
      'networkIp': networkIp,
      'networkPort': networkPort,
      'paperSize': paperSize.index,
    };
  }

  factory PrinterSettings.fromJson(Map<String, dynamic> json) {
    return PrinterSettings(
      printerType: PrinterType.values[json['printerType'] ?? 0],
      bluetoothAddress: json['bluetoothAddress'] ?? '86:67:7A:A7:91:6C',
      networkIp: json['networkIp'] ?? '192.168.1.100',
      networkPort: json['networkPort'] ?? 9100,
      paperSize: PaperSize.values[json['paperSize'] ?? 1],
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('printerType', printerType.index);
    await prefs.setString('bluetoothAddress', bluetoothAddress);
    await prefs.setString('networkIp', networkIp);
    await prefs.setInt('networkPort', networkPort);
    await prefs.setInt('paperSize', paperSize.index);
  }

  static Future<PrinterSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterSettings(
      printerType: PrinterType.values[prefs.getInt('printerType') ?? 0],
      bluetoothAddress:
          prefs.getString('bluetoothAddress') ?? '86:67:7A:A7:91:6C',
      networkIp: prefs.getString('networkIp') ?? '192.168.1.100',
      networkPort: prefs.getInt('networkPort') ?? 9100,
      paperSize: PaperSize.values[prefs.getInt('paperSize') ?? 1],
    );
  }

  PrinterSettings copyWith({
    PrinterType? printerType,
    String? bluetoothAddress,
    String? networkIp,
    int? networkPort,
    PaperSize? paperSize,
  }) {
    return PrinterSettings(
      printerType: printerType ?? this.printerType,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      networkIp: networkIp ?? this.networkIp,
      networkPort: networkPort ?? this.networkPort,
      paperSize: paperSize ?? this.paperSize,
    );
  }

  int get paperWidthMm => paperSize == PaperSize.mm58 ? 58 : 80;

  String get paperSizeLabel => paperSize == PaperSize.mm58 ? '58mm' : '80mm';

  String get printerTypeLabel =>
      printerType == PrinterType.bluetooth ? 'Bluetooth' : 'Network (WiFi)';
}
