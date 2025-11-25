import 'package:flutter/material.dart';

/// Sticky red header used on the home screen and other pages that
/// need the same layout.
class HomeAppBarCard extends StatelessWidget {
  const HomeAppBarCard({
    super.key,
    required this.locationLabel,
    this.onMenuTap,
    this.onFilterTap,
    this.onLocationTap,
    this.onSearchChanged,
    this.searchController,
  });

  final String locationLabel;
  final VoidCallback? onMenuTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onLocationTap;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF4B4B), Color(0xFFFF4B4B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIconButton(icon: Icons.menu, onTap: onMenuTap),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onLocationTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC2BA),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FFFFFF),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFB82E2E),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationLabel,
                            style: const TextStyle(
                              color: Color.fromARGB(153, 139, 28, 28),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Cari menu lainnya...',
                      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                      icon: Icon(Icons.search, color: Color(0xFF444444)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _CircleIconButton(icon: Icons.tune, onTap: onFilterTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3A2F2F)),
      ),
    );
  }
}
