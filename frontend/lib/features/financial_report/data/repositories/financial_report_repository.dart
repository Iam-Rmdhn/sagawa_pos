import 'package:sagawa_pos_new/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos_new/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';

/// Repository untuk mengelola data laporan keuangan
class FinancialReportRepository {
  final OrderHistoryRepository _orderHistoryRepository;
  String? _currentOutletId;

  FinancialReportRepository({OrderHistoryRepository? orderHistoryRepository})
    : _orderHistoryRepository =
          orderHistoryRepository ?? OrderHistoryRepository();

  /// Get current outlet ID from logged in user
  Future<String?> _getCurrentOutletId() async {
    if (_currentOutletId != null) return _currentOutletId;
    final user = await UserService.getUser();
    _currentOutletId = user?.id;
    return _currentOutletId;
  }

  /// Get orders filtered by outlet ID
  Future<List<OrderHistory>> _getOrdersByOutlet() async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return [];
    }
    return await _orderHistoryRepository.getOrdersByOutlet(outletId);
  }

  /// Generate laporan keuangan lengkap (filtered by outlet)
  Future<FinancialReport> generateReport() async {
    final orders = await _getOrdersByOutlet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Hitung revenue harian (hari ini)
    double dailyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      if (orderDate.isAtSameMomentAs(today)) {
        dailyRevenue += order.totalAmount;
      }
    }

    // Hitung revenue mingguan
    double weeklyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      if (!orderDate.isBefore(startOfWeek) && !orderDate.isAfter(today)) {
        weeklyRevenue += order.totalAmount;
      }
    }

    // Hitung revenue bulanan
    double monthlyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      if (!orderDate.isBefore(startOfMonth) && !orderDate.isAfter(today)) {
        monthlyRevenue += order.totalAmount;
      }
    }

    // Hitung Dine In dan Take Away
    int dineInCount = 0;
    int takeAwayCount = 0;
    for (final order in orders) {
      // Ambil type dari receipt
      final type = order.receipt.type.toLowerCase();
      if (type.contains('dine in') || type.contains('dine-in')) {
        dineInCount++;
      } else if (type.contains('take away') || type.contains('takeaway')) {
        takeAwayCount++;
      }
    }

    // Generate data untuk 7 hari terakhir (untuk line chart)
    final dailyRevenueList = <DailyRevenue>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      double revenue = 0;
      int orderCount = 0;

      for (final order in orders) {
        final orderDate = DateTime(
          order.date.year,
          order.date.month,
          order.date.day,
        );
        if (orderDate.isAtSameMomentAs(date)) {
          revenue += order.totalAmount;
          orderCount++;
        }
      }

      dailyRevenueList.add(
        DailyRevenue(date: date, revenue: revenue, orderCount: orderCount),
      );
    }

    // Generate transaction records
    final transactions = _convertOrdersToTransactions(orders);

    return FinancialReport(
      dailyRevenue: dailyRevenue,
      weeklyRevenue: weeklyRevenue,
      monthlyRevenue: monthlyRevenue,
      dineInCount: dineInCount,
      takeAwayCount: takeAwayCount,
      dailyRevenueList: dailyRevenueList,
      totalOrders: orders.length,
      transactions: transactions,
    );
  }

  /// Convert orders to transaction records
  List<TransactionRecord> _convertOrdersToTransactions(
    List<OrderHistory> orders,
  ) {
    return orders.map((order) {
      // Get menu items as string
      final menuItems = order.receipt.items.map((item) => item.name).join(', ');

      // Get total quantity
      final totalQty = order.receipt.items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

      return TransactionRecord(
        trxId: order.trxId,
        date: order.date,
        type: order.receipt.type,
        menuItems: menuItems,
        qty: totalQty,
        tax: order.receipt.tax,
        subtotal: order.receipt.subTotal,
        total: order.totalAmount,
      );
    }).toList();
  }

  /// Get transactions filtered by period (filtered by outlet)
  Future<List<TransactionRecord>> getTransactionsByFilter(
    TableFilter filter,
  ) async {
    final orders = await _getOrdersByOutlet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<OrderHistory> filteredOrders;

    switch (filter) {
      case TableFilter.daily:
        // Filter untuk hari ini
        filteredOrders = orders.where((order) {
          final orderDate = DateTime(
            order.date.year,
            order.date.month,
            order.date.day,
          );
          return orderDate.isAtSameMomentAs(today);
        }).toList();
        break;
      case TableFilter.monthly:
        // Filter untuk bulan ini
        final startOfMonth = DateTime(now.year, now.month, 1);
        filteredOrders = orders.where((order) {
          final orderDate = DateTime(
            order.date.year,
            order.date.month,
            order.date.day,
          );
          return !orderDate.isBefore(startOfMonth) && !orderDate.isAfter(today);
        }).toList();
        break;
    }

    return _convertOrdersToTransactions(filteredOrders);
  }

  /// Generate laporan berdasarkan periode tertentu (filtered by outlet)
  Future<List<DailyRevenue>> getRevenueByPeriod(ReportPeriod period) async {
    final orders = await _getOrdersByOutlet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int daysBack;
    switch (period) {
      case ReportPeriod.daily:
        daysBack = 7; // 7 hari terakhir
        break;
      case ReportPeriod.weekly:
        daysBack = 28; // 4 minggu terakhir
        break;
      case ReportPeriod.monthly:
        daysBack = 365; // 12 bulan terakhir (akan digroup per bulan)
        break;
    }

    final dailyRevenueList = <DailyRevenue>[];

    if (period == ReportPeriod.monthly) {
      // Group by month for monthly view
      for (int i = 11; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        double revenue = 0;
        int orderCount = 0;

        for (final order in orders) {
          if (order.date.year == targetMonth.year &&
              order.date.month == targetMonth.month) {
            revenue += order.totalAmount;
            orderCount++;
          }
        }

        dailyRevenueList.add(
          DailyRevenue(
            date: targetMonth,
            revenue: revenue,
            orderCount: orderCount,
          ),
        );
      }
    } else {
      // Group by day for daily/weekly view
      for (int i = daysBack - 1; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        double revenue = 0;
        int orderCount = 0;

        for (final order in orders) {
          final orderDate = DateTime(
            order.date.year,
            order.date.month,
            order.date.day,
          );
          if (orderDate.isAtSameMomentAs(date)) {
            revenue += order.totalAmount;
            orderCount++;
          }
        }

        dailyRevenueList.add(
          DailyRevenue(date: date, revenue: revenue, orderCount: orderCount),
        );
      }
    }

    return dailyRevenueList;
  }
}
