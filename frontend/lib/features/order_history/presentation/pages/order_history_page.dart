import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/features/order_history/presentation/cubit/order_history_cubit.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/features/order_history/presentation/pages/order_detail_page.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      // If filter is active, maintain the filter
      // Just reload will trigger the current filter
      if (cubit.state.selectedDate != null) {
        cubit.filterByDate(cubit.state.selectedDate!, cubit.state.filterLabel!);
      }
    } else {
      // No filter, load all orders
      cubit.loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: const Color(0xFFFF4B4B),
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Riwayat Pemesanan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                AppImages.filterIcon,
                width: 24,
                height: 24,
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
      body: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
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

          if (state.orders.isEmpty) {
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter indicator
              if (state.filterLabel != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${state.filterLabel} • ${state.orders.length} Riwayat',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          context.read<OrderHistoryCubit>().resetFilter();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Order list
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFFF4B4B),
                  onRefresh: () async {
                    _loadOrders();
                    // Wait a bit for the UI to update
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = state.orders[index];
                      return _OrderHistoryCard(
                        order: order,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailPage(order: order),
                            ),
                          );
                          // Reload data when coming back from detail page
                          if (mounted) {
                            _loadOrders();
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
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

class _OrderHistoryCard extends StatelessWidget {
  final OrderHistory order;
  final VoidCallback onTap;

  const _OrderHistoryCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Invoice Icon
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: SvgPicture.asset(
                    AppImages.invoiceIcon,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.trxId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppImages.calenderIcon,
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            Colors.grey.shade600,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.shortFormattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More Icon
              Icon(Icons.more_vert, color: Colors.grey.shade400, size: 24),
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
  DateTime _selectedDate = DateTime.now();
  String _selectedQuickFilter = 'Pilih';

  void _applyQuickFilter(String filter) {
    Navigator.pop(context);

    switch (filter) {
      case 'Hari Ini':
        widget.onFilterApplied(DateTime.now(), 'Hari Ini');
        break;
      case 'Kemarin':
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        widget.onFilterApplied(yesterday, 'Kemarin');
        break;
      case 'Minggu Ini':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        widget.onFilterRange(startOfWeek, endOfWeek, 'Minggu Ini');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4B4B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppImages.filterIcon,
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Filter Riwayat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info text
                  const Text(
                    'Pilih quick filter atau tanggal spesifik untuk melihat riwayat pemesanan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Filter Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedQuickFilter,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        style: const TextStyle(
                          fontSize: 14,
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
                  const SizedBox(height: 20),

                  // Divider with text
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ATAU',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Calendar section label
                  Text(
                    'Pilih Tanggal Spesifik',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Calendar
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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
                ],
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
