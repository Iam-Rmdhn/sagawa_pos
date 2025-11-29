import 'package:flutter/material.dart';

class HomeCategoryCard extends StatefulWidget {
  const HomeCategoryCard({
    super.key,
    required this.categories,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  State<HomeCategoryCard> createState() => _HomeCategoryCardState();
}

class _HomeCategoryCardState extends State<HomeCategoryCard> {
  final _scrollController = ScrollController();
  bool _isFirstStripeActive = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final clampedOffset = _scrollController.offset.clamp(0, maxExtent);
    final isFirst = maxExtent == 0 ? true : (clampedOffset / maxExtent) < 0.5;
    if (isFirst != _isFirstStripeActive) {
      setState(() => _isFirstStripeActive = isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: Color(0xFF1F1F1F),
      fontSize: 18,
      fontWeight: FontWeight.w900,
    );

    return Container(
      color: const Color.fromARGB(255, 250, 250, 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: const Text('Kategori', style: titleStyle),
          ),
          Column(
            children: [
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final isSelected = index == widget.selectedIndex;
                    return GestureDetector(
                      onTap: () => widget.onSelected?.call(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFA348)
                              : const Color(0xFFF4D98A),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Center(
                          child: Text(
                            category,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF3A3A3A),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: widget.categories.length,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PaginationStripe(isActive: _isFirstStripeActive),
                    const SizedBox(width: 8),
                    _PaginationStripe(isActive: !_isFirstStripeActive),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationStripe extends StatelessWidget {
  const _PaginationStripe({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: isActive ? 6 : 6,
      width: isActive ? 32 : 24,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE84A3A) : const Color(0xFFB7B7B7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
