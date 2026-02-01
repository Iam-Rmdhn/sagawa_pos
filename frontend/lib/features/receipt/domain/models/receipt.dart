import 'package:sagawa_pos/features/receipt/domain/models/receipt_item.dart';

class Receipt {
  final String storeName;
  final String address;
  final String type;
  final String trxId;
  final String cashier;
  final String customerName;
  final List<ReceiptItem> items;
  final double subTotal;
  final double tax;
  final double afterTax;
  final double cash;
  final double change;
  final DateTime date;
  final String? logoPath;
  final String paymentMethod;

  final String? voucherCode;
  final double? voucherAmount;
  final double? additionalPayment;
  final String? additionalPaymentMethod;

  final int? discountPercent;
  final double? discountAmount;

  final double? cashAmount;
  final double? qrisAmount;

  final String? notes;

  Receipt({
    required this.storeName,
    required this.address,
    required this.type,
    required this.trxId,
    required this.cashier,
    required this.customerName,
    required this.items,
    required this.subTotal,
    required this.tax,
    required this.afterTax,
    required this.cash,
    required this.change,
    required this.date,
    this.logoPath,
    this.paymentMethod = 'Cash',
    this.voucherCode,
    this.voucherAmount,
    this.additionalPayment,
    this.additionalPaymentMethod,
    this.discountPercent,
    this.discountAmount,
    this.cashAmount,
    this.qrisAmount,
    this.notes,
  });

  bool get isVoucherPayment => paymentMethod.toLowerCase().contains('voucher');

  bool get isDiscountPayment =>
      paymentMethod.toLowerCase().contains('discount') &&
      discountPercent != null;

  bool get hasAdditionalPayment =>
      isVoucherPayment && additionalPayment != null && additionalPayment! > 0;

  int get totalItems => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPembelian => subTotal;

  double get totalPotongan {
    if (isVoucherPayment) {
      if (voucherAmount != null && voucherAmount! > 0) {
        return voucherAmount!;
      }

      if (afterTax > 0 && afterTax < (subTotal * 1.1)) {
        final subtotalAfterVoucher = afterTax / 1.1;
        final estimatedVoucher = subTotal - subtotalAfterVoucher;
        if (estimatedVoucher > 0 && estimatedVoucher <= subTotal) {
          return estimatedVoucher;
        }
      }
      return 0.0;
    }
    if (isDiscountPayment) {
      if (discountAmount != null && discountAmount! > 0) {
        return discountAmount!;
      }

      if (discountPercent != null && discountPercent! > 0) {
        return (subTotal * discountPercent! / 100);
      }

      if (afterTax > 0 && afterTax < (subTotal * 1.1)) {
        final subtotalAfterDiscount = afterTax / 1.1;
        final estimatedDiscount = subTotal - subtotalAfterDiscount;
        if (estimatedDiscount > 0 && estimatedDiscount <= subTotal) {
          return estimatedDiscount;
        }
      }
      return 0.0;
    }
    return 0.0;
  }

  double get totalSetelahPotongan {
    final total = totalPembelian - totalPotongan;
    return total > 0 ? total : 0.0;
  }

  double get calculatedTax {
    if (hasPotongan) {
      return totalSetelahPotongan * 0.10;
    }

    if (tax > 0) return tax;
    return subTotal * 0.10;
  }

  bool get hasPotongan => totalPotongan > 0;

  double get subTotalFinal {
    if (hasPotongan) {
      return totalSetelahPotongan + calculatedTax;
    }

    if (afterTax > 0) {
      return afterTax;
    }
    return totalSetelahPotongan + calculatedTax;
  }

  double get afterTaxFinal => subTotalFinal;

  bool get isFreeTransaction {
    if (isDiscountPayment && discountPercent == 100) return true;
    if (isVoucherPayment && !hasAdditionalPayment && totalSetelahPotongan <= 0)
      return true;
    return false;
  }

  double get calculatedChange {
    if (isFreeTransaction) return 0.0;

    if (paymentMethodDisplay == 'QRIS') return 0.0;

    if (isVoucherPayment &&
        hasAdditionalPayment &&
        additionalPaymentMethod == 'Cash') {
      final changeValue = additionalPayment! - subTotalFinal;
      return changeValue > 0 ? changeValue : 0.0;
    }

    if (isDiscountPayment && paymentMethod.toLowerCase().contains('cash')) {
      final changeValue = cash - subTotalFinal;
      return changeValue > 0 ? changeValue : 0.0;
    }

    if (paymentMethod == 'Cash' || paymentMethodDisplay == 'Cash') {
      final changeValue = cash - subTotalFinal;
      return changeValue > 0 ? changeValue : 0.0;
    }

    return 0.0;
  }

  bool get hasChange {
    return calculatedChange > 0 && paymentMethodDisplay.contains('Cash');
  }

  double get amountPaid {
    if (isVoucherPayment && hasAdditionalPayment) {
      return additionalPayment!;
    }
    return cash;
  }

  String get paymentMethodDisplay {
    if (isFreeTransaction) {
      return '-';
    }
    if (isVoucherPayment) {
      if (hasAdditionalPayment) {
        return additionalPaymentMethod ?? 'Cash';
      }

      return '-';
    }
    if (isDiscountPayment) {
      return paymentMethod.contains('QRIS') ? 'QRIS' : 'Cash';
    }
    return paymentMethod;
  }

  List<ReceiptItem> get groupedItems {
    final Map<String, ReceiptItem> itemMap = {};

    for (var item in items) {
      final key = '${item.name}_${item.price}';

      if (itemMap.containsKey(key)) {
        final existing = itemMap[key]!;
        itemMap[key] = ReceiptItem(
          name: existing.name,
          quantity: existing.quantity + item.quantity,
          price: existing.price,
          subtotal: existing.subtotal + item.subtotal,
        );
      } else {
        itemMap[key] = item;
      }
    }

    return itemMap.values.toList();
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      storeName: json['storeName'] as String,
      address: json['address'] as String,
      type: json['type'] as String,
      trxId: json['trxId'] as String,
      cashier: json['cashier'] as String,
      customerName: json['customerName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subTotal: (json['subTotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      afterTax: (json['afterTax'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      logoPath: json['logoPath'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      voucherCode: json['voucherCode'] as String?,
      voucherAmount: json['voucherAmount'] != null
          ? (json['voucherAmount'] as num).toDouble()
          : null,
      additionalPayment: json['additionalPayment'] != null
          ? (json['additionalPayment'] as num).toDouble()
          : null,
      additionalPaymentMethod: json['additionalPaymentMethod'] as String?,
      discountPercent: json['discountPercent'] as int?,
      discountAmount: json['discountAmount'] != null
          ? (json['discountAmount'] as num).toDouble()
          : null,
      cashAmount: json['cashAmount'] != null
          ? (json['cashAmount'] as num).toDouble()
          : null,
      qrisAmount: json['qrisAmount'] != null
          ? (json['qrisAmount'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'address': address,
      'type': type,
      'trxId': trxId,
      'cashier': cashier,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'subTotal': subTotal,
      'tax': tax,
      'afterTax': afterTax,
      'cash': cash,
      'change': change,
      'date': date.toIso8601String(),
      'logoPath': logoPath,
      'paymentMethod': paymentMethod,
      'voucherCode': voucherCode,
      'voucherAmount': voucherAmount,
      'additionalPayment': additionalPayment,
      'additionalPaymentMethod': additionalPaymentMethod,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'cashAmount': cashAmount,
      'qrisAmount': qrisAmount,
      'notes': notes,
    };
  }
}
