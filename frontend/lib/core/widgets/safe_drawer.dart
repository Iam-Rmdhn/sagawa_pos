import 'package:flutter/material.dart';

/// Safe Drawer Builder untuk menghindari crash saat membuka drawer
/// Menangani masalah context dan theme loading
class SafeDrawerBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const SafeDrawerBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    // Pastikan theme sudah loaded sebelum build drawer
    return FutureBuilder(
      future: Future.delayed(Duration.zero),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return builder(context);
      },
    );
  }
}

/// Extension untuk safe drawer opening
extension SafeScaffoldExtension on ScaffoldState {
  void safeOpenDrawer() {
    try {
      openDrawer();
    } catch (e) {
      debugPrint('Error opening drawer: $e');
    }
  }
}
