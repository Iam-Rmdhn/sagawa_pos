import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
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
  bool _isScanning = false;

  final _restaurantNameController = TextEditingController();
  final _outletAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _networkIpController = TextEditingController();
  final _networkPortController = TextEditingController();

  List<BluetoothDevice> _bluetoothDevices = [];
  List<BluetoothDevice> _nearbyDevices = [];

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

  Future<void> _startBluetoothScan() async {
    setState(() {
      _isScanning = true;
      _nearbyDevices = [];
    });

    try {
      final scanResults = await FlutterBluetoothSerial.instance
          .startDiscovery();
      final discoveredDevices = <BluetoothDevice>[];

      await for (var result in scanResults) {
        if (!discoveredDevices.any((d) => d.address == result.device.address)) {
          discoveredDevices.add(result.device);
          setState(() {
            _nearbyDevices = List.from(discoveredDevices);
          });
        }
      }

      setState(() => _isScanning = false);
    } catch (e) {
      setState(() {
        _isScanning = false;
        _nearbyDevices = [];
      });

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Gagal melakukan scan: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  void _stopBluetoothScan() {
    FlutterBluetoothSerial.instance.cancelDiscovery();
    setState(() => _isScanning = false);
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
        body: Column(
          children: [
            _buildAppBar(),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4B4B)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Restaurant Info Section
                _buildSettingsItem(
                  iconPath: AppImages.storeIcon,
                  title: 'Nama Restoran',
                  subtitle: _restaurantNameController.text.isEmpty
                      ? 'Belum diatur'
                      : _restaurantNameController.text,
                  onTap: () => _showTextInputDialog(
                    title: 'Nama Restoran',
                    controller: _restaurantNameController,
                    iconPath: AppImages.storeIcon,
                    hint: 'SAGAWA POS',
                    onSave: (value) {
                      _config = _config.copyWith(restaurantName: value);
                    },
                  ),
                ),

                _buildSettingsItem(
                  iconPath: AppImages.locationIcon,
                  title: 'Alamat Outlet',
                  subtitle: _outletAddressController.text.isEmpty
                      ? 'Belum diatur'
                      : _outletAddressController.text,
                  onTap: () => _showTextInputDialog(
                    title: 'Alamat Outlet',
                    controller: _outletAddressController,
                    iconPath: AppImages.locationIcon,
                    hint: 'Jl. Example No. 123',
                    maxLines: 3,
                    onSave: (value) {
                      _config = _config.copyWith(outletAddress: value);
                    },
                  ),
                ),

                _buildSettingsItem(
                  iconPath: AppImages.phoneIcon,
                  title: 'Nomor Telepon',
                  subtitle: _phoneNumberController.text.isEmpty
                      ? 'Belum diatur'
                      : _phoneNumberController.text,
                  onTap: () => _showTextInputDialog(
                    title: 'Nomor Telepon',
                    controller: _phoneNumberController,
                    iconPath: AppImages.phoneIcon,
                    hint: '021-12345678',
                    keyboardType: TextInputType.phone,
                    onSave: (value) {
                      _config = _config.copyWith(phoneNumber: value);
                    },
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(thickness: 6, color: Color(0xFFF5F5F5)),
                const SizedBox(height: 16),

                // Printer Connection Section
                _buildSectionTitle('Koneksi Printer'),
                _buildSettingsItem(
                  iconPath: AppImages.bluetoothIcon,
                  title: 'Printer Bluetooth',
                  subtitle: _config.bluetoothDeviceName.isEmpty
                      ? 'Pilih printer'
                      : _config.bluetoothDeviceName,
                  onTap: () => _showBluetoothDialog(),
                ),
              ],
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFF4B4B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(
                  AppImages.backArrow,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Konfigurasi Printer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitle.contains('Belum')
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  void _showTextInputDialog({
    required String title,
    required TextEditingController controller,
    required String iconPath,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    required Function(String) onSave,
  }) {
    final tempController = TextEditingController(text: controller.text);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4B4B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      iconPath,
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: tempController,
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF4B4B),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              controller.text = tempController.text;
                              onSave(tempController.text);
                              Navigator.pop(context);
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4B4B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBluetoothDialog() {
    int selectedTab = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4B4B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          AppImages.bluetoothIcon,
                          width: 28,
                          height: 28,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Pilih Printer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!_isLoadingDevices && !_isScanning)
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () async {
                              setDialogState(() {
                                _isLoadingDevices = true;
                              });
                              setState(() {
                                _isLoadingDevices = true;
                              });
                              await _loadBluetoothDevices();
                              setDialogState(() {
                                _isLoadingDevices = false;
                              });
                            },
                            tooltip: 'Refresh',
                          ),
                        if (!_isLoadingDevices && !_isScanning)
                          IconButton(
                            icon: SvgPicture.asset(
                              AppImages.scanIcon,
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () async {
                              setDialogState(() {
                                _isScanning = true;
                                selectedTab = 1;
                              });
                              setState(() {
                                _isScanning = true;
                              });
                              await _startBluetoothScan();
                              setDialogState(() {
                                _isScanning = false;
                              });
                            },
                            tooltip: 'Scan',
                          ),
                      ],
                    ),
                  ),
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedTab = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selectedTab == 0
                                        ? const Color(0xFFFF4B4B)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Paired',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selectedTab == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedTab == 0
                                      ? const Color(0xFFFF4B4B)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedTab = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selectedTab == 1
                                        ? const Color(0xFFFF4B4B)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Nearby',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selectedTab == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedTab == 1
                                      ? const Color(0xFFFF4B4B)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: selectedTab == 0
                        ? _buildPairedDevicesList(setDialogState)
                        : _buildNearbyDevicesList(setDialogState),
                  ),
                  // Close Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          if (_isScanning) {
                            _stopBluetoothScan();
                          }
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      if (_isScanning) {
        _stopBluetoothScan();
      }
      if (_bluetoothDevices.isEmpty && !_isLoadingDevices) {
        _loadBluetoothDevices();
      }
    });
  }

  Widget _buildPairedDevicesList(StateSetter setDialogState) {
    if (_isLoadingDevices) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4B4B)),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat perangkat paired...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_bluetoothDevices.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada perangkat paired',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Pairing printer di Settings > Bluetooth',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _bluetoothDevices.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _bluetoothDevices[index];
          final isSelected = device.address == _config.bluetoothAddress;

          return ListTile(
            leading: Icon(
              Icons.print,
              color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey,
            ),
            title: Text(
              device.name ?? 'Unknown Device',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFF4B4B) : Colors.black87,
              ),
            ),
            subtitle: Text(
              device.address,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFFFF4B4B))
                : null,
            onTap: () {
              setState(() {
                _config = _config.copyWith(
                  bluetoothAddress: device.address,
                  bluetoothDeviceName: device.name ?? 'Unknown',
                );
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildNearbyDevicesList(StateSetter setDialogState) {
    if (_isScanning) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF4B4B),
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    AppImages.findSignal,
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFF4B4B),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Scanning nearby devices...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_nearbyDevices.length} device${_nearbyDevices.length != 1 ? 's' : ''} found',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _stopBluetoothScan();
                  setDialogState(() {
                    _isScanning = false;
                  });
                },
                child: const Text(
                  'Stop Scan',
                  style: TextStyle(
                    color: Color(0xFFFF4B4B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyDevices.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada scan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Tekan tombol scan untuk menemukan perangkat di sekitar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _nearbyDevices.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _nearbyDevices[index];
          final isSelected = device.address == _config.bluetoothAddress;
          final isPaired = _bluetoothDevices.any(
            (d) => d.address == device.address,
          );

          return ListTile(
            leading: Icon(
              isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isSelected
                  ? const Color(0xFFFF4B4B)
                  : isPaired
                  ? Colors.blue
                  : Colors.grey,
            ),
            title: Text(
              device.name ?? 'Unknown Device',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFF4B4B) : Colors.black87,
              ),
            ),
            subtitle: Row(
              children: [
                Text(device.address, style: const TextStyle(fontSize: 12)),
                if (isPaired) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Paired',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFFFF4B4B))
                : null,
            onTap: () {
              setState(() {
                _config = _config.copyWith(
                  bluetoothAddress: device.address,
                  bluetoothDeviceName: device.name ?? 'Unknown',
                );
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 2, right: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.0),
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
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveConfiguration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              disabledBackgroundColor: const Color(0xFFFF4B4B).withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Simpan Konfigurasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
