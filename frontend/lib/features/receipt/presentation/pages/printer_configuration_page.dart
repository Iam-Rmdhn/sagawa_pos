import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/core/services/permission_service.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos/features/receipt/domain/models/printer_configuration.dart';
import 'package:sagawa_pos/features/receipt/domain/models/printer_settings.dart'
    as settings;
import 'package:sagawa_pos/features/receipt/domain/services/bluetooth_printer_service.dart';

class PrinterConfigurationPage extends StatefulWidget {
  const PrinterConfigurationPage({super.key});

  @override
  State<PrinterConfigurationPage> createState() =>
      _PrinterConfigurationPageState();
}

class _PrinterConfigurationPageState extends State<PrinterConfigurationPage>
    with WidgetsBindingObserver {
  late PrinterConfiguration _config;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingDevices = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isPrinting = false;

  final _restaurantNameController = TextEditingController();
  final _outletAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _networkIpController = TextEditingController();
  final _networkPortController = TextEditingController();
  final _searchController = TextEditingController(); // For searching printers

  final BluetoothPrinterService _bluetoothService = BluetoothPrinterService();
  List<BluetoothInfo> _bluetoothDevices = [];
  List<BluetoothInfo> _filteredBluetoothDevices = []; // Filtered search results

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConfiguration();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restaurantNameController.dispose();
    _outletAddressController.dispose();
    _phoneNumberController.dispose();
    _networkIpController.dispose();
    _networkPortController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check connection when app returns to foreground
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, checking connection status...');
      _checkConnectionStatus();
    }
  }

  void _filterPrinters(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBluetoothDevices = _bluetoothDevices;
      } else {
        _filteredBluetoothDevices = _bluetoothDevices.where((device) {
          final nameLower = device.name.toLowerCase();
          final addressLower = device.macAdress.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              addressLower.contains(queryLower);
        }).toList();
      }
    });
  }

  Future<void> _loadConfiguration() async {
    setState(() => _isLoading = true);

    try {
      final config = await PrinterConfiguration.load();
      final prefs = await SharedPreferences.getInstance();

      // Sinkronkan alamat outlet dengan user_location
      String outletAddress = config.outletAddress;
      final userLocation = prefs.getString('user_location') ?? '';

      // Jika outlet address default atau kosong, gunakan user_location
      if (outletAddress.isEmpty ||
          outletAddress == 'Jl. Example No. 123, Jakarta') {
        if (userLocation.isNotEmpty) {
          outletAddress = userLocation;
        }
      } else if (userLocation.isEmpty &&
          outletAddress.isNotEmpty &&
          outletAddress != 'Jl. Example No. 123, Jakarta') {
        // Jika user_location kosong tapi outlet address ada, sinkronkan
        await prefs.setString('user_location', outletAddress);
      }

      setState(() {
        _config = config.copyWith(outletAddress: outletAddress);
        _restaurantNameController.text = config.restaurantName;
        _outletAddressController.text = outletAddress;
        _phoneNumberController.text = config.phoneNumber;
        _networkIpController.text = config.networkIp;
        _networkPortController.text = config.networkPort.toString();
        _isLoading = false;
      });

      // Load Bluetooth devices if Bluetooth type
      if (_config.printerType == PrinterType.bluetooth) {
        await _loadBluetoothDevices();
        // Check connection status after loading
        await _checkConnectionStatus();
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
      // Request Bluetooth permission first (required for Android 12+)
      print('📱 Checking Bluetooth permissions...');
      final hasPermission = await PermissionService.requestBluetoothPermission(
        context,
      );

      if (!hasPermission) {
        print('❌ Bluetooth permission not granted');
        setState(() {
          _bluetoothDevices = [];
          _filteredBluetoothDevices = [];
          _isLoadingDevices = false;
        });

        if (mounted) {
          CustomSnackbar.show(
            context,
            message:
                'Izin Bluetooth diperlukan untuk menampilkan daftar printer',
            type: SnackbarType.warning,
          );
        }
        return;
      }

      // Check if Bluetooth is enabled
      print('📱 Checking if Bluetooth is enabled...');
      final isBluetoothOn = await _bluetoothService.isBluetoothAvailable();

      if (!isBluetoothOn) {
        setState(() {
          _bluetoothDevices = [];
          _filteredBluetoothDevices = [];
          _isLoadingDevices = false;
        });

        if (mounted) {
          _showBluetoothOffDialog();
        }
        return;
      }

      // Get paired devices
      print('📱 Loading paired Bluetooth devices...');
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _bluetoothDevices = devices;
        _filteredBluetoothDevices = devices;
        _isLoadingDevices = false;
      });

      print('📱 Found ${devices.length} paired devices');
    } catch (e) {
      print('❌ Error loading Bluetooth devices: $e');
      setState(() {
        _bluetoothDevices = [];
        _filteredBluetoothDevices = [];
        _isLoadingDevices = false;
      });

      if (mounted) {
        String errorMessage = 'Gagal memuat perangkat Bluetooth';

        // Check for common errors
        if (e.toString().contains('permission') ||
            e.toString().contains('SecurityException')) {
          errorMessage =
              'Izin Bluetooth ditolak. Buka Pengaturan > Aplikasi > Sagawa POS > Izin untuk mengaktifkan.';
        } else if (e.toString().contains('BluetoothAdapter')) {
          errorMessage = 'Bluetooth tidak tersedia di perangkat ini.';
        }

        CustomSnackbar.show(
          context,
          message: errorMessage,
          type: SnackbarType.error,
        );
      }
    }
  }

  /// Show dialog when Bluetooth is off
  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Color(0xFFFF4B4B), size: 28),
            SizedBox(width: 12),
            Text('Bluetooth Mati'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bluetooth perangkat Anda sedang mati. Silakan aktifkan Bluetooth terlebih dahulu untuk menghubungkan ke printer.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 16),
            Text(
              'Langkah:\n1. Buka Settings/Pengaturan\n2. Pilih Bluetooth\n3. Aktifkan Bluetooth\n4. Kembali ke aplikasi ini',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh after user enables Bluetooth
              _loadBluetoothDevices();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkConnectionStatus() async {
    if (_config.bluetoothAddress.isEmpty) {
      setState(() => _isConnected = false);
      return;
    }

    try {
      final connected = await _bluetoothService.isConnected();
      setState(() => _isConnected = connected);
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  Future<void> _connectToPrinter() async {
    if (_config.bluetoothAddress.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Pilih printer terlebih dahulu',
        type: SnackbarType.warning,
      );
      return;
    }

    print('🔵 UI: Starting connection to ${_config.bluetoothAddress}');
    setState(() => _isConnecting = true);

    try {
      // Check Bluetooth permission first (Android 12+)
      final hasPermission = await PermissionService.requestBluetoothPermission(
        context,
      );
      if (!hasPermission) {
        setState(() => _isConnecting = false);
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: 'Izin Bluetooth diperlukan untuk menghubungkan ke printer',
            type: SnackbarType.warning,
          );
        }
        return;
      }

      // Check if Bluetooth is enabled
      final isBluetoothOn = await _bluetoothService.isBluetoothAvailable();
      if (!isBluetoothOn) {
        setState(() => _isConnecting = false);
        if (mounted) {
          _showBluetoothOffDialog();
        }
        return;
      }

      // Disconnect first if already connected
      if (_isConnected) {
        print('🔵 UI: Disconnecting from current device');
        await _bluetoothService.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('🔵 UI: Calling connectByAddress');
      final success = await _bluetoothService.connectByAddress(
        _config.bluetoothAddress,
      );

      print('🔵 UI: Connection result: $success');
      setState(() {
        _isConnecting = false;
        _isConnected = success;
      });

      if (mounted) {
        if (success) {
          CustomSnackbar.show(
            context,
            message: 'Berhasil terhubung ke ${_config.bluetoothDeviceName}',
            type: SnackbarType.success,
          );
        } else {
          CustomSnackbar.show(
            context,
            message:
                'Gagal terhubung ke ${_config.bluetoothDeviceName}.\n\n'
                'Kemungkinan penyebab:\n'
                '• Printer terhubung ke HP/device lain\n'
                '• Bluetooth HP belum aktif\n'
                '• Printer terlalu jauh (>10m)\n'
                '• Printer sedang digunakan\n\n'
                'Solusi: Disconnect printer dari device lain atau restart printer',
            type: SnackbarType.error,
          );
        }
      }
    } catch (e) {
      print('❌ UI: Error connecting: $e');
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error koneksi: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _testPrint() async {
    if (_config.bluetoothAddress.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Pilih printer terlebih dahulu',
        type: SnackbarType.warning,
      );
      return;
    }

    print('🖨️ UI: Starting test print');
    setState(() => _isPrinting = true);

    try {
      // Check Bluetooth permission first (Android 12+)
      final hasPermission = await PermissionService.requestBluetoothPermission(
        context,
      );
      if (!hasPermission) {
        setState(() => _isPrinting = false);
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: 'Izin Bluetooth diperlukan untuk mencetak',
            type: SnackbarType.warning,
          );
        }
        return;
      }

      // Check if Bluetooth is enabled
      final isBluetoothOn = await _bluetoothService.isBluetoothAvailable();
      if (!isBluetoothOn) {
        setState(() => _isPrinting = false);
        if (mounted) {
          _showBluetoothOffDialog();
        }
        return;
      }

      // Connect if not connected
      if (!_isConnected) {
        print('🖨️ UI: Not connected, attempting connection...');

        final connected = await _bluetoothService.connectByAddress(
          _config.bluetoothAddress,
        );

        if (!connected) {
          throw Exception(
            'Gagal terhubung ke printer. Pastikan printer dalam jangkauan dan tidak terhubung ke device lain.',
          );
        }

        setState(() => _isConnected = true);
        print('🖨️ UI: Connected successfully');

        // Wait for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Verify connection before printing
      final isStillConnected = await _bluetoothService.isConnected();
      if (!isStillConnected) {
        setState(() => _isConnected = false);
        throw Exception('Koneksi terputus. Coba hubungkan ulang.');
      }

      print('🖨️ UI: Creating printer settings');
      // Create printer settings
      final printerSettings = settings.PrinterSettings(
        printerType: settings.PrinterType.bluetooth,
        paperSize: _config.paperSize == PaperSize.mm58
            ? settings.PaperSize.mm58
            : settings.PaperSize.mm80,
        bluetoothAddress: _config.bluetoothAddress,
        networkIp: '',
        networkPort: 9100,
      );

      print('🖨️ UI: Sending test print');
      // Print test page
      final success = await _bluetoothService.printTestPage(printerSettings);

      setState(() => _isPrinting = false);
      print('🖨️ UI: Test print result: $success');

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: success
              ? 'Test print berhasil! Periksa printer Anda.'
              : 'Test print gagal. Coba lagi.',
          type: success ? SnackbarType.success : SnackbarType.error,
        );
      }
    } catch (e) {
      print('❌ UI: Test print error: $e');
      setState(() => _isPrinting = false);

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: ${e.toString()}',
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
                  onTap: () => _showAddressInputDialog(),
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

                // Connection Status & Actions
                if (_config.bluetoothAddress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildConnectionStatus(),
                  const SizedBox(height: 16),
                  _buildPrinterActions(),
                ],
              ],
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Terhubung' : 'Tidak Terhubung',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isConnected
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  _config.bluetoothDeviceName,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_isConnecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _checkConnectionStatus,
              color: _isConnected ? Colors.green : Colors.orange,
              tooltip: 'Cek Status',
            ),
        ],
      ),
    );
  }

  Widget _buildPrinterActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isConnecting ? null : _connectToPrinter,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                      ),
                label: Text(_isConnected ? 'Hubungkan Ulang' : 'Hubungkan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: _isConnected
                        ? Colors.green
                        : const Color(0xFFFF4B4B),
                  ),
                  foregroundColor: _isConnected
                      ? Colors.green
                      : const Color(0xFFFF4B4B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isPrinting ? null : _testPrint,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.print),
                label: const Text('Test Print'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFFFF4B4B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showTroubleshootingGuide,
          icon: const Icon(Icons.help_outline, size: 18),
          label: const Text('Panduan Troubleshooting'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showTroubleshootingGuide() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
                child: const Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Panduan Troubleshooting',
                        style: TextStyle(
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jika gagal terhubung, ikuti langkah berikut:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PENTING - Koneksi device lain
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PENTING!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD32F2F),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Printer Bluetooth hanya bisa terhubung ke 1 device. Disconnect dari HP/tablet lain terlebih dahulu!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Langkah-langkah troubleshooting
                      _buildTroubleshootItem(
                        '1',
                        'Pastikan Bluetooth HP aktif',
                      ),
                      _buildTroubleshootItem(
                        '2',
                        'Pastikan printer sudah paired di Settings > Bluetooth',
                      ),
                      _buildTroubleshootItem(
                        '3',
                        'DISCONNECT printer dari device lain (HP/tablet/PC)',
                      ),
                      _buildTroubleshootItem(
                        '4',
                        'Jika masih gagal, UNPAIR printer dari device lain',
                      ),
                      _buildTroubleshootItem(
                        '5',
                        'Printer dalam jangkauan (< 10 meter)',
                      ),
                      _buildTroubleshootItem(
                        '6',
                        'Restart printer (matikan, tunggu 5 detik, nyalakan)',
                      ),
                      _buildTroubleshootItem(
                        '7',
                        'Restart Bluetooth HP (off > on)',
                      ),
                      _buildTroubleshootItem(
                        '8',
                        'Terakhir: Unpair dan pair ulang printer di HP ini',
                      ),
                      const SizedBox(height: 16),

                      // Cara disconnect dari device lain
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Cara Disconnect dari Device Lain:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '1. Buka Bluetooth di HP/device lain\n'
                              '2. Tap nama printer yang terhubung\n'
                              '3. Pilih "Disconnect" atau "Forget"\n'
                              '4. Tunggu beberapa detik\n'
                              '5. Coba connect dari HP ini',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B4B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        color: Colors.white,
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
      ),
    );
  }

  Widget _buildTroubleshootItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4B4B).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
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

  void _showAddressInputDialog() {
    final tempController = TextEditingController(
      text: _outletAddressController.text,
    );
    bool isLoadingLocation = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                        AppImages.locationIcon,
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
                          'Alamat Outlet',
                          style: TextStyle(
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
                      // Info text
                      Text(
                        'Masukkan alamat atau sinkronkan dengan lokasi GPS Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Address input
                      TextField(
                        controller: tempController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Jl. Example No. 123, Jakarta',
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
                      const SizedBox(height: 16),
                      // Sync location button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoadingLocation
                              ? null
                              : () async {
                                  setDialogState(
                                    () => isLoadingLocation = true,
                                  );

                                  try {
                                    // Request location permission
                                    final hasPermission =
                                        await PermissionService.requestLocationPermission(
                                          context,
                                        );
                                    if (!hasPermission) {
                                      setDialogState(
                                        () => isLoadingLocation = false,
                                      );
                                      return;
                                    }

                                    // Get current position
                                    Position position =
                                        await Geolocator.getCurrentPosition(
                                          locationSettings:
                                              const LocationSettings(
                                                accuracy: LocationAccuracy.high,
                                              ),
                                        );

                                    // Reverse geocoding to get address
                                    List<Placemark> placemarks =
                                        await placemarkFromCoordinates(
                                          position.latitude,
                                          position.longitude,
                                        );

                                    if (placemarks.isNotEmpty) {
                                      final place = placemarks.first;
                                      final address =
                                          [
                                                if (place.street?.isNotEmpty ??
                                                    false)
                                                  place.street,
                                                if (place
                                                        .subLocality
                                                        ?.isNotEmpty ??
                                                    false)
                                                  place.subLocality,
                                                if (place
                                                        .locality
                                                        ?.isNotEmpty ??
                                                    false)
                                                  place.locality,
                                                if (place
                                                        .subAdministrativeArea
                                                        ?.isNotEmpty ??
                                                    false)
                                                  place.subAdministrativeArea,
                                                if (place
                                                        .administrativeArea
                                                        ?.isNotEmpty ??
                                                    false)
                                                  place.administrativeArea,
                                              ]
                                              .where(
                                                (e) =>
                                                    e != null && e.isNotEmpty,
                                              )
                                              .join(', ');

                                      tempController.text = address.isNotEmpty
                                          ? address
                                          : '${position.latitude}, ${position.longitude}';

                                      if (mounted) {
                                        CustomSnackbar.show(
                                          this.context,
                                          message:
                                              'Lokasi berhasil disinkronkan',
                                          type: SnackbarType.success,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      CustomSnackbar.show(
                                        this.context,
                                        message: 'Gagal mendapatkan lokasi: $e',
                                        type: SnackbarType.error,
                                      );
                                    }
                                  } finally {
                                    setDialogState(
                                      () => isLoadingLocation = false,
                                    );
                                  }
                                },
                          icon: isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF4B4B),
                                    ),
                                  ),
                                )
                              : SvgPicture.asset(
                                  AppImages.locationIcon,
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFFF4B4B),
                                    BlendMode.srcIn,
                                  ),
                                ),
                          label: Text(
                            isLoadingLocation
                                ? 'Mendapatkan lokasi...'
                                : 'Sinkronkan Lokasi GPS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF4B4B),
                            side: const BorderSide(
                              color: Color(0xFFFF4B4B),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                              onPressed: () async {
                                _outletAddressController.text =
                                    tempController.text;
                                _config = _config.copyWith(
                                  outletAddress: tempController.text,
                                );
                                // Sinkronkan ke user_location juga
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'user_location',
                                  tempController.text,
                                );
                                Navigator.pop(context);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4B4B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
      ),
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
                        if (!_isLoadingDevices)
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
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setDialogState(() {
                          _filterPrinters(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau alamat printer...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    _searchController.clear();
                                    _filterPrinters('');
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  // Content - Paired Devices Only
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildPairedDevicesList(setDialogState),
                  ),
                  // Close Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterPrinters('');
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

    // Show message if search has no results
    if (_filteredBluetoothDevices.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Printer tidak ditemukan',
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
                  'Coba kata kunci lain atau refresh daftar',
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
        itemCount: _filteredBluetoothDevices.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _filteredBluetoothDevices[index];
          final isSelected = device.macAdress == _config.bluetoothAddress;

          return ListTile(
            leading: Icon(
              Icons.print,
              color: isSelected ? const Color(0xFFFF4B4B) : Colors.grey,
            ),
            title: Text(
              device.name.isNotEmpty ? device.name : 'Unknown Device',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFF4B4B) : Colors.black87,
              ),
            ),
            subtitle: Text(
              device.macAdress,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFFFF4B4B))
                : null,
            onTap: () {
              setState(() {
                _config = _config.copyWith(
                  bluetoothAddress: device.macAdress,
                  bluetoothDeviceName: device.name.isNotEmpty
                      ? device.name
                      : 'Unknown',
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
