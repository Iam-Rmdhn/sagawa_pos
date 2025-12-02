import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sagawa_pos_new/core/utils/indonesia_time.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt_item.dart';

/// Repository untuk mengelola data order history
class OrderHistoryRepository {
  static const String _orderHistoryKey = 'order_history';
  static const String _baseUrl = 'http://localhost:8080/api/v1';

  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10)
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

    // Parse date - API mengirim waktu dalam format RFC3339 dengan timezone
    // Kita parse dan konversi ke waktu Indonesia untuk konsistensi display
    DateTime date = IndonesiaTime.now();
    if (trx['created_at'] != null) {
      try {
        // DateTime.parse akan menghormati timezone info jika ada (Z atau +07:00)
        final parsed = DateTime.parse(trx['created_at'].toString());
        // Konversi ke waktu Indonesia untuk display yang konsisten
        date = IndonesiaTime.toIndonesiaTime(parsed);
      } catch (e) {
        // Keep default
      }
    }

    // Create Receipt
    final receipt = Receipt(
      storeName: trx['outlet_name']?.toString() ?? '',
      address: '',
      type: trx['type']?.toString() ?? 'Dine In',
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
      paymentMethod: trx['method']?.toString() ?? 'Cash',
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

  /// Get orders from API by outlet ID
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

      // Fallback to local storage if API fails
      return _getOrdersByOutletLocal(outletId);
    } catch (e) {
      print('Error fetching orders from API: $e');
      // Fallback to local storage
      return _getOrdersByOutletLocal(outletId);
    }
  }

  /// Get orders from API by outlet ID and date range
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

      final response = await _dio.get(
        '$_baseUrl/transactions/outlet/$outletId/range',
        queryParameters: {'start_date': startStr, 'end_date': endStr},
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

      // Fallback to local storage
      return _getOrdersByOutletAndDateRangeLocal(outletId, startDate, endDate);
    } catch (e) {
      print('Error fetching orders from API: $e');
      return _getOrdersByOutletAndDateRangeLocal(outletId, startDate, endDate);
    }
  }

  /// Get orders from API by outlet ID and month
  Future<List<OrderHistory>> getOrdersByOutletAndMonth(
    String outletId,
    int month,
    int year,
  ) async {
    // Calculate start and end of month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(
      year,
      month + 1,
      0,
      23,
      59,
      59,
    ); // Last day of month

    return getOrdersByOutletAndDateRange(outletId, startDate, endDate);
  }

  // ========== Local Storage Fallback Methods ==========

  /// Simpan order ke history (local)
  Future<void> saveOrder(OrderHistory order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getAllOrders();

    orders.insert(0, order); // Insert at beginning (newest first)

    final jsonList = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_orderHistoryKey, json.encode(jsonList));
  }

  /// Ambil semua order history (local)
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

  /// Filter order berdasarkan outlet ID (local fallback)
  Future<List<OrderHistory>> _getOrdersByOutletLocal(String outletId) async {
    final orders = await getAllOrders();
    return orders.where((order) => order.outletId == outletId).toList();
  }

  /// Filter order berdasarkan outlet ID dan tanggal (local fallback)
  Future<List<OrderHistory>> _getOrdersByOutletAndDateRangeLocal(
    String outletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final orders = await getAllOrders();
    return orders.where((order) {
      return order.outletId == outletId &&
          order.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          order.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Hapus semua order history
  Future<void> clearAllOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderHistoryKey);
  }

  /// Hapus order tertentu
  Future<void> deleteOrder(String orderId) async {
    final orders = await getAllOrders();
    orders.removeWhere((order) => order.id == orderId);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_orderHistoryKey, json.encode(jsonList));
  }
}
