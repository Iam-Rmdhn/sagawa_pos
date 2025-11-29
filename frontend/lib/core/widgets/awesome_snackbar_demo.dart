import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';

class AwesomeSnackbarDemo extends StatelessWidget {
  const AwesomeSnackbarDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awesome Snackbar Demo'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                const Icon(
                  Icons.notifications_active,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Custom Snackbar Demo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Top-right position • Smooth animation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // SUCCESS Button
                _AwesomeButton(
                  label: 'SUCCESS',
                  subtitle: 'Operasi berhasil',
                  color: const Color(0xFF00E676),
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    CustomSnackbar.show(
                      context,
                      message: 'Printer berhasil terhubung dan siap digunakan!',
                      type: SnackbarType.success,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ERROR Button
                _AwesomeButton(
                  label: 'ERROR',
                  subtitle: 'Terjadi kesalahan',
                  color: const Color(0xFFFF1744),
                  icon: Icons.error_outline,
                  onPressed: () {
                    CustomSnackbar.show(
                      context,
                      message:
                          'Gagal menyimpan konfigurasi. Silakan coba lagi.',
                      type: SnackbarType.error,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // INFO Button
                _AwesomeButton(
                  label: 'INFO',
                  subtitle: 'Informasi penting',
                  color: const Color(0xFF2979FF),
                  icon: Icons.info_outline,
                  onPressed: () {
                    CustomSnackbar.show(
                      context,
                      message: 'Fitur multi-bahasa akan segera hadir.',
                      type: SnackbarType.info,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // WARNING Button
                _AwesomeButton(
                  label: 'WARNING',
                  subtitle: 'Peringatan',
                  color: const Color(0xFFFF9100),
                  icon: Icons.warning_amber_outlined,
                  onPressed: () {
                    CustomSnackbar.show(
                      context,
                      message: 'Harap isi nama restoran sebelum menyimpan.',
                      type: SnackbarType.warning,
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Divider
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 24),

                // Custom Duration Example
                OutlinedButton.icon(
                  onPressed: () {
                    CustomSnackbar.show(
                      context,
                      message:
                          'Snackbar ini akan tampil selama 5 detik dengan custom title',
                      type: SnackbarType.info,
                      title: 'Custom Duration',
                      duration: const Duration(seconds: 5),
                    );
                  },
                  icon: const Icon(Icons.timer, color: Colors.white70),
                  label: const Text(
                    'Custom Duration (5s)',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                const SizedBox(height: 16),

                // Features Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.amber.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Fitur Unggulan:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FeatureItem(
                        'Posisi top-right (tidak menghalangi konten)',
                      ),
                      _FeatureItem('Animasi smooth slide + fade'),
                      _FeatureItem('Progress bar waktu tersisa'),
                      _FeatureItem('Auto-dismiss & manual close'),
                      _FeatureItem('4 warna vibrant yang eye-catching'),
                      _FeatureItem('Shadow effect yang elegan'),
                      _FeatureItem('Icon dengan background circle'),
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
}

class _AwesomeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _AwesomeButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade300, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
