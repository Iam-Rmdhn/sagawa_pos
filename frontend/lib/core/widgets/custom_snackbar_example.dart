import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';

class CustomSnackbarExample extends StatelessWidget {
  const CustomSnackbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Snackbar Examples')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                CustomSnackbar.show(
                  context,
                  message: 'Data berhasil disimpan!',
                  type: SnackbarType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Show Success Snackbar'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                CustomSnackbar.show(
                  context,
                  message: 'Terjadi kesalahan saat menyimpan data',
                  type: SnackbarType.error,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
              ),
              child: const Text('Show Error Snackbar'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                CustomSnackbar.show(
                  context,
                  message: 'Fitur ini akan segera hadir',
                  type: SnackbarType.info,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Show Info Snackbar'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                CustomSnackbar.show(
                  context,
                  message: 'Mohon lengkapi semua field terlebih dahulu',
                  type: SnackbarType.warning,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
              ),
              child: const Text('Show Warning Snackbar'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                CustomSnackbar.show(
                  context,
                  message: 'Koneksi internet terputus',
                  type: SnackbarType.warning,
                  title: 'Tidak Ada Koneksi',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Custom Title'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                CustomSnackbar.show(
                  context,
                  message: 'Pesan ini akan muncul selama 5 detik',
                  type: SnackbarType.info,
                  duration: const Duration(seconds: 5),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Custom Duration (5s)'),
            ),
          ],
        ),
      ),
    );
  }
}
