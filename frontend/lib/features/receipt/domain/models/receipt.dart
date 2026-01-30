import 'package:sagawa_pos/features/receipt/domain/models/receipt_item.dart';

class Receipt {
  final String storeName;
  final String address;
  final String type; // "Dine In" or "Take Away"
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
  final String
  paymentMethod; // "Cash", "QRIS", "Voucher", "Voucher + Cash", "Voucher + QRIS", "Discount"
  // Voucher fields
  final String? voucherCode;
  final double? voucherAmount;
  final double? additionalPayment; // For voucher + cash/qris
  final String? additionalPaymentMethod; // "Cash" or "QRIS"
  // Discount fields
  final int? discountPercent; // 5, 10, 15, 20, 25, 30, 100
  final double? discountAmount;
  // Payment amounts from backend (for discount payment revenue calculation)
  final double? cashAmount; // Actual cash paid (from nominal field)
  final double? qrisAmount; // Actual qris paid (from qris field)
  // Order notes
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
    this.paymentMethod = 'Cash', // Default to Cash
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

  // Check if payment uses voucher
  // Lebih permisif - cukup cek payment method contains 'voucher'
  // karena data lama mungkin tidak memiliki voucherCode
  bool get isVoucherPayment => paymentMethod.toLowerCase().contains('voucher');

  // Check if payment uses discount
  bool get isDiscountPayment =>
      paymentMethod.toLowerCase().contains('discount') &&
      discountPercent != null;

  // Check if voucher has additional payment
  bool get hasAdditionalPayment =>
      isVoucherPayment && additionalPayment != null && additionalPayment! > 0;

  int get totalItems => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // ============== COMPUTED PROPERTIES FOR STRUCTURED CALCULATION ==============
  // Struktur: Menu -> Total Pembelian -> Potongan -> Total -> Tax -> Subtotal

  /// Total Pembelian = Subtotal (harga menu sebelum potongan dan pajak)
  double get totalPembelian => subTotal;

