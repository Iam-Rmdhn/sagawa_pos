import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/bloc/receipt_cubit.dart';

class BluetoothPrinterSelectionPage extends StatefulWidget {
  const BluetoothPrinterSelectionPage({super.key});

  @override
  State<BluetoothPrinterSelectionPage> createState() =>
      _BluetoothPrinterSelectionPageState();
}

class _BluetoothPrinterSelectionPageState
    extends State<BluetoothPrinterSelectionPage> {
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cubit = context.read<ReceiptCubit>();
      final devices = await cubit.getBluetoothDevices();
      setState(() {
        _devices = devices.cast<BluetoothDevice>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading devices: $e')));
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
      _selectedDevice = device;
    });

    try {
      final cubit = context.read<ReceiptCubit>();

      // Disconnect terlebih dahulu jika masih ada koneksi
      await cubit.disconnectBluetooth();

      // Retry logic - coba 2 kali
      bool success = false;
      String? errorMessage;

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          success = await cubit.connectBluetoothPrinter(device);
          if (success) break;

          if (attempt < 2) {
            // Wait before retry
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          errorMessage = e.toString();
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil terhubung ke printer')),
          );
          Navigator.pop(context, device);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal terhubung ke printer${errorMessage != null ? ': $errorMessage' : ''}',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _testPrint(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cubit = context.read<ReceiptCubit>();

      // Connect if not connected
      final isConnected = await cubit.isBluetoothConnected();
      if (!isConnected) {
        final connected = await cubit.connectBluetoothPrinter(device);
        if (!connected) {
          throw Exception('Gagal terhubung ke printer');
        }
      }

      // Print test page
      final success = await cubit.printTestPage();

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print berhasil' : 'Test print gagal'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Printer Bluetooth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada perangkat Bluetooth ditemukan',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pastikan Bluetooth aktif dan printer sudah dipair',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadDevices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final isSelected = _selectedDevice == device;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.print,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      device.name ?? 'Unknown Device',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.address ?? 'No address'),
                        if (isSelected)
                          const Text(
                            'Connected',
                            style: TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print_outlined),
                          onPressed: () => _testPrint(device),
                          tooltip: 'Test Print',
                        ),
                        IconButton(
                          icon: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.bluetooth_connected,
                          ),
                          onPressed: () => _connectToDevice(device),
                          tooltip: 'Connect',
                          color: isSelected ? Colors.green : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
