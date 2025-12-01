import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';

/// Repository untuk mengelola data order history
class OrderHistoryRepository {
  static const String _orderHistoryKey = 'order_history';

  /// Simpan order ke history
  Future<void> saveOrder(OrderHistory order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getAllOrders();

    orders.insert(0, order); // Insert at beginning (newest first)

    final jsonList = orders.map((o) => o.toJson()).toList();
    await prefs.setString(_orderHistoryKey, json.encode(jsonList));
  }

  /// Ambil semua order history
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

  /// Filter order berdasarkan tanggal
  Future<List<OrderHistory>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final orders = await getAllOrders();
    return orders.where((order) {
      return order.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          order.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Filter order berdasarkan bulan
  Future<List<OrderHistory>> getOrdersByMonth(int month, int year) async {
    final orders = await getAllOrders();
    return orders.where((order) {
      return order.date.month == month && order.date.year == year;
    }).toList();
  }

  /// Filter order berdasarkan outlet ID
  Future<List<OrderHistory>> getOrdersByOutlet(String outletId) async {
    final orders = await getAllOrders();
    return orders.where((order) => order.outletId == outletId).toList();
  }

  /// Filter order berdasarkan outlet ID dan tanggal
  Future<List<OrderHistory>> getOrdersByOutletAndDateRange(
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

  /// Filter order berdasarkan outlet ID dan bulan
  Future<List<OrderHistory>> getOrdersByOutletAndMonth(
    String outletId,
    int month,
    int year,
  ) async {
    final orders = await getAllOrders();
    return orders.where((order) {
      return order.outletId == outletId &&
          order.date.month == month &&
          order.date.year == year;
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
