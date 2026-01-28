import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/data/services/settings_service.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/features/financial_report/presentation/pages/financial_report_page.dart';

class SummaryCardsSection extends StatefulWidget {
  final FinancialReport report;
  final ReportTab tab;
  final DateTimeRange? customDateRange;

  const SummaryCardsSection({
    super.key,
    required this.report,
    required this.tab,
    this.customDateRange,
  });

  @override
  State<SummaryCardsSection> createState() => _SummaryCardsSectionState();
}

class _SummaryCardsSectionState extends State<SummaryCardsSection> {
  bool _isTaxEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTaxSetting();
  }

  Future<void> _loadTaxSetting() async {
    final taxEnabled = await SettingsService.isTaxEnabled();
    if (mounted) {
      setState(() => _isTaxEnabled = taxEnabled);
    }
  }

  bool _isInRange(DateTime txDate) {
    final now = IndonesiaTime.now();
    final date = DateTime(txDate.year, txDate.month, txDate.day);

    switch (widget.tab) {
      case ReportTab.today:
        return txDate.year == now.year &&
            txDate.month == now.month &&
            txDate.day == now.day;
      case ReportTab.week:
        final weekday = now.weekday;
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
      case ReportTab.month:
        return txDate.year == now.year && txDate.month == now.month;
      case ReportTab.custom:
        if (widget.customDateRange == null) return false;
        final start = DateTime(
          widget.customDateRange!.start.year,
          widget.customDateRange!.start.month,
          widget.customDateRange!.start.day,
        );
        final end = DateTime(
          widget.customDateRange!.end.year,
          widget.customDateRange!.end.month,
          widget.customDateRange!.end.day,
        ).add(const Duration(days: 1));
        return !date.isBefore(start) && date.isBefore(end);
    }
  }

  bool _isFullDiscount(TransactionRecord tx) {
    final paymentMethod = tx.paymentMethod.toLowerCase();
    if (paymentMethod.contains('discount')) {
      if (tx.subtotal <= 0) {
        return true;
      }
      if (!paymentMethod.contains('cash') && !paymentMethod.contains('qris')) {
        return true;
      }
    }
    return false;
  }

  /// Check if transaction is a pure voucher (100% covered by voucher)
  bool _isPureVoucher(TransactionRecord tx) {
    final paymentMethod = tx.paymentMethod.toLowerCase();
    // Pure voucher: payment method is exactly "voucher" (not "voucher + cash" or "voucher + qris")
    return paymentMethod == 'voucher';
  }

  /// Get actual revenue for a transaction (accounting for voucher/discount)
  /// Revenue is calculated WITHOUT tax (tax is shown separately in PB1 card)
  /// For voucher payments: additionalPayment - changes (net payment received)
  double _getActualTransactionRevenue(TransactionRecord tx) {
    final paymentMethod = tx.paymentMethod.toLowerCase();

    // Full discount (100%) - no revenue
    if (_isFullDiscount(tx)) {
      return 0.0;
    }

    // Pure voucher (covers 100%) - no revenue
    if (_isPureVoucher(tx)) {
      return 0.0;
    }

    // Voucher + Cash/QRIS: additionalPayment - changes (net amount received)
    if (paymentMethod.contains('voucher')) {
      if (tx.additionalPayment != null && tx.additionalPayment! > 0) {
        final changes = tx.changes ?? 0.0;
        // Net revenue = what customer paid - change given back
        return tx.additionalPayment! - changes;
      }
      // Legacy data fallback: use total if less than full price
      final fullPrice = tx.subtotal + tx.tax;
      if (tx.total < fullPrice && tx.total > 0) {
        return tx.total;
      }
      return 0.0;
    }

    // Regular payment or Discount + Cash/QRIS - use subtotal (WITHOUT tax)
    // Tax is calculated separately in PB1 card
    return tx.subtotal;
  }

  double _getRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        total += _getActualTransactionRevenue(tx);
      }
    }
    return total;
  }

  int _getTransactionCount() {
    return widget.report.transactions.where((tx) => _isInRange(tx.date)).length;
  }

  double _getAveragePerTransaction() {
    final count = _getTransactionCount();
    if (count == 0) return 0;
    return _getRevenue() / count;
  }

  double _getCashRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date) && !_isFullDiscount(tx) && !_isPureVoucher(tx)) {
        final paymentMethod = tx.paymentMethod.toLowerCase();

        // Cash payment (not QRIS)
        if (!paymentMethod.contains('qris')) {
          if (paymentMethod.contains('voucher') &&
              paymentMethod.contains('cash')) {
            // Voucher + Cash: additionalPayment - changes
            if (tx.additionalPayment != null && tx.additionalPayment! > 0) {
              final changes = tx.changes ?? 0.0;
              total += tx.additionalPayment! - changes;
            } else {
              // Legacy data fallback
              final fullPrice = tx.subtotal + tx.tax;
              if (tx.total < fullPrice && tx.total > 0) {
                total += tx.total;
              }
            }
          } else if (!paymentMethod.contains('voucher')) {
            // Pure Cash or Discount + Cash - use subtotal (WITHOUT tax)
            total += tx.subtotal;
          }
        }
      }
    }
    return total;
  }

  double _getQrisRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date) && !_isFullDiscount(tx) && !_isPureVoucher(tx)) {
        final paymentMethod = tx.paymentMethod.toLowerCase();

        if (paymentMethod.contains('qris')) {
          if (paymentMethod.contains('voucher')) {
            // Voucher + QRIS: additionalPayment - changes (usually no change for QRIS)
            if (tx.additionalPayment != null && tx.additionalPayment! > 0) {
              final changes = tx.changes ?? 0.0;
              total += tx.additionalPayment! - changes;
            } else {
              // Legacy data fallback
              final fullPrice = tx.subtotal + tx.tax;
              if (tx.total < fullPrice && tx.total > 0) {
                total += tx.total;
              }
            }
          } else {
            // Pure QRIS or Discount + QRIS - use subtotal (WITHOUT tax)
            total += tx.subtotal;
          }
        }
      }
    }
    return total;
  }

  int _getVoucherCount() {
    int count = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        final paymentMethod = tx.paymentMethod.toLowerCase();
        if (paymentMethod.contains('voucher')) {
          count++;
        }
      }
    }
    return count;
  }

  double _getTotalTax() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        final paymentMethod = tx.paymentMethod.toLowerCase();

        // For full discount or pure voucher, no tax revenue
        if (_isFullDiscount(tx) || _isPureVoucher(tx)) {
          continue;
        }

        // For voucher + cash/qris, calculate proportional tax
        if (paymentMethod.contains('voucher')) {
          // Calculate proportional tax based on actual payment vs full amount
          final actualRevenue = _getActualTransactionRevenue(tx);
          final fullAmount = tx.subtotal + tx.tax;
          if (fullAmount > 0) {
            final taxPortion = tx.tax * (actualRevenue / fullAmount);
            total += taxPortion;
          }
        } else {
          // Full tax for normal payments
          total += tx.tax;
        }
      }
    }
    return total;
  }

  String _getTabLabel() {
    switch (widget.tab) {
      case ReportTab.today:
        return 'Hari Ini';
      case ReportTab.week:
        return 'Minggu Ini';
      case ReportTab.month:
        return 'Bulan Ini';
      case ReportTab.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _getRevenue();
    final transactionCount = _getTransactionCount();
    final average = _getAveragePerTransaction();
    final cashRevenue = _getCashRevenue();
    final qrisRevenue = _getQrisRevenue();
    final voucherCount = _getVoucherCount();
    final totalTax = _getTotalTax();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan ${_getTabLabel()}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 18,
              tablet: 20,
            ),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardCount = constraints.maxWidth > 600 ? 3 : 2;
            final spacing = 12.0;
            final totalSpacing = spacing * (cardCount - 1);
            final cardWidth = (constraints.maxWidth - totalSpacing) / cardCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardCount == 3 ? cardWidth : constraints.maxWidth,
                  child: SummaryCard(
                    icon: Icons.trending_up,
                    title: 'Total Penjualan',
                    value: FinancialReport.formatCurrency(revenue),
                    color: const Color(0xFF4CAF50),
                    infoNote: _isTaxEnabled
                        ? 'Pajak dihitung terpisah termasuk qris/cash'
                        : null,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.receipt_long,
                    title: 'Jumlah Transaksi',
                    value: '$transactionCount',
                    color: const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.calculate,
                    title: 'Rata-rata / Transaksi',
                    value: FinancialReport.formatCurrency(average),
                    color: const Color(0xFFFF9800),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.money,
                    title: 'Pendapatan Cash',
                    value: FinancialReport.formatCurrency(cashRevenue),
                    color: const Color(0xFF66BB6A),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.qr_code,
                    title: 'Pendapatan QRIS',
                    value: FinancialReport.formatCurrency(qrisRevenue),
                    color: const Color(0xFF7C4DFF),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.card_giftcard,
                    title: 'Transaksi Voucher',
                    value: '$voucherCount Transaksi',
                    color: const Color(0xFFE91E63),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.account_balance,
                    title: 'PB1 10%',
                    value: FinancialReport.formatCurrency(totalTax),
                    color: const Color(0xFF00BCD4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? infoNote;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.infoNote,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final cardPadding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 22.0 : 26.0;
    final titleSize = isMobile ? 12.0 : 14.0;
    final valueSize = isMobile ? 18.0 : 22.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (infoNote != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isMobile ? 12 : 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    infoNote!,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
