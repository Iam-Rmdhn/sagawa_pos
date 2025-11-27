import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_settings.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  late PrinterSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  final _networkIpController = TextEditingController();
  final _networkPortController = TextEditingController();
  final _bluetoothAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _networkIpController.dispose();
    _networkPortController.dispose();
    _bluetoothAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await PrinterSettings.load();
      setState(() {
        _settings = settings;
        _networkIpController.text = settings.networkIp;
        _networkPortController.text = settings.networkPort.toString();
        _bluetoothAddressController.text = settings.bluetoothAddress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = PrinterSettings.defaults();
        _networkIpController.text = _settings.networkIp;
        _networkPortController.text = _settings.networkPort.toString();
        _bluetoothAddressController.text = _settings.bluetoothAddress;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settings.save();

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Pengaturan printer berhasil disimpan',
          type: SnackbarType.success,
        );
        Navigator.pop(context, _settings);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF4B4B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pengaturan Printer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4B4B)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4B4B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Printer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Printer Type Section
          _buildSectionCard(
            title: 'Jenis Printer',
            icon: Icons.print_outlined,
            child: Column(
              children: [
                _buildRadioTile(
                  title: 'Bluetooth',
                  subtitle: 'Printer thermal via Bluetooth',
                  value: PrinterType.bluetooth,
                  groupValue: _settings.printerType,
                  icon: Icons.bluetooth,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(printerType: value);
                    });
                  },
                ),
                const Divider(height: 1),
                _buildRadioTile(
                  title: 'Network (WiFi)',
                  subtitle: 'Printer thermal via jaringan WiFi',
                  value: PrinterType.network,
                  groupValue: _settings.printerType,
                  icon: Icons.wifi,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(printerType: value);
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bluetooth Settings (only show if Bluetooth selected)
          if (_settings.printerType == PrinterType.bluetooth)
            _buildSectionCard(
              title: 'Pengaturan Bluetooth',
              icon: Icons.bluetooth_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model Printer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF4B4B).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.print,
                          color: const Color(0xFFFF4B4B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'RPP02N Thermal Printer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF4B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bluetoothAddressController,
                    decoration: InputDecoration(
                      labelText: 'MAC Address',
                      hintText: '86:67:7A:A7:91:6C',
                      prefixIcon: const Icon(Icons.bluetooth_connected),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9A-Fa-f:]'),
                      ),
                    ],
                    onChanged: (value) {
                      _settings = _settings.copyWith(bluetoothAddress: value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Format: XX:XX:XX:XX:XX:XX',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          // Network Settings (only show if Network selected)
          if (_settings.printerType == PrinterType.network)
            _buildSectionCard(
              title: 'Pengaturan Network',
              icon: Icons.wifi_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model Printer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF4B4B).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.print,
                          color: const Color(0xFFFF4B4B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'RPP02N Thermal Printer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF4B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _networkIpController,
                    decoration: InputDecoration(
                      labelText: 'IP Address',
                      hintText: '192.168.1.100',
                      prefixIcon: const Icon(Icons.router),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (value) {
                      _settings = _settings.copyWith(networkIp: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _networkPortController,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      hintText: '9100',
                      prefixIcon: const Icon(Icons.settings_ethernet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final port = int.tryParse(value) ?? 9100;
                      _settings = _settings.copyWith(networkPort: port);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Port default untuk thermal printer: 9100',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Paper Size Section
          _buildSectionCard(
            title: 'Ukuran Kertas',
            icon: Icons.straighten_outlined,
            child: Column(
              children: [
                _buildRadioTile(
                  title: '58mm',
                  subtitle: 'Kertas thermal 58mm (kecil)',
                  value: PaperSize.mm58,
                  groupValue: _settings.paperSize,
                  icon: Icons.receipt,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(paperSize: value);
                    });
                  },
                ),
                const Divider(height: 1),
                _buildRadioTile(
                  title: '80mm',
                  subtitle: 'Kertas thermal 80mm (standar)',
                  value: PaperSize.mm80,
                  groupValue: _settings.paperSize,
                  icon: Icons.receipt_long,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(paperSize: value);
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Printer RPP02N mendukung koneksi Bluetooth dan WiFi. Pastikan printer sudah terhubung sebelum mencetak.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                disabledBackgroundColor: const Color(
                  0xFFFF4B4B,
                ).withOpacity(0.5),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF4B4B), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF4B4B).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFFF4B4B)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFFFF4B4B),
            ),
          ],
        ),
      ),
    );
  }
}
