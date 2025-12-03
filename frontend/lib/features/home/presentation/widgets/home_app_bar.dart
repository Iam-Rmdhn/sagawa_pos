import 'package:flutter/material.dart';

class HomeAppBarCard extends StatelessWidget {
  const HomeAppBarCard({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.searchController,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 20),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.menu, onTap: onMenuTap),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF444444)),
                    SizedBox(width: 12),
                    Text(
                      'Cari menu lainnya...',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
            ),
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
