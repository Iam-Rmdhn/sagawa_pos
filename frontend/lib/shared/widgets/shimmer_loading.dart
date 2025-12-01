import 'package:flutter/material.dart';

/// Widget untuk membuat efek shimmer loading
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey.shade300;
    final highlightColor = widget.highlightColor ?? Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Container shimmer dengan bentuk kotak
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Container shimmer dengan bentuk lingkaran
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// SKELETON LOADERS UNTUK BERBAGAI PAGE
// ============================================================================

/// Skeleton loader untuk Home Page - Grid Menu
class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          // App Bar Skeleton
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const ShimmerCircle(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerBox(width: 100, height: 14),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: 12,
                          ),
                        ],
                      ),
                    ),
                    const ShimmerCircle(size: 40),
                    const SizedBox(width: 8),
                    const ShimmerCircle(size: 40),
                  ],
                ),
                const SizedBox(height: 16),
                const ShimmerBox(
                  width: double.infinity,
                  height: 48,
                  borderRadius: 24,
                ),
              ],
            ),
          ),

          // Category Skeleton
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ShimmerBox(
                  width: index == 0 ? 70 : 90,
                  height: 36,
                  borderRadius: 18,
                );
              },
            ),
          ),

          // Menu Grid Skeleton
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const _MenuCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCardSkeleton extends StatelessWidget {
  const _MenuCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
            ),
          ),
          // Info placeholder
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 100, height: 14),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerBox(width: 70, height: 16),
                        const SizedBox(height: 4),
                        const ShimmerBox(width: 50, height: 12),
                      ],
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
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

/// Skeleton loader untuk Order History Page
class OrderHistorySkeleton extends StatelessWidget {
  const OrderHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const _OrderHistoryCardSkeleton(),
      ),
    );
  }
}

class _OrderHistoryCardSkeleton extends StatelessWidget {
  const _OrderHistoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 120, height: 16),
                const SizedBox(height: 8),
                const ShimmerBox(width: 100, height: 13),
              ],
            ),
          ),
          const ShimmerBox(width: 24, height: 24, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk Menu Management Page
class MenuManagementSkeleton extends StatelessWidget {
  const MenuManagementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => const _MenuManagementCardSkeleton(),
      ),
    );
  }
}

