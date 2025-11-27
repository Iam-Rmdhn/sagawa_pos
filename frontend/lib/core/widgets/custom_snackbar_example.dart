import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';

/// Example usage of CustomSnackbar
///
/// Dokumentasi penggunaan CustomSnackbar di berbagai skenario
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
            // Success Snackbar - Hijau
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

            // Error Snackbar - Merah
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

            // Info Snackbar - Biru
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

            // Warning Snackbar - Orange
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

            // Custom Title
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

            // Custom Duration
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

/// Contoh penggunaan di dalam BLoC/Cubit listener
/// 
/// ```dart
/// BlocConsumer<MyCubit, MyState>(
///   listener: (context, state) {
///     if (state is SuccessState) {
///       CustomSnackbar.show(
///         context,
///         message: 'Operasi berhasil!',
///         type: SnackbarType.success,
///       );
///     } else if (state is ErrorState) {
///       CustomSnackbar.show(
///         context,
///         message: state.errorMessage,
///         type: SnackbarType.error,
///       );
///     }
///   },
///   builder: (context, state) {
///     // Your UI here
///   },
/// )
/// ```

/// Contoh penggunaan di dalam onPressed button
/// 
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     try {
///       await saveData();
///       CustomSnackbar.show(
///         context,
///         message: 'Data tersimpan',
///         type: SnackbarType.success,
///       );
///     } catch (e) {
///       CustomSnackbar.show(
///         context,
///         message: 'Gagal menyimpan: $e',
///         type: SnackbarType.error,
///       );
///     }
///   },
///   child: const Text('Simpan'),
/// )
/// ```
