import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/home/presentation/widgets/home_app_bar.dart';
import 'package:sagawa_pos_new/features/home/presentation/widgets/home_category_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final List<HomeCategoryOption> _categories = const [
    HomeCategoryOption(label: 'Semua', assetPath: AppImages.allMenu),
    HomeCategoryOption(label: 'Best Seller', assetPath: AppImages.bestSeller),
    HomeCategoryOption(label: 'Ala Carte', assetPath: AppImages.alaCarte),
    HomeCategoryOption(label: 'Coffee', assetPath: AppImages.coffee),
    HomeCategoryOption(label: 'Non Coffee', assetPath: AppImages.nonCoffee),
  ];
  int _selectedCategory = 0;

  final List<_ProductData> _products = const [
    _ProductData(title: 'Sate Ayam Original', priceLabel: 'Rp 20.000'),
    _ProductData(title: 'Sate Ayam Pedas', priceLabel: 'Rp 20.000'),
    _ProductData(title: 'Sate Kulit Crispy', priceLabel: 'Rp 20.000'),
    _ProductData(title: 'Sate Mix Favorit', priceLabel: 'Rp 20.000'),
    _ProductData(title: 'Sate Mozarella', priceLabel: 'Rp 20.000'),
    _ProductData(title: 'Sate Manis', priceLabel: 'Rp 20.000'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 252, 252, 252),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(
                    height: 205,
                    child: HomeAppBarCard(
                      locationLabel: 'Jl. Mampang Prapatan No.18',
                      onMenuTap: () {},
                      onFilterTap: () {},
                      searchController: _searchController,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: HomeCategoryCard(
                      categories: _categories,
                      selectedIndex: _selectedCategory,
                      onSelected: (index) {
                        setState(() => _selectedCategory = index);
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _ProductCard(product: _products[index]),
                      childCount: _products.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _CartSummaryCard(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductData {
  const _ProductData({required this.title, required this.priceLabel});

  final String title;
  final String priceLabel;
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _ProductData product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Image.asset(
                AppImages.onboardingIllustration,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      product.priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1 Item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Ketuk untuk melihat',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Text(
            '50.000',
            style: TextStyle(
              color: Color(0xFF22A45D),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B4B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({required double height, required this.child})
    : minExtent = height,
      maxExtent = height;

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}
