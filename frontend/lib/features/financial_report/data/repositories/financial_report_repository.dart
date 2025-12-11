import 'package:dio/dio.dart';
import 'package:sagawa_pos_new/core/utils/indonesia_time.dart';
import 'package:sagawa_pos_new/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos_new/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';

class FinancialReportRepository {
  final OrderHistoryRepository _orderHistoryRepository;
  String? _currentOutletId;
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/v1';
  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 15)
    ..options.receiveTimeout = const Duration(seconds: 15)
    ..options.validateStatus = (status) => true;

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

  /// Clear cached outlet ID (call on logout)
  void clearCache() {
    _currentOutletId = null;
  }

  /// Get orders from API filtered by outlet ID
  Future<List<OrderHistory>> _getOrdersByOutlet() async {
    final outletId = await _getCurrentOutletId();
    if (outletId == null || outletId.isEmpty) {
      return [];
    }
    // Data diambil dari API melalui OrderHistoryRepository
    return await _orderHistoryRepository.getOrdersByOutlet(outletId);
  }

  /// Get orders from API filtered by outlet ID and date range
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
      // Return empty report jika tidak ada outlet ID
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

    // Hitung revenue harian
    double dailyRevenue = 0;
    for (final order in orders) {
      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      // Compare year, month, day instead of isAtSameMomentAs
      if (orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day) {
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
      // Handle berbagai format: 'dine in', 'dine-in', 'dine_in', 'dinein'
      if (type.contains('dine') &&
          (type.contains('in') || type.contains('_in'))) {
        dineInCount++;
      } else if (type.contains('take') &&
          (type.contains('away') || type.contains('_away'))) {
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
        // Compare year, month, day instead of isAtSameMomentAs
        if (orderDate.year == date.year &&
            orderDate.month == date.month &&
            orderDate.day == date.day) {
          revenue += order.totalAmount;
          orderCount++;
        }
      }

      dailyRevenueList.add(
        DailyRevenue(date: date, revenue: revenue, orderCount: orderCount),
      );
    }

    // Generate transaction records dari data database
    final transactions = _convertOrdersToTransactions(orders);

    // Calculate payment method statistics
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
        total: order.receipt.afterTax, // Use afterTax instead of totalAmount
        paymentMethod: order.receipt.paymentMethod,
      );
    }).toList();
  }

  /// Calculate payment method statistics from orders
  Map<String, dynamic> _calculatePaymentStats(List<OrderHistory> orders) {
    double totalRevenue = 0; // Total pendapatan keseluruhan
    double cashRevenue = 0; // Pendapatan dari Cash, Voucher+Cash, Discount+Cash
    double qrisRevenue = 0; // Pendapatan dari QRIS, Voucher+QRIS, Discount+QRIS
    int voucherCount = 0; // Jumlah transaksi voucher
    double totalTaxWithPB1 =
        0; // Total PB1 dari semua transaksi yang dikenakan pajak

    int cashCount = 0;
    int qrisCount = 0;
    int discountCount = 0;

    for (final order in orders) {
      final paymentMethod = order.receipt.paymentMethod.toLowerCase();
      final amount = order.receipt.afterTax; // Total setelah pajak
      final tax = order.receipt.tax; // Pajak (PB1)

      // 1. Total pendapatan = semua transaksi
      totalRevenue += amount;

      // 7. Total PB1 dari semua transaksi yang dikenakan pajak
      // (discount, voucher, cash, qris semuanya kena pajak)
      totalTaxWithPB1 += tax;

      // Kategorisasi berdasarkan metode pembayaran
      if (paymentMethod.contains('discount')) {
        discountCount++;

        // Discount payment menggunakan cash atau qris
        if (paymentMethod.contains('qris')) {
          // 5. Discount + QRIS masuk ke pendapatan QRIS
          final qrisAmount = (order.receipt.qrisAmount ?? 0).toDouble();
          qrisRevenue += qrisAmount;
          qrisCount++;
        } else {
          // 4. Discount + Cash masuk ke pendapatan Cash
          final cashAmount = (order.receipt.cashAmount ?? 0).toDouble();
          cashRevenue += cashAmount;
          cashCount++;
        }
      } else if (paymentMethod.contains('voucher')) {
        // 6. Transaksi voucher (hitung jumlahnya saja)
        voucherCount++;

        // Voucher + pembayaran tambahan
        if (paymentMethod.contains('cash')) {
          // 4. Voucher + Cash: pembayaran tambahan masuk ke pendapatan Cash
          final additionalPayment = (order.receipt.additionalPayment ?? 0)
              .toDouble();
          cashRevenue += additionalPayment;
          cashCount++;
          print(
            '[FinancialReport] Voucher+Cash: additionalPayment=$additionalPayment, adding to cashRevenue',
          );
        } else if (paymentMethod.contains('qris')) {
          // 5. Voucher + QRIS: pembayaran tambahan masuk ke pendapatan QRIS
          final additionalPayment = (order.receipt.additionalPayment ?? 0)
              .toDouble();
          qrisRevenue += additionalPayment;
          qrisCount++;
          print(
            '[FinancialReport] Voucher+QRIS: additionalPayment=$additionalPayment, adding to qrisRevenue',
          );
        }
        // Pure voucher: tidak ada pendapatan cash/qris
      } else if (paymentMethod.contains('qris')) {
        // 5. QRIS murni masuk ke pendapatan QRIS
        qrisRevenue += amount;
        qrisCount++;
      } else {
        // 4. Cash murni masuk ke pendapatan Cash (default)
        cashRevenue += amount;
        cashCount++;
      }
    }

    return {
      'totalRevenue': totalRevenue, // Total pendapatan keseluruhan
      'cashRevenue': cashRevenue, // Cash + Voucher+Cash + Discount+Cash
      'qrisRevenue': qrisRevenue, // QRIS + Voucher+QRIS + Discount+QRIS
      'voucherRevenue': 0.0, // Tidak ada revenue voucher (hanya count)
      'discountRevenue':
          0.0, // Tidak perlu revenue discount (sudah masuk cash/qris)
      'cashCount': cashCount,
      'qrisCount': qrisCount,
      'voucherCount': voucherCount,
      'discountCount': discountCount,
      'totalTax': totalTaxWithPB1, // Total PB1 dari semua transaksi
    };
  }

  /// Get transactions filtered by period (from database filtered by outlet ID)
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
        // Ambil data hari ini dari API dengan date range
        filteredOrders = await _getOrdersByOutletAndDateRange(
          today,
          endOfToday,
        );
        break;
      case TableFilter.monthly:
        // Ambil data bulan ini dari API dengan date range
        final startOfMonth = IndonesiaTime.startOfMonth(now);
        filteredOrders = await _getOrdersByOutletAndDateRange(
          startOfMonth,
          endOfToday,
        );
        break;
    }

    return _convertOrdersToTransactions(filteredOrders);
  }

  /// Generate laporan berdasarkan periode tertentu (from database filtered by outlet ID)
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
        daysBack = 7; // 7 hari terakhir
        startDate = today.subtract(const Duration(days: 7));
        break;
      case ReportPeriod.weekly:
        daysBack = 28; // 4 minggu terakhir
        startDate = today.subtract(const Duration(days: 28));
        break;
      case ReportPeriod.monthly:
        daysBack = 365; // 12 bulan terakhir (akan digroup per bulan)
        startDate = DateTime(now.year - 1, now.month, 1);
        break;
    }

    // Ambil orders dari API dengan date range
    final orders = await _getOrdersByOutletAndDateRange(startDate, endOfToday);

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
          // Compare year, month, day instead of isAtSameMomentAs
          if (orderDate.year == date.year &&
              orderDate.month == date.month &&
              orderDate.day == date.day) {
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

  /// Generate report berdasarkan custom date range
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

    // Normalize dates
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Get orders from API with date range
    final orders = await _getOrdersByOutletAndDateRange(start, end);

    // Calculate total revenue for the range
    double totalRevenue = 0;
    for (final order in orders) {
      totalRevenue += order.totalAmount;
    }

    // Count Dine In and Take Away
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

    // Generate daily revenue list for the date range
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

    // Calculate payment method statistics
    final paymentStats = _calculatePaymentStats(orders);

    return FinancialReport(
      dailyRevenue: totalRevenue, // Use total as daily for custom range
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
