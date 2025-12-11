import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/utils/indonesia_time.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';
import 'package:sagawa_pos_new/features/order_history/presentation/cubit/order_history_cubit.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/grouped_order_by_date.dart';
import 'package:sagawa_pos_new/features/order_history/presentation/pages/order_detail_page.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _applyTabFilter(_tabController.index);
  }

  void _applyTabFilter(int index) {
    final cubit = context.read<OrderHistoryCubit>();
    final now = IndonesiaTime.now();

    switch (index) {
      case 0: // Semua
        cubit.resetFilter();
        break;
      case 1: // Harian
        cubit.filterByDate(now, 'Hari Ini');
        break;
      case 2: // Mingguan
        final startOfWeek = IndonesiaTime.startOfWeek(now);
        final endOfWeek = IndonesiaTime.endOfWeek(now);
        cubit.filterByDateRange(startOfWeek, endOfWeek, 'Minggu Ini');
        break;
      case 3: // Bulanan
        final startOfMonth = IndonesiaTime.startOfMonth(now);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        cubit.filterByDateRange(startOfMonth, endOfMonth, 'Bulan Ini');
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    // Check if cubit still has filter applied
    final cubit = context.read<OrderHistoryCubit>();
    if (cubit.state.filterLabel != null) {
      if (cubit.state.selectedDate != null) {
        cubit.filterByDate(cubit.state.selectedDate!, cubit.state.filterLabel!);
      }
    } else {
      cubit.loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveHelper.isTabletLandscape(context);
    final borderRadius = isCompact ? 24.0 : 32.0;
    final titleFontSize = isCompact ? 17.0 : 20.0;
    final filterIconSize = isCompact ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B4B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: isCompact ? kToolbarHeight * 0.85 : kToolbarHeight,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: isCompact ? 22 : 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Riwayat Pemesanan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            AppImages.filterIcon,
                            width: filterIconSize,
                            height: filterIconSize,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => _showFilterDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 16,
              isCompact ? 10 : 16,
              isCompact ? 12 : 16,
              isCompact ? 6 : 8,
            ),
            child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
              builder: (context, state) {
                // Hitung total transaksi dari semua grouped orders
                final totalTransactions = state.groupedOrders.fold<int>(
                  0,
                  (sum, group) => sum + group.transactionCount,
                );

                return Row(
                  children: [
                    // Filter Indicator (Left)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: isCompact ? 6 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '$totalTransactions Riwayat',
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4B4B),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _tabController.index,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: isCompact ? 18 : 20,
                          ),
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 8 : 12,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Semua')),
                            DropdownMenuItem(value: 1, child: Text('Hari ini')),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Minggu ini'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('Bulan ini'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _tabController.index = value;
                              });
                              _applyTabFilter(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Body content
          Expanded(
            child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const _OrderHistorySkeleton();
                }

                if (state.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<OrderHistoryCubit>().loadOrders();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4B4B),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.groupedOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/no_data.json',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Riwayat Pesanan Kosong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada transaksi yang tercatat',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFFFF4B4B),
                  onRefresh: () async {
                    _loadOrders();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getPadding(context),
                    ),
                    itemCount: state.groupedOrders.length,
                    itemBuilder: (context, index) {
                      final groupedOrder = state.groupedOrders[index];
                      return _GroupedOrderCard(
                        key: ValueKey(groupedOrder.date.toIso8601String()),
                        groupedOrder: groupedOrder,
                        onTap: () {
                          // Navigate ke halaman detail untuk melihat semua transaksi dalam grup
                          _showOrdersForDate(context, groupedOrder);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrdersForDate(
    BuildContext context,
    GroupedOrderByDate groupedOrder,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupedOrder.shortFormattedDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${groupedOrder.transactionCount} transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // List of orders
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedOrder.orders.length,
                  itemBuilder: (context, index) {
                    final order = groupedOrder.orders[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < groupedOrder.orders.length - 1 ? 12 : 0,
                      ),
                      child: _OrderHistoryCard(
                        key: ValueKey(order.trxId),
                        order: order,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailPage(order: order),
                            ),
                          );
                          if (context.mounted) {
                            _loadOrders();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) => _FilterDialog(
        onFilterApplied: (date, label) {
          context.read<OrderHistoryCubit>().filterByDate(date, label);
        },
        onFilterRange: (start, end, label) {
          context.read<OrderHistoryCubit>().filterByDateRange(
            start,
            end,
            label,
          );
        },
      ),
    );
  }
}

// Widget untuk menampilkan grouped order by date
class _GroupedOrderCard extends StatelessWidget {
  final GroupedOrderByDate groupedOrder;
  final VoidCallback onTap;

  const _GroupedOrderCard({
    super.key,
    required this.groupedOrder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Calendar Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppImages.calenderIcon,
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFF4B4B),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Date and Transaction Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupedOrder.shortFormattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        groupedOrder.transactionCountText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Amount and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      groupedOrder.formattedAmount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderHistory order;
  final VoidCallback onTap;
  final bool isCompact;

  const _OrderHistoryCard({
    super.key,
    required this.order,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = isCompact ? 10.0 : 16.0;
    final iconContainerSize = isCompact ? 36.0 : 48.0;
    final iconSize = isCompact ? 18.0 : 24.0;
    final titleFontSize = isCompact ? 13.0 : 16.0;
    final dateFontSize = isCompact ? 11.0 : 13.0;
    final calendarIconSize = isCompact ? 12.0 : 14.0;
    final spacing = isCompact ? 10.0 : 16.0;
    final moreIconSize = isCompact ? 20.0 : 24.0;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              // Invoice Icon
              SizedBox(
                width: iconContainerSize,
                height: iconContainerSize,
                child: Center(
                  child: SvgPicture.asset(
                    AppImages.invoiceIcon,
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ),
              SizedBox(width: spacing),

              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      order.trxId,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isCompact ? 4 : 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppImages.calenderIcon,
                          width: calendarIconSize,
                          height: calendarIconSize,
                          colorFilter: ColorFilter.mode(
                            Colors.grey.shade600,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(width: isCompact ? 4 : 6),
                        Expanded(
                          child: Text(
                            order.shortFormattedDate,
                            style: TextStyle(
                              fontSize: dateFontSize,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More Icon
              Icon(
                Icons.more_vert,
                color: Colors.grey.shade400,
                size: moreIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Filter Dialog Widget
class _FilterDialog extends StatefulWidget {
  final Function(DateTime date, String label) onFilterApplied;
  final Function(DateTime start, DateTime end, String label) onFilterRange;

  const _FilterDialog({
    required this.onFilterApplied,
    required this.onFilterRange,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  DateTime _selectedDate = IndonesiaTime.now();
  String _selectedQuickFilter = 'Pilih';

  void _applyQuickFilter(String filter) {
    Navigator.pop(context);

    switch (filter) {
      case 'Hari Ini':
        widget.onFilterApplied(IndonesiaTime.now(), 'Hari Ini');
        break;
      case 'Kemarin':
        final yesterday = IndonesiaTime.now().subtract(const Duration(days: 1));
        widget.onFilterApplied(yesterday, 'Kemarin');
        break;
      case 'Minggu Ini':
        final now = IndonesiaTime.now();
        final startOfWeek = IndonesiaTime.startOfWeek(now);
        final endOfWeek = IndonesiaTime.endOfWeek(now);
        widget.onFilterRange(startOfWeek, endOfWeek, 'Minggu Ini');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = isLandscape
        ? screenHeight * 0.9
        : screenHeight * 0.85;
    final isCompact = isLandscape;
    final headerPadding = isCompact ? 16.0 : 24.0;
    final contentPadding = isCompact ? 16.0 : 24.0;
    final titleFontSize = isCompact ? 17.0 : 20.0;
    final iconSize = isCompact ? 24.0 : 28.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 48 : 24,
        vertical: isLandscape ? 16 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 500 : 400,
          maxHeight: maxDialogHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B4B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isCompact ? 20 : 24),
                  topRight: Radius.circular(isCompact ? 20 : 24),
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppImages.filterIcon,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Filter Riwayat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isCompact ? 20 : 24,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info text
                    Text(
                      'Pilih quick filter atau tanggal spesifik untuk melihat riwayat pemesanan',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isCompact ? 14 : 20),

                    // Quick Filter Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedQuickFilter,
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12 : 16,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: isCompact ? 18 : 20,
                          ),
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Pilih',
                              child: Text('Pilih Quick Filter'),
                            ),
                            DropdownMenuItem(
                              value: 'Hari Ini',
                              child: Text('Hari Ini'),
                            ),
                            DropdownMenuItem(
                              value: 'Kemarin',
                              child: Text('Kemarin'),
                            ),
                            DropdownMenuItem(
                              value: 'Minggu Ini',
                              child: Text('Minggu Ini'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null && value != 'Pilih') {
                              _applyQuickFilter(value);
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 14 : 20),

                    // Divider with text
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12 : 16,
                          ),
                          child: Text(
                            'ATAU',
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    SizedBox(height: isCompact ? 14 : 20),

                    // Calendar section label
                    Text(
                      'Pilih Tanggal Spesifik',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: isCompact ? 8 : 12),

                    // Calendar
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: const Color(0xFF4CAF50), // Selected date
                              onPrimary: Colors.white, // Text on selected date
                              surface: Colors.white, // Calendar background
                              onSurface: Colors.black87, // Regular date text
                            ),
                            datePickerTheme: DatePickerThemeData(
                              todayForegroundColor: WidgetStateProperty.all(
                                const Color(0xFF4CAF50),
                              ),
                              todayBorder: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: IndonesiaTime.now(),
                            onDateChanged: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                              // Auto apply filter when date selected
                              Navigator.pop(context);
                              final formatter =
                                  '${date.day}/${date.month}/${date.year}';
                              widget.onFilterApplied(date, formatter);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading untuk order history dengan efek shimmer
class _OrderHistorySkeleton extends StatelessWidget {
  const _OrderHistorySkeleton();

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
