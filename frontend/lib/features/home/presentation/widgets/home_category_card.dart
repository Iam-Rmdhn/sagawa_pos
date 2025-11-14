import 'package:flutter/material.dart';

class HomeCategoryOption {
  const HomeCategoryOption({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

class HomeCategoryCard extends StatelessWidget {
  const HomeCategoryCard({
    super.key,
    required this.categories,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<HomeCategoryOption> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: Color(0xFF1F1F1F),
      fontSize: 18,
      fontWeight: FontWeight.w800,
    );
    const primaryColor = Color(0xFFF7D772);
    const idleIconBackground = Color(0xFFFFF2C8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori', style: titleStyle),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(categories.length, (index) {
                final category = categories[index];
                final selected = index == selectedIndex;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 12,
                  ),
                  child: GestureDetector(
                    onTap: () => onSelected?.call(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 96,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: selected
                            ? const LinearGradient(
                                colors: [Color(0xFFF7D772), Color(0xFFEFA348)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: selected ? null : primaryColor,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : idleIconBackground,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              category.assetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF4C4C4C),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
