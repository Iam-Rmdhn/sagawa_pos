import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Request location permission
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

    // Request for the first time
    final result = await Permission.location.request();
    return result.isGranted;
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // For Android 13+ (API 33+), use photos/videos/audio permissions
    // For older versions, use storage permission
    PermissionStatus status;

    if (await Permission.photos.isRestricted) {
      // Android 13+ or iOS
      status = await Permission.photos.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.photos.request();
        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(
              context,
              'Izin Penyimpanan Diperlukan',
              'Aplikasi memerlukan akses ke galeri untuk memilih foto produk. Silakan aktifkan di pengaturan.',
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

      final result = await Permission.photos.request();
      return result.isGranted;
    } else {
      // Android 12 and below
      status = await Permission.storage.status;

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
              'Aplikasi memerlukan akses ke penyimpanan untuk menyimpan foto. Silakan aktifkan di pengaturan.',
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
  }

  /// Request camera permission
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

  /// Request notification permission (for Android 13+)
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

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    if (await Permission.photos.isRestricted) {
      return await Permission.photos.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Show dialog when permission is permanently denied
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

  /// Request multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
