import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/printer_configuration.dart';

class PrinterConfigurationPage extends StatefulWidget {
  const PrinterConfigurationPage({super.key});

  @override
  State<PrinterConfigurationPage> createState() =>
      _PrinterConfigurationPageState();
}

class _PrinterConfigurationPageState extends State<PrinterConfigurationPage> {
  late PrinterConfiguration _config;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingDevices = false;

  final _restaurantNameController = TextEditingController();
  final _outletAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _networkIpController = TextEditingController();
  final _networkPortController = TextEditingController();

  List<BluetoothDevice> _bluetoothDevices = [];
  String? _selectedLogoPath;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _outletAddressController.dispose();
    _phoneNumberController.dispose();
    _networkIpController.dispose();
    _networkPortController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    setState(() => _isLoading = true);

    try {
      final config = await PrinterConfiguration.load();
      setState(() {
        _config = config;
        _restaurantNameController.text = config.restaurantName;
        _outletAddressController.text = config.outletAddress;
        _phoneNumberController.text = config.phoneNumber;
        _networkIpController.text = config.networkIp;
        _networkPortController.text = config.networkPort.toString();
        _selectedLogoPath = config.logoPath;
        _isLoading = false;
      });

      // Load Bluetooth devices if Bluetooth type
      if (_config.printerType == PrinterType.bluetooth) {
        _loadBluetoothDevices();
      }
    } catch (e) {
      setState(() {
        _config = PrinterConfiguration.defaults();
        _restaurantNameController.text = _config.restaurantName;
        _outletAddressController.text = _config.outletAddress;
        _phoneNumberController.text = _config.phoneNumber;
        _networkIpController.text = _config.networkIp;
        _networkPortController.text = _config.networkPort.toString();
        _selectedLogoPath = _config.logoPath;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBluetoothDevices() async {
    setState(() => _isLoadingDevices = true);

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _bluetoothDevices = devices;
        _isLoadingDevices = false;
      });
    } catch (e) {
      setState(() {
        _bluetoothDevices = [];
        _isLoadingDevices = false;
      });

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Gagal memuat perangkat Bluetooth: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedLogoPath = pickedFile.path;
          _config = _config.copyWith(logoPath: pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Gagal memilih logo: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    // Validate required fields
    if (_restaurantNameController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Nama restoran tidak boleh kosong',
        type: SnackbarType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _config.save();

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Konfigurasi printer berhasil disimpan',
          type: SnackbarType.success,
        );
        Navigator.pop(context, _config);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Gagal menyimpan konfigurasi: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4B4B)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Header Configuration Section
          _buildHeaderSection(),
          const SizedBox(height: 16),

          // 2. Printer Connection Section
          _buildPrinterConnectionSection(),
          const SizedBox(height: 16),

          // 3. Paper Settings Section
          _buildPaperSettingsSection(),
          const SizedBox(height: 16),

          // 4. Help/Usage Section
          _buildHelpSection(),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFF4B4B),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Konfigurasi Printer',
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
    );
  }

  Widget _buildHeaderSection() {
    return _buildSectionCard(
      title: 'Konfigurasi Header Struk',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Upload
          const Text(
            'Logo Restoran',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedLogoPath != null && _selectedLogoPath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedLogoPath!),
                        fit: BoxFit.contain,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk pilih logo',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Restaurant Name
          TextField(
            controller: _restaurantNameController,
            decoration: InputDecoration(
              labelText: 'Nama Restoran *',
              hintText: 'SAGAWA POS',
              prefixIcon: const Icon(Icons.store),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              _config = _config.copyWith(restaurantName: value);
            },
          ),
          const SizedBox(height: 16),

          // Outlet Address
          TextField(
            controller: _outletAddressController,
            decoration: InputDecoration(
              labelText: 'Alamat Outlet',
              hintText: 'Jl. Example No. 123, Jakarta',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
            onChanged: (value) {
              _config = _config.copyWith(outletAddress: value);
            },
          ),
          const SizedBox(height: 16),

          // Phone Number
          TextField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: 'Nomor Telepon',
              hintText: '021-12345678',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              _config = _config.copyWith(phoneNumber: value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterConnectionSection() {
    return _buildSectionCard(
      title: 'Koneksi Printer',
      icon: Icons.print_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Printer Type Selection
          const Text(
            'Jenis Koneksi',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildRadioTile(
            title: 'Bluetooth',
            subtitle: 'Koneksi via Bluetooth',
            value: PrinterType.bluetooth,
            groupValue: _config.printerType,
            icon: Icons.bluetooth,
            onChanged: (value) {
              setState(() {
                _config = _config.copyWith(printerType: value);
                if (value == PrinterType.bluetooth) {
                  _loadBluetoothDevices();
                }
              });
            },
          ),
          const Divider(height: 1),
          _buildRadioTile(
            title: 'USB (Coming Soon)',
            subtitle: 'Koneksi via kabel USB',
            value: PrinterType.usb,
            groupValue: _config.printerType,
            icon: Icons.usb,
            onChanged: null, // Disabled for now
          ),
          const SizedBox(height: 16),

          // Bluetooth Device Selection
          if (_config.printerType == PrinterType.bluetooth) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Printer Bluetooth',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!_isLoadingDevices)
                  TextButton.icon(
                    onPressed: _loadBluetoothDevices,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4B4B),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingDevices)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_bluetoothDevices.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tidak ada perangkat Bluetooth yang terpasang. Pastikan printer sudah di-pairing.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bluetoothDevices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = _bluetoothDevices[index];
                    final isSelected =
                        device.address == _config.bluetoothAddress;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF4B4B).withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.print,
                          color: isSelected
                              ? const Color(0xFFFF4B4B)
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        device.name ?? 'Unknown Device',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFF4B4B)
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        device.address,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFF4B4B),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _config = _config.copyWith(
                            bluetoothAddress: device.address,
                            bluetoothDeviceName: device.name ?? 'Unknown',
                          );
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaperSettingsSection() {
    return _buildSectionCard(
      title: 'Ukuran Kertas',
      icon: Icons.straighten_outlined,
      child: Column(
        children: [
          _buildRadioTile(
            title: '58mm',
            subtitle: 'Kertas thermal 58mm (kecil)',
            value: PaperSize.mm58,
            groupValue: _config.paperSize,
            icon: Icons.receipt,
            onChanged: (value) {
              setState(() {
                _config = _config.copyWith(paperSize: value);
              });
            },
          ),
          const Divider(height: 1),
          _buildRadioTile(
            title: '80mm',
            subtitle: 'Kertas thermal 80mm (standar)',
            value: PaperSize.mm80,
            groupValue: _config.paperSize,
            icon: Icons.receipt_long,
            onChanged: (value) {
              setState(() {
                _config = _config.copyWith(paperSize: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return _buildSectionCard(
      title: 'Panduan Penggunaan',
      icon: Icons.help_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpItem(
            number: '1',
            title: 'Pairing Printer Bluetooth',
            description:
                'Buka Settings > Bluetooth di HP Anda, pastikan Bluetooth aktif. Cari perangkat printer (contoh: RPP02N), lalu tap untuk pairing. PIN default biasanya 0000 atau 1234.',
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            number: '2',
            title: 'Pilih Printer',
            description:
                'Setelah pairing berhasil, refresh daftar printer di atas dan pilih printer yang sudah terpasang.',
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            number: '3',
            title: 'Test Koneksi',
            description:
                'Sebelum mencetak struk asli, coba test print terlebih dahulu untuk memastikan koneksi berfungsi dengan baik.',
          ),
          const SizedBox(height: 12),
          _buildHelpItem(
            number: '4',
            title: 'Troubleshooting',
            description:
                'Jika gagal cetak: pastikan printer menyala, kertas tersedia, Bluetooth aktif, dan printer dalam jangkauan (<10 meter).',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Simpan konfigurasi setelah pairing berhasil agar tidak perlu setup ulang.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4B4B),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
    required ValueChanged<T?>? onChanged,
  }) {
    final isSelected = value == groupValue;
    final isEnabled = onChanged != null;

    return InkWell(
      onTap: isEnabled ? () => onChanged(value) : null,
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
                color: isSelected
                    ? const Color(0xFFFF4B4B)
                    : isEnabled
                    ? Colors.grey
                    : Colors.grey.shade400,
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
                          : isEnabled
                          ? Colors.black87
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
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

  Widget _buildSaveButton() {
    return Container(
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
            onPressed: _isSaving ? null : _saveConfiguration,
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
              _isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              disabledBackgroundColor: const Color(0xFFFF4B4B).withOpacity(0.5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
