import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Izin Lokasi Diperlukan',
            'Aplikasi memerlukan akses lokasi untuk menampilkan alamat toko Anda. Silakan aktifkan di pengaturan.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Izin Lokasi Diblokir',
          'Anda telah menolak izin lokasi secara permanen. Silakan aktifkan di pengaturan aplikasi.',
        );
      }
      return false;
    }

    final result = await Permission.location.request();
    return result.isGranted;
  }

  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final photosStatus = await Permission.photos.status;

    if (photosStatus == PermissionStatus.restricted) {
      return await _requestLegacyStoragePermission(context);
    }

    if (photosStatus.isGranted) {
      return true;
    }

    if (photosStatus.isDenied) {
      final result = await Permission.photos.request();
      if (result.isGranted || result.isLimited) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Izin Akses Media Diperlukan',
            'Aplikasi memerlukan akses ke foto dan media untuk memilih gambar. Silakan aktifkan di pengaturan.',
          );
        }
        return false;
      }
      return false;
    }

    if (photosStatus.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Izin Akses Media Diblokir',
          'Anda telah menolak izin akses media secara permanen. Silakan aktifkan di pengaturan aplikasi.',
        );
      }
      return false;
    }

    if (photosStatus.isLimited) {
      return true;
    }

    final result = await Permission.photos.request();
    return result.isGranted || result.isLimited;
  }

  static Future<bool> _requestLegacyStoragePermission(
    BuildContext context,
  ) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Izin Penyimpanan Diperlukan',
            'Aplikasi memerlukan akses ke penyimpanan untuk menyimpan file. Silakan aktifkan di pengaturan.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Izin Penyimpanan Diblokir',
          'Anda telah menolak izin penyimpanan secara permanen. Silakan aktifkan di pengaturan aplikasi.',
        );
      }
      return false;
    }

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  static Future<bool> requestDownloadPermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.storage.status;

    if (status.isGranted || status.isRestricted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      return true;
    }

    return true;
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Izin Kamera Diperlukan',
            'Aplikasi memerlukan akses kamera untuk mengambil foto produk. Silakan aktifkan di pengaturan.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Izin Kamera Diblokir',
          'Anda telah menolak izin kamera secara permanen. Silakan aktifkan di pengaturan aplikasi.',
        );
      }
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  static Future<bool> requestBluetoothPermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final connectStatus = await Permission.bluetoothConnect.status;

      if (connectStatus == PermissionStatus.restricted) {
        print('📱 Android 11 or below - Bluetooth permissions auto-granted');
        return true;
      }

      print('📱 Android 12+ detected - requesting Bluetooth permissions');

      if (!connectStatus.isGranted) {
        print('📱 Requesting BLUETOOTH_CONNECT permission');
        final connectResult = await Permission.bluetoothConnect.request();

        if (connectResult.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(
              context,
              'Izin Bluetooth Diperlukan',
              'Aplikasi memerlukan akses Bluetooth untuk menghubungkan ke printer thermal. Silakan aktifkan izin "Nearby devices" atau "Perangkat terdekat" di pengaturan.',
            );
          }
          return false;
        }

        if (!connectResult.isGranted) {
          print('❌ BLUETOOTH_CONNECT permission denied');
          return false;
        }
      }

      final scanStatus = await Permission.bluetoothScan.status;
      if (!scanStatus.isGranted && scanStatus != PermissionStatus.restricted) {
        print('📱 Requesting BLUETOOTH_SCAN permission');
        final scanResult = await Permission.bluetoothScan.request();

        if (scanResult.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(
              context,
              'Izin Scan Bluetooth Diperlukan',
              'Aplikasi memerlukan izin untuk mencari perangkat Bluetooth. Silakan aktifkan di pengaturan.',
            );
          }
          return false;
        }

        if (!scanResult.isGranted &&
            scanResult != PermissionStatus.restricted) {
          print('❌ BLUETOOTH_SCAN permission denied');
        }
      }

      print('✅ Bluetooth permissions granted');
      return true;
    } catch (e) {
      print('❌ Error requesting Bluetooth permission: $e');

      return true;
    }
  }

  static Future<bool> isBluetoothPermissionGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final connectStatus = await Permission.bluetoothConnect.status;

      if (connectStatus == PermissionStatus.restricted) {
        return true;
      }

      return connectStatus.isGranted;
    } catch (e) {
      print('❌ Error checking Bluetooth permission: $e');
      return true;
    }
  }

  static Future<bool> requestNotificationPermission(
    BuildContext context,
  ) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDeniedDialog(
            context,
            'Izin Notifikasi Diperlukan',
            'Aplikasi memerlukan akses notifikasi untuk memberi tahu Anda tentang pesanan baru. Silakan aktifkan di pengaturan.',
          );
        }
        return false;
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Izin Notifikasi Diblokir',
          'Anda telah menolak izin notifikasi secara permanen. Silakan aktifkan di pengaturan aplikasi.',
          showOpenSettings: true,
        );
      }
      return false;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  static Future<bool> isStoragePermissionGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final photosStatus = await Permission.photos.status;
    if (photosStatus != PermissionStatus.restricted) {
      return photosStatus.isGranted || photosStatus.isLimited;
    }

    return await Permission.storage.isGranted;
  }

  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> ensureBluetoothPermission(BuildContext context) async {
    if (!context.mounted) return false;
    return await requestBluetoothPermission(context);
  }

  static Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message, {
    bool showOpenSettings = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF4B4B),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          if (showOpenSettings)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Buka Pengaturan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
