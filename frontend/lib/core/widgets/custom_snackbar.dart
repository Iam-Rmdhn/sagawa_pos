import 'package:flutter/material.dart';

enum SnackbarType { success, error, info, warning }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Get colors based on type
    final colors = _getColors(type);
    final icon = _getIcon(type);
    final defaultTitle = _getTitle(type);

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackbarWidget(
        message: message,
        title: title ?? defaultTitle,
        backgroundColor: colors['background']!,
        textColor: colors['text']!,
        icon: icon,
        onDismiss: () {
          overlayEntry.remove();
        },
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static Map<String, Color> _getColors(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return {'background': const Color(0xFF4CAF50), 'text': Colors.white};
      case SnackbarType.error:
        return {'background': const Color(0xFFFF4B4B), 'text': Colors.white};
      case SnackbarType.info:
        return {'background': const Color(0xFF2196F3), 'text': Colors.white};
      case SnackbarType.warning:
        return {'background': const Color(0xFFFF9800), 'text': Colors.white};
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.info:
        return Icons.info;
      case SnackbarType.warning:
        return Icons.warning;
    }
  }

  static String _getTitle(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return 'Berhasil';
      case SnackbarType.error:
        return 'Error';
      case SnackbarType.info:
        return 'Info';
      case SnackbarType.warning:
        return 'Peringatan';
    }
  }
}

class _CustomSnackbarWidget extends StatefulWidget {
  final String message;
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onDismiss;
  final Duration duration;

  const _CustomSnackbarWidget({
    required this.message,
    required this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_CustomSnackbarWidget> createState() => _CustomSnackbarWidgetState();
}

class _CustomSnackbarWidgetState extends State<_CustomSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Slide from right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto dismiss animation
    Future.delayed(widget.duration - const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Progress bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: 1 - _controller.value,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.4),
                            ),
                            minHeight: 3,
                          );
                        },
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Icon(widget.icon, color: widget.textColor, size: 28),
                          const SizedBox(width: 12),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: widget.textColor.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Close button
                          GestureDetector(
                            onTap: () {
                              _controller.reverse().then((_) {
                                widget.onDismiss();
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: widget.textColor.withOpacity(0.8),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
