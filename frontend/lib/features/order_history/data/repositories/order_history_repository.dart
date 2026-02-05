import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sagawa_pos/core/network/api_config.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt_item.dart';

class OrderHistoryRepository {
  static const String _orderHistoryKey = 'order_history';
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/v1';

  final Dio _dio = Dio()
    ..options.connectTimeout = ApiConfig.connectTimeout
    ..options.receiveTimeout = ApiConfig.receiveTimeout
    ..options.validateStatus = (status) => true;

  OrderHistory _transactionToOrderHistory(Map<String, dynamic> trx) {
    List<ReceiptItem> items = [];
    if (trx['items'] != null) {
      for (var item in trx['items']) {
        items.add(
          ReceiptItem(
            name:
                item['menu_name']?.toString() ?? item['name']?.toString() ?? '',
            quantity: (item['qty'] as num?)?.toInt() ?? 1,
            price: (item['price'] as num?)?.toDouble() ?? 0,
            subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }
    DateTime date = IndonesiaTime.now();
    if (trx['created_at'] != null) {
      try {
        final dateString = trx['created_at'].toString();
        if (dateString.endsWith('Z')) {
          final parsed = DateTime.parse(dateString);
          date = IndonesiaTime.toIndonesiaTime(parsed);
        } else if (dateString.contains('+07:00') ||
            dateString.contains('+08:00') ||
            dateString.contains('+09:00')) {
          final withoutOffset = dateString.substring(0, 19);
          date = DateTime.parse(withoutOffset);
        } else if (dateString.contains('+') || dateString.contains('-', 10)) {
          final parsed = DateTime.parse(dateString);
          date = IndonesiaTime.toIndonesiaTime(parsed);
        } else {
          date = DateTime.parse(dateString);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    String orderType = trx['type']?.toString() ?? 'Dine In';
    if (orderType.toLowerCase() == 'dine_in') {
      orderType = 'Dine In';
    } else if (orderType.toLowerCase() == 'take_away') {
      orderType = 'Take Away';
    }

    final paymentMethod = trx['method']?.toString() ?? 'Cash';
    double? additionalPayment;
    String? additionalPaymentMethod;
    if (paymentMethod.toLowerCase().contains('voucher')) {
      if (paymentMethod.toLowerCase().contains('cash')) {
        additionalPayment = (trx['nominal'] as num?)?.toDouble();
        additionalPaymentMethod = 'Cash';
        print(
          '[OrderHistory] Voucher+Cash: additionalPayment=$additionalPayment, nominal=${trx['nominal']}',
        );
      } else if (paymentMethod.toLowerCase().contains('qris')) {
        additionalPayment = (trx['qris'] as num?)?.toDouble();
        additionalPaymentMethod = 'QRIS';
        print(
          '[OrderHistory] Voucher+QRIS: additionalPayment=$additionalPayment, qris=${trx['qris']}',
        );
      }
    }
    final receipt = Receipt(
      storeName: trx['outlet_name']?.toString() ?? '',
      address: '',
      type: orderType,
      trxId: trx['trx_id']?.toString() ?? '',
      cashier: trx['cashier']?.toString() ?? '',
      customerName: trx['customer']?.toString() ?? '',
      items: items,
      subTotal: (trx['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (trx['tax'] as num?)?.toDouble() ?? 0,
      afterTax: (trx['total'] as num?)?.toDouble() ?? 0,
      cash: (trx['nominal'] as num?)?.toDouble() ?? 0,
      change: (trx['changes'] as num?)?.toDouble() ?? 0,
      date: date,
      paymentMethod: paymentMethod,
      notes: trx['note']?.toString(),
      additionalPayment: additionalPayment,
      additionalPaymentMethod: additionalPaymentMethod,

      voucherCode: trx['voucher_code']?.toString(),
      voucherAmount: trx['voucher_amount'] != null
          ? (trx['voucher_amount'] as num).toDouble()
          : null,

      discountPercent: trx['discount_percent'] != null
          ? (trx['discount_percent'] as num).toInt()
          : null,
      discountAmount: trx['discount_amount'] != null
          ? (trx['discount_amount'] as num).toDouble()
          : null,

      cashAmount: (trx['nominal'] as num?)?.toDouble(),
      qrisAmount: (trx['qris'] as num?)?.toDouble(),
    );

    return OrderHistory(
      id: trx['_id']?.toString() ?? trx['trx_id']?.toString() ?? '',
      trxId: trx['trx_id']?.toString() ?? '',
      outletId: trx['outlet_id']?.toString() ?? '',
      outletName: trx['outlet_name']?.toString() ?? '',
      date: date,
      totalAmount: (trx['total'] as num?)?.toDouble() ?? 0,
      status: trx['status']?.toString() ?? 'completed',
      receipt: receipt,
    );
  }

  Future<List<OrderHistory>> getOrdersByOutlet(String outletId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/transactions/outlet/$outletId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['transactions'] != null) {
          final List<dynamic> transactions = data['transactions'];
          return transactions
              .map(
                (trx) =>
                    _transactionToOrderHistory(trx as Map<String, dynamic>),
              )
              .toList();
        }
      }

      return _getOrdersByOutletLocal(outletId);
    } catch (e) {
      print('Error fetching orders from API: $e');

      return _getOrdersByOutletLocal(outletId);
    }
  }

  Future<List<OrderHistory>> getOrdersByOutletAndDateRange(
    String outletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      print('[OrderHistoryRepository] Fetching orders for outlet: $outletId');
      print('[OrderHistoryRepository] Date range: $startStr to $endStr');

      final stopwatch = Stopwatch()..start();

      final response = await _dio.get(
        '$_baseUrl/transactions/outlet/$outletId/range',
        queryParameters: {'start_date': startStr, 'end_date': endStr},
      );

      stopwatch.stop();
      print(
        '[OrderHistoryRepository] API response time: ${stopwatch.elapsedMilliseconds}ms',
      );
      print('[OrderHistoryRepository] Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['transactions'] != null) {
          final List<dynamic> transactions = data['transactions'];
          print(
            '[OrderHistoryRepository] Fetched ${transactions.length} transactions from API',
          );
          print(
            '[OrderHistoryRepository] Source: ${data['source'] ?? 'unknown'}',
          );

          return transactions
              .map(
                (trx) =>
                    _transactionToOrderHistory(trx as Map<String, dynamic>),
              )
              .toList();
        } else {
          print('[OrderHistoryRepository] No transactions in response data');
        }
      } else {
        print(
          '[OrderHistoryRepository] Non-200 response: ${response.statusCode}',
        );
      }

      print('[OrderHistoryRepository] Falling back to local storage');
      return _getOrdersByOutletAndDateRangeLocal(outletId, startDate, endDate);
    } catch (e) {
      print('[OrderHistoryRepository] Error fetching orders from API: $e');
      print('[OrderHistoryRepository] Falling back to local storage');
      return _getOrdersByOutletAndDateRangeLocal(outletId, startDate, endDate);
    }
  }

  Future<List<OrderHistory>> getOrdersByOutletAndMonth(
    String outletId,
    int month,
    int year,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return getOrdersByOutletAndDateRange(outletId, startDate, endDate);
  }

  Future<void> saveOrder(OrderHistory order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getAllOrders();

    orders.insert(0, order);

    final jsonList = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_orderHistoryKey, json.encode(jsonList));
  }

  Future<List<OrderHistory>> getAllOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_orderHistoryKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => OrderHistory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderHistory>> _getOrdersByOutletLocal(String outletId) async {
    final orders = await getAllOrders();
    return orders.where((order) => order.outletId == outletId).toList();
  }

  Future<List<OrderHistory>> _getOrdersByOutletAndDateRangeLocal(
    String outletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final orders = await getAllOrders();

    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    return orders.where((order) {
      if (order.outletId != outletId) return false;

      final orderDate = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      );
      final startOnly = DateTime(
        normalizedStart.year,
        normalizedStart.month,
        normalizedStart.day,
      );
      final endOnly = DateTime(
        normalizedEnd.year,
        normalizedEnd.month,
        normalizedEnd.day,
      );

      return !orderDate.isBefore(startOnly) && !orderDate.isAfter(endOnly);
    }).toList();
  }

  Future<void> clearAllOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderHistoryKey);
  }

  Future<void> deleteOrder(String orderId) async {
    final orders = await getAllOrders();
    orders.removeWhere((order) => order.id == orderId);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_orderHistoryKey, json.encode(jsonList));
  }
}
