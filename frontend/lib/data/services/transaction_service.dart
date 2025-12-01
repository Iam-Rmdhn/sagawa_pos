import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';

/// Model for transaction item
class TransactionItemData {
  final String menuName;
  final int qty;
  final double price;
  final double subtotal;

  TransactionItemData({
    required this.menuName,
    required this.qty,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'menu_name': menuName,
      'qty': qty,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

/// Model for transaction data to send to backend
class TransactionData {
  final String trxId;
  final String outletId; // ID outlet dari akun login
  final String outletName; // Nama outlet
  final List<TransactionItemData> items;
  final String cashier;
  final String customer;
  final String? note;
  final String type; // dine_in / take_away
  final String method; // cash / qris
  final double nominal; // Uang yang diberikan customer (untuk cash)
  final double subtotal; // Jumlah harga sebelum pajak
  final double tax; // Pajak
  final double total; // Total setelah pajak
  final double qris; // Jumlah yang dibayar QRIS (jika metode QRIS)
  final double changes; // Kembalian (untuk cash)

  TransactionData({
    required this.trxId,
    required this.outletId,
    required this.outletName,
    required this.items,
    required this.cashier,
    required this.customer,
    this.note,
    required this.type,
    required this.method,
    required this.nominal,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.qris,
    required this.changes,
  });

  Map<String, dynamic> toJson() {
    return {
      'trx_id': trxId,
      'outlet_id': outletId,
      'outlet_name': outletName,
      'items': items.map((item) => item.toJson()).toList(),
      'cashier': cashier,
      'customer': customer,
      'note': note ?? '',
      'type': type,
      'method': method,
      'nominal': nominal,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'qris': qris,
      'changes': changes,
    };
  }
}

/// Service for handling transaction API calls
class TransactionService {
  final ApiClient _apiClient;

  TransactionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Save transaction to database
  /// Returns true if successful, throws exception if failed
  Future<bool> saveTransaction(TransactionData transaction) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.transactions,
        data: transaction.toJson(),
      );

      if (response.statusCode == 201) {
        print('DEBUG: Transaction saved successfully: ${transaction.trxId}');
        return true;
      } else {
        print('ERROR: Failed to save transaction: ${response.statusCode}');
        throw Exception('Failed to save transaction: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Exception while saving transaction: $e');
      rethrow;
    }
  }

  /// Get transactions by outlet ID
  Future<List<Map<String, dynamic>>> getTransactionsByOutlet(
    String outletId,
  ) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.transactionsByOutlet}/$outletId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final transactions = data['transactions'] as List<dynamic>;
        return transactions.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('ERROR: Failed to get transactions: ${response.statusCode}');
        throw Exception('Failed to get transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Exception while getting transactions: $e');
      rethrow;
    }
  }

  /// Get transactions by outlet ID and date range
  Future<List<Map<String, dynamic>>> getTransactionsByOutletAndDateRange(
    String outletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.get(
        '${ApiConfig.transactionsByOutlet}/$outletId/range',
        queryParameters: {'start_date': startStr, 'end_date': endStr},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final transactions = data['transactions'] as List<dynamic>;
        return transactions.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('ERROR: Failed to get transactions: ${response.statusCode}');
        throw Exception('Failed to get transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Exception while getting transactions: $e');
      rethrow;
    }
  }
}