class _MenuManagementCardSkeleton extends StatelessWidget {
  const _MenuManagementCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          const ShimmerBox(width: 80, height: 80, borderRadius: 12),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 120, height: 16),
                const SizedBox(height: 4),
                const ShimmerBox(width: 80, height: 15),
                const SizedBox(height: 8),
                const ShimmerBox(width: 70, height: 24, borderRadius: 6),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const ShimmerBox(width: 50, height: 28, borderRadius: 14),
              const SizedBox(height: 16),
              const ShimmerBox(width: 80, height: 40, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk Financial Report Page
class FinancialReportSkeleton extends StatelessWidget {
  const FinancialReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const ShimmerBox(width: 180, height: 20),
            const SizedBox(height: 12),

            // Revenue Cards
            Row(
              children: [
                Expanded(child: _buildRevenueCardSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildRevenueCardSkeleton()),
              ],
            ),
            const SizedBox(height: 12),
            _buildRevenueCardSkeleton(isLarge: true),
            const SizedBox(height: 24),

            // Chart Section
            _buildChartSkeleton(),
            const SizedBox(height: 24),

            // Pie Chart Section
            _buildPieChartSkeleton(),
            const SizedBox(height: 24),

            // Table Section
            _buildTableSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCardSkeleton({bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 70, height: isLarge ? 14 : 12),
          const SizedBox(height: 8),
          ShimmerBox(width: 120, height: isLarge ? 22 : 18),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerBox(width: 140, height: 18),
              const ShimmerBox(width: 80, height: 30, borderRadius: 15),
            ],
          ),
          const SizedBox(height: 24),
          // Chart placeholder
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Y axis lines
                for (int i = 0; i < 5; i++)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 44.0 * i,
                    child: Container(height: 1, color: Colors.grey.shade200),
                  ),
                // Bars placeholder
                Positioned(
                  left: 50,
                  right: 20,
                  bottom: 30,
                  top: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final heights = [
                        60.0,
                        100.0,
                        80.0,
                        140.0,
                        120.0,
                        90.0,
                        110.0,
                      ];
                      return ShimmerBox(
                        width: 8,
                        height: heights[index],
                        borderRadius: 4,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 120, height: 18),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie chart placeholder
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 180,
                  child: Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItemSkeleton(),
                    const SizedBox(height: 16),
                    _buildLegendItemSkeleton(),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItemSkeleton() {
    return Row(
      children: [
        const ShimmerBox(width: 16, height: 16, borderRadius: 4),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 60, height: 13),
            const SizedBox(height: 4),
            const ShimmerBox(width: 70, height: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildTableSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 130, height: 18),
                Row(
                  children: [
                    const ShimmerBox(width: 80, height: 30, borderRadius: 15),
                    const SizedBox(width: 8),
                    const ShimmerBox(width: 60, height: 32, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
          // Table header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const ShimmerBox(width: 60, height: 12),
                const Spacer(),
                const ShimmerBox(width: 60, height: 12),
                const Spacer(),
                const ShimmerBox(width: 40, height: 12),
                const Spacer(),
                const ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
          // Table rows
          ...List.generate(5, (index) => _buildTableRowSkeleton()),
          // Pagination
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 100, height: 12),
                Row(
                  children: [
                    const ShimmerBox(width: 32, height: 32, borderRadius: 8),
                    const SizedBox(width: 12),
                    const ShimmerBox(width: 40, height: 14),
                    const SizedBox(width: 12),
                    const ShimmerBox(width: 32, height: 32, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 80, height: 12),
          const Spacer(),
          const ShimmerBox(width: 70, height: 12),
          const Spacer(),
          const ShimmerBox(width: 50, height: 20, borderRadius: 10),
          const Spacer(),
          const ShimmerBox(width: 60, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk Profile Page
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    // App bar
                    Row(
                      children: [
                        const ShimmerCircle(size: 24),
                        const Expanded(
                          child: Center(
                            child: ShimmerBox(width: 60, height: 20),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Profile photo and info
                    Row(
                      children: [
                        const ShimmerCircle(size: 120),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ShimmerBox(width: 150, height: 24),
                              const SizedBox(height: 8),
                              const ShimmerBox(width: 120, height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Fields
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFieldSkeleton(),
                  const SizedBox(height: 24),
                  _buildFieldSkeleton(),
                  const SizedBox(height: 24),
                  _buildFieldSkeleton(),
                  const SizedBox(height: 24),
                  _buildFieldSkeleton(),
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: const ShimmerBox(
              width: double.infinity,
              height: 56,
              borderRadius: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ShimmerBox(width: double.infinity, height: 20),
    );
  }
}

/// Skeleton loader untuk Settings Page
class SettingsPageSkeleton extends StatelessWidget {
  const SettingsPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: 5,
        separatorBuilder: (_, __) =>
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const ShimmerBox(width: 24, height: 24, borderRadius: 4),
              const SizedBox(width: 16),
              Expanded(child: const ShimmerBox(width: 100, height: 16)),
              if (index == 4)
                const ShimmerBox(width: 50, height: 28, borderRadius: 14)
              else
                const ShimmerBox(width: 24, height: 24, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader untuk Order Detail Page
class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Order info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(width: 100, height: 16),
                      const ShimmerBox(width: 80, height: 24, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ShimmerBox(width: 80, height: 14),
                      const ShimmerBox(width: 120, height: 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items list
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderItemSkeleton(),
              ),
            ),

            const SizedBox(height: 16),

            // Total section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTotalRowSkeleton(),
                  const SizedBox(height: 8),
                  _buildTotalRowSkeleton(),
                  const Divider(height: 24),
                  _buildTotalRowSkeleton(isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 60, height: 60, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 120, height: 14),
                const SizedBox(height: 6),
                const ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
          const ShimmerBox(width: 70, height: 16),
        ],
      ),
    );
  }

  Widget _buildTotalRowSkeleton({bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShimmerBox(width: isTotal ? 60 : 80, height: isTotal ? 16 : 14),
        ShimmerBox(width: isTotal ? 100 : 80, height: isTotal ? 18 : 14),
      ],
    );
  }
}

/// Skeleton loader untuk Payment Page
class PaymentMethodSkeleton extends StatelessWidget {
  const PaymentMethodSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          // Order summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerBox(width: 80, height: 14),
                    const ShimmerBox(width: 100, height: 14),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerBox(width: 60, height: 14),
                    const ShimmerBox(width: 80, height: 14),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerBox(width: 50, height: 16),
                    const ShimmerBox(width: 120, height: 20),
                  ],
                ),
              ],
            ),
          ),

          // Payment methods
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 140, height: 18),
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const ShimmerBox(width: 40, height: 40, borderRadius: 8),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerBox(width: 80, height: 14),
                          const SizedBox(height: 4),
                          const ShimmerBox(width: 120, height: 12),
                        ],
                      ),
                    ),
                    const ShimmerCircle(size: 24),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: const ShimmerBox(
              width: double.infinity,
              height: 56,
              borderRadius: 16,
            ),
          ),
        ],
      ),
    );
  }
}
