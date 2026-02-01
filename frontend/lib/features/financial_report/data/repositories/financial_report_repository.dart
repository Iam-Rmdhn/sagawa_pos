import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos/data/services/user_service.dart';

class FinancialReportRepository {
  final OrderHistoryRepository _orderHistoryRepository;
  String? _currentOutletId;

  FinancialReportRepository({OrderHistoryRepository? orderHistoryRepository})
    : _orderHistoryRepository =
          orderHistoryRepository ?? OrderHistoryRepository();

  Future<String?> _getCurrentOutletId() async {
    if (_currentOutletId != null) return _currentOutletId;
    final user = await UserService.getUser();
    _currentOutletId = user?.id;
    return _currentOutletId;
  }

  void clearCache() {
    _currentOutletId = null;
  }

  Future<List<OrderHistory>> _getOrdersByOutlet() async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return [];
    }
    return await _orderHistoryRepository.getOrdersByOutlet(outletId);
  }

  Future<List<OrderHistory>> _getOrdersByOutletAndDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return [];
    }
    return await _orderHistoryRepository.getOrdersByOutletAndDateRange(
      outletId,
      startDate,
      endDate,
    );
  }

  Future<FinancialReport> generateReport() async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return FinancialReport(
        dailyRevenue: 0,
        weeklyRevenue: 0,
        monthlyRevenue: 0,
        dineInCount: 0,
        takeAwayCount: 0,
        dailyRevenueList: [],
        totalOrders: 0,
        transactions: [],
      );
    }

    final now = IndonesiaTime.now();
    final today = IndonesiaTime.startOfDay(now);
    final startOfWeek = IndonesiaTime.startOfWeek(now);
    final startOfMonth = IndonesiaTime.startOfMonth(now);

    final orders = await _getOrdersByOutlet();

    double dailyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      if (orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day) {
        dailyRevenue += _getActualRevenue(order);
      }
    }

    double weeklyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      if (!orderDate.isBefore(startOfWeek) && !orderDate.isAfter(today)) {
        weeklyRevenue += _getActualRevenue(order);
      }
    }

    double monthlyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      if (!orderDate.isBefore(startOfMonth) && !orderDate.isAfter(today)) {
        monthlyRevenue += _getActualRevenue(order);
      }
    }

    int dineInCount = 0;
    int takeAwayCount = 0;
    for (final order in orders) {
      final type = order.receipt.type.toLowerCase();

      if (type.contains('dine') &&
          (type.contains('in') || type.contains('_in'))) {
        dineInCount++;
      } else if (type.contains('take') &&
          (type.contains('away') || type.contains('_away'))) {
        takeAwayCount++;
      }
    }

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

        if (orderDate.year == date.year &&
            orderDate.month == date.month &&
            orderDate.day == date.day) {
          revenue += _getActualRevenue(order);
          orderCount++;
        }
      }

      dailyRevenueList.add(
        DailyRevenue(date: date, revenue: revenue, orderCount: orderCount),
      );
    }

    final transactions = _convertOrdersToTransactions(orders);

    final paymentStats = _calculatePaymentStats(orders);

    return FinancialReport(
      dailyRevenue: dailyRevenue,
      weeklyRevenue: weeklyRevenue,
      monthlyRevenue: monthlyRevenue,
      dineInCount: dineInCount,
      takeAwayCount: takeAwayCount,
      dailyRevenueList: dailyRevenueList,
      totalOrders: orders.length,
      transactions: transactions,
      totalRevenue: (paymentStats['totalRevenue'] as num).toDouble(),
      cashRevenue: (paymentStats['cashRevenue'] as num).toDouble(),
      qrisRevenue: (paymentStats['qrisRevenue'] as num).toDouble(),
      voucherRevenue: (paymentStats['voucherRevenue'] as num).toDouble(),
      discountRevenue: (paymentStats['discountRevenue'] as num).toDouble(),
      cashCount: paymentStats['cashCount'] as int,
      qrisCount: paymentStats['qrisCount'] as int,
      voucherCount: paymentStats['voucherCount'] as int,
      discountCount: paymentStats['discountCount'] as int,
      totalTax: (paymentStats['totalTax'] as num).toDouble(),
    );
  }

  List<TransactionRecord> _convertOrdersToTransactions(
    List<OrderHistory> orders,
  ) {
    return orders.map((order) {
      final menuItems = order.receipt.groupedItems
          .map((item) {
            if (item.quantity > 1) {
              return '${item.name} x${item.quantity}';
            }
            return item.name;
          })
          .join(', ');

      final totalQty = order.receipt.items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

      String paymentMethod = order.receipt.paymentMethod;
      if (order.receipt.discountPercent != null &&
          paymentMethod.toLowerCase().contains('discount') &&
          !paymentMethod.contains('%')) {
        paymentMethod = paymentMethod.replaceFirst(
          RegExp('Discount', caseSensitive: false),
          'Discount ${order.receipt.discountPercent}%',
        );
      }

      return TransactionRecord(
        trxId: order.trxId,
        date: order.date,
        type: order.receipt.type,
        menuItems: menuItems,
        qty: totalQty,
        tax: order.receipt.tax,
        subtotal: order.receipt.subTotal,
        total: order.receipt.afterTax,
        paymentMethod: paymentMethod,

        voucherAmount: order.receipt.voucherAmount?.toDouble(),
        additionalPayment: order.receipt.additionalPayment?.toDouble(),
        changes: order.receipt.change,

        discountPercent: order.receipt.discountPercent,
        discountAmount: order.receipt.discountAmount?.toDouble(),
      );
    }).toList();
  }

  double _getActualRevenue(OrderHistory order) {
    final paymentMethod = order.receipt.paymentMethod.toLowerCase();
    final amount = order.receipt.afterTax;

    if (paymentMethod.contains('discount') && paymentMethod.contains('100')) {
      return 0.0;
    }

    if (paymentMethod == 'voucher') {
      return 0.0;
    }

    if (paymentMethod.contains('voucher')) {
      return (order.receipt.additionalPayment ?? 0).toDouble();
    }

    if (paymentMethod.contains('discount')) {
      if (paymentMethod.contains('qris')) {
        return (order.receipt.qrisAmount ?? 0).toDouble();
      } else {
        return (order.receipt.cashAmount ?? 0).toDouble();
      }
    }

    return amount;
  }

  Map<String, dynamic> _calculatePaymentStats(List<OrderHistory> orders) {
    double totalRevenue = 0;
    double cashRevenue = 0;
    double qrisRevenue = 0;
    int voucherCount = 0;
    double totalTaxWithPB1 = 0;

    int cashCount = 0;
    int qrisCount = 0;
    int discountCount = 0;

    for (final order in orders) {
      final paymentMethod = order.receipt.paymentMethod.toLowerCase();
      final amount = order.receipt.afterTax;
      final tax = order.receipt.tax;

      if (paymentMethod.contains('discount')) {
        discountCount++;

        if (paymentMethod.contains('qris')) {
          final qrisAmount = (order.receipt.qrisAmount ?? 0).toDouble();
          qrisRevenue += qrisAmount;
          totalRevenue += qrisAmount;
          totalTaxWithPB1 += tax;
          qrisCount++;
        } else if (paymentMethod.contains('100%')) {
        } else {
          final cashAmount = (order.receipt.cashAmount ?? 0).toDouble();
          cashRevenue += cashAmount;
          totalRevenue += cashAmount;
          totalTaxWithPB1 += tax;
          cashCount++;
        }
      } else if (paymentMethod.contains('voucher')) {
        voucherCount++;

        if (paymentMethod.contains('cash')) {
          final additionalPayment = (order.receipt.additionalPayment ?? 0)
              .toDouble();
          cashRevenue += additionalPayment;
          totalRevenue += additionalPayment;

          if (amount > 0) {
            final taxPortion = tax * (additionalPayment / amount);
            totalTaxWithPB1 += taxPortion;
          }
          cashCount++;
          print(
            '[FinancialReport] Voucher+Cash: additionalPayment=$additionalPayment, adding to cashRevenue and totalRevenue',
          );
        } else if (paymentMethod.contains('qris')) {
          final additionalPayment = (order.receipt.additionalPayment ?? 0)
              .toDouble();
          qrisRevenue += additionalPayment;
          totalRevenue += additionalPayment;

          if (amount > 0) {
            final taxPortion = tax * (additionalPayment / amount);
            totalTaxWithPB1 += taxPortion;
          }
          qrisCount++;
          print(
            '[FinancialReport] Voucher+QRIS: additionalPayment=$additionalPayment, adding to qrisRevenue and totalRevenue',
          );
        }
      } else if (paymentMethod.contains('qris')) {
        qrisRevenue += amount;
        totalRevenue += amount;
        totalTaxWithPB1 += tax;
        qrisCount++;
      } else {
        cashRevenue += amount;
        totalRevenue += amount;
        totalTaxWithPB1 += tax;
        cashCount++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'cashRevenue': cashRevenue,
      'qrisRevenue': qrisRevenue,
      'voucherRevenue': 0.0,
      'discountRevenue': 0.0,
      'cashCount': cashCount,
      'qrisCount': qrisCount,
      'voucherCount': voucherCount,
      'discountCount': discountCount,
      'totalTax': totalTaxWithPB1,
    };
  }

  Future<List<TransactionRecord>> getTransactionsByFilter(
    TableFilter filter,
  ) async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return [];
    }

    final now = IndonesiaTime.now();
    final today = IndonesiaTime.startOfDay(now);
    final endOfToday = IndonesiaTime.endOfDay(now);

    List<OrderHistory> filteredOrders;

    switch (filter) {
      case TableFilter.daily:
        filteredOrders = await _getOrdersByOutletAndDateRange(
          today,
          endOfToday,
        );
        break;
      case TableFilter.monthly:
        final startOfMonth = IndonesiaTime.startOfMonth(now);
        filteredOrders = await _getOrdersByOutletAndDateRange(
          startOfMonth,
          endOfToday,
        );
        break;
    }

    return _convertOrdersToTransactions(filteredOrders);
  }

  Future<List<DailyRevenue>> getRevenueByPeriod(ReportPeriod period) async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return [];
    }

    final now = IndonesiaTime.now();
    final today = IndonesiaTime.startOfDay(now);
    final endOfToday = IndonesiaTime.endOfDay(now);

    DateTime startDate;
    int daysBack;
    switch (period) {
      case ReportPeriod.daily:
        daysBack = 7;
        startDate = today.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.weekly:
        daysBack = 28;
        startDate = today.subtract(const Duration(days: 28));
        break;
      case ReportPeriod.monthly:
        daysBack = 365;
        startDate = DateTime(now.year - 1, now.month, 1);
        break;
    }

    final orders = await _getOrdersByOutletAndDateRange(startDate, endOfToday);

    final dailyRevenueList = <DailyRevenue>[];

    if (period == ReportPeriod.monthly) {
      for (int i = 11; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        double revenue = 0;
        int orderCount = 0;

        for (final order in orders) {
          if (order.date.year == targetMonth.year &&
              order.date.month == targetMonth.month) {
            revenue += _getActualRevenue(order);
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

          if (orderDate.year == date.year &&
              orderDate.month == date.month &&
              orderDate.day == date.day) {
            revenue += _getActualRevenue(order);
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

  Future<FinancialReport> generateReportByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return FinancialReport(
        dailyRevenue: 0,
        weeklyRevenue: 0,
        monthlyRevenue: 0,
        dineInCount: 0,
        takeAwayCount: 0,
        dailyRevenueList: [],
        totalOrders: 0,
        transactions: [],
      );
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final orders = await _getOrdersByOutletAndDateRange(start, end);

    double totalRevenue = 0;
    for (final order in orders) {
      totalRevenue += _getActualRevenue(order);
    }

    int dineInCount = 0;
    int takeAwayCount = 0;
    for (final order in orders) {
      final type = order.receipt.type.toLowerCase();
      if (type.contains('dine') &&
          (type.contains('in') || type.contains('_in'))) {
        dineInCount++;
      } else if (type.contains('take') &&
          (type.contains('away') || type.contains('_away'))) {
        takeAwayCount++;
      }
    }

    final dailyRevenueList = <DailyRevenue>[];
    final daysDiff = end.difference(start).inDays + 1;

    for (int i = 0; i < daysDiff; i++) {
      final date = start.add(Duration(days: i));
      double revenue = 0;
      int orderCount = 0;

      for (final order in orders) {
        final orderDate = DateTime(
          order.date.year,
          order.date.month,
          order.date.day,
        );
        if (orderDate.year == date.year &&
            orderDate.month == date.month &&
            orderDate.day == date.day) {
          revenue += _getActualRevenue(order);
          orderCount++;
        }
      }

      dailyRevenueList.add(
        DailyRevenue(date: date, revenue: revenue, orderCount: orderCount),
      );
    }

    final transactions = _convertOrdersToTransactions(orders);

    final paymentStats = _calculatePaymentStats(orders);

    return FinancialReport(
      dailyRevenue: totalRevenue,
      weeklyRevenue: totalRevenue,
      monthlyRevenue: totalRevenue,
      dineInCount: dineInCount,
      takeAwayCount: takeAwayCount,
      dailyRevenueList: dailyRevenueList,
      totalOrders: orders.length,
      transactions: transactions,
      totalRevenue: (paymentStats['totalRevenue'] as num).toDouble(),
      cashRevenue: (paymentStats['cashRevenue'] as num).toDouble(),
      qrisRevenue: (paymentStats['qrisRevenue'] as num).toDouble(),
      voucherRevenue: (paymentStats['voucherRevenue'] as num).toDouble(),
      discountRevenue: (paymentStats['discountRevenue'] as num).toDouble(),
      cashCount: paymentStats['cashCount'] as int,
      qrisCount: paymentStats['qrisCount'] as int,
      voucherCount: paymentStats['voucherCount'] as int,
      discountCount: paymentStats['discountCount'] as int,
      totalTax: (paymentStats['totalTax'] as num).toDouble(),
    );
  }
}
