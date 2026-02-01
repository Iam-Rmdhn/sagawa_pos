import 'package:sagawa_pos/core/network/api_client.dart';
import 'package:sagawa_pos/core/network/api_config.dart';

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

class TransactionData {
  final String trxId;
  final String outletId;
  final String outletName;
  final List<TransactionItemData> items;
  final String cashier;
  final String customer;
  final String? note;
  final String type;
  final String method;
  final double nominal;
  final double subtotal;
  final double tax;
  final double total;
  final double qris;
  final double changes;
  final int? discountPercent;
  final double? discountAmount;

  final String? voucherCode;
  final double? voucherAmount;
  final double? additionalPayment;
  final String? additionalPaymentMethod;

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
    this.discountPercent,
    this.discountAmount,
    this.voucherCode,
    this.voucherAmount,
    this.additionalPayment,
    this.additionalPaymentMethod,
  });

  Map<String, dynamic> toJson() {
    final json = {
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

    if (discountPercent != null) {
      json['discount_percent'] = discountPercent!;
    }
    if (discountAmount != null) {
      json['discount_amount'] = discountAmount!;
    }

    if (voucherCode != null) {
      json['voucher_code'] = voucherCode!;
    }
    if (voucherAmount != null) {
      json['voucher_amount'] = voucherAmount!;
    }
    if (additionalPayment != null) {
      json['additional_payment'] = additionalPayment!;
    }
    if (additionalPaymentMethod != null) {
      json['additional_payment_method'] = additionalPaymentMethod!;
    }

    return json;
  }
}

class TransactionService {
  final ApiClient _apiClient;

  TransactionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<bool> saveTransaction(TransactionData transaction) async {
    try {
      final jsonData = transaction.toJson();
      print(
        '[TransactionService] Saving transaction: method=${jsonData['method']}, nominal=${jsonData['nominal']}, qris=${jsonData['qris']}',
      );

      final response = await _apiClient.post(
        ApiConfig.transactions,
        data: jsonData,
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