  /// Total Potongan (Voucher atau Discount)
  double get totalPotongan {
    if (isVoucherPayment) {
      // PRIORITAS 1: voucherAmount langsung
      if (voucherAmount != null && voucherAmount! > 0) {
        return voucherAmount!;
      }
      // PRIORITAS 2: Estimasi dari data yang tersedia
      // Jika afterTax sudah benar (dihitung dengan rumus), kita bisa estimasi voucher
      // afterTax = (subTotal - voucher) × 1.1
      // voucher = subTotal - (afterTax / 1.1)
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
      // PRIORITAS 1: discountAmount langsung
      if (discountAmount != null && discountAmount! > 0) {
        return discountAmount!;
      }
      // PRIORITAS 2: Hitung dari discountPercent jika tersedia
      if (discountPercent != null && discountPercent! > 0) {
        return (subTotal * discountPercent! / 100);
      }
      // PRIORITAS 3: Estimasi dari afterTax
      // afterTax = (subTotal - discount) × 1.1
      // discount = subTotal - (afterTax / 1.1)
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

  /// Total setelah potongan (sebelum pajak)
  double get totalSetelahPotongan {
    final total = totalPembelian - totalPotongan;
    return total > 0 ? total : 0.0;
  }

  /// Tax 10% dihitung dari total setelah potongan
  /// RUMUS: (subtotal - potongan) × 0.1
  double get calculatedTax {
    // Jika ada potongan (voucher/discount), SELALU hitung tax dari totalSetelahPotongan
    // Tidak boleh menggunakan tax dari input karena bisa jadi salah
    if (hasPotongan) {
      return totalSetelahPotongan * 0.10;
    }
    // Jika tidak ada potongan, gunakan tax dari input atau hitung dari subtotal
    if (tax > 0) return tax;
    return subTotal * 0.10;
  }

  /// Check apakah ada potongan (voucher atau discount)
  bool get hasPotongan => totalPotongan > 0;

  /// Sub total = Total setelah potongan + Tax (minimal 0)
  /// Selalu hitung ulang untuk memastikan konsistensi dengan rumus
  double get subTotalFinal {
    // Jika ada potongan, hitung dengan rumus yang benar
    if (hasPotongan) {
      return totalSetelahPotongan + calculatedTax;
    }
    // Untuk pembayaran normal tanpa potongan
    // Gunakan afterTax dari input jika tersedia dan valid
    if (afterTax > 0) {
      return afterTax;
    }
    return totalSetelahPotongan + calculatedTax;
  }

  /// After Tax (alias untuk subTotalFinal untuk display)
  double get afterTaxFinal => subTotalFinal;

  /// Check apakah ini pembayaran gratis (voucher 100% atau discount 100%)
  bool get isFreeTransaction {
    if (isDiscountPayment && discountPercent == 100) return true;
    if (isVoucherPayment && !hasAdditionalPayment && totalSetelahPotongan <= 0)
      return true;
    return false;
  }

  /// Computed change yang dihitung dari data receipt
  /// SELALU hitung ulang untuk memastikan perhitungan benar
  /// Rumus: Change = Paid - Total (After Tax)
  double get calculatedChange {
    // Free transaction: no change
    if (isFreeTransaction) return 0.0;

    // QRIS payment: never has change
    if (paymentMethodDisplay == 'QRIS') return 0.0;

    // Voucher + Cash: hitung shortfall dan change
    if (isVoucherPayment &&
        hasAdditionalPayment &&
        additionalPaymentMethod == 'Cash') {
      // Change = additionalPayment (yang dibayar) - subTotalFinal (total setelah voucher + tax)
      final changeValue = additionalPayment! - subTotalFinal;
      return changeValue > 0 ? changeValue : 0.0;
    }

    // Discount + Cash: change = cash - total setelah discount
    if (isDiscountPayment && paymentMethod.toLowerCase().contains('cash')) {
      final changeValue = cash - subTotalFinal;
      return changeValue > 0 ? changeValue : 0.0;
    }

    // Regular Cash payment: change = cash - total (After Tax)
    if (paymentMethod == 'Cash' || paymentMethodDisplay == 'Cash') {
      final changeValue = cash - subTotalFinal;
      return changeValue > 0 ? changeValue : 0.0;
    }

    return 0.0;
  }

  /// Check apakah ada kembalian yang perlu ditampilkan
  bool get hasChange {
    return calculatedChange > 0 && paymentMethodDisplay.contains('Cash');
  }

  /// Jumlah yang dibayarkan customer (cash atau additional payment)
  double get amountPaid {
    if (isVoucherPayment && hasAdditionalPayment) {
      return additionalPayment!;
    }
    return cash;
  }

  /// Label untuk metode pembayaran (hanya Cash atau QRIS, tidak ada "Voucher + Cash")
  String get paymentMethodDisplay {
    if (isFreeTransaction) {
      return '-';
    }
    if (isVoucherPayment) {
      // Untuk voucher, hanya tampilkan metode pembayaran tambahan (Cash/QRIS)
      if (hasAdditionalPayment) {
        return additionalPaymentMethod ?? 'Cash';
      }
      // Jika voucher mencukupi tapi bukan free transaction, tampilkan '-'
      return '-';
    }
    if (isDiscountPayment) {
      return paymentMethod.contains('QRIS') ? 'QRIS' : 'Cash';
    }
    return paymentMethod; // Cash atau QRIS
  }

  /// Get grouped items (menggabungkan item yang sama)
  /// Item dengan nama dan harga yang sama akan digabungkan quantity-nya
  List<ReceiptItem> get groupedItems {
    final Map<String, ReceiptItem> itemMap = {};

    for (var item in items) {
      // Gunakan kombinasi nama dan harga sebagai key
      final key = '${item.name}_${item.price}';

      if (itemMap.containsKey(key)) {
        // Item sudah ada, tambahkan quantity
        final existing = itemMap[key]!;
        itemMap[key] = ReceiptItem(
          name: existing.name,
          quantity: existing.quantity + item.quantity,
          price: existing.price,
          subtotal: existing.subtotal + item.subtotal,
        );
      } else {
        // Item baru, tambahkan ke map
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
