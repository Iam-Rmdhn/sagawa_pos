import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
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
  @override
  void initState() {
    super.initState();
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

  bool _isFreeTransaction(TransactionRecord tx) {
    final paymentMethod = tx.paymentMethod.toLowerCase();

    if (paymentMethod.contains('discount')) {
      if (paymentMethod.contains('100%') || paymentMethod.contains('100 %')) {
        if (!paymentMethod.contains('cash') &&
            !paymentMethod.contains('qris')) {
          return true;
        }
      }
      if (tx.subtotal <= 0) return true;
    }

    if (paymentMethod == 'voucher') {
      return true;
    }

    if (tx.isVoucherPayment &&
        tx.voucherAmount != null &&
        tx.voucherAmount! >= tx.subtotal) {
      return true;
    }

    return false;
  }

  double _getTotalPendapatan() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        if (_isFreeTransaction(tx)) continue;

        total += tx.calculatedTotal;
      }
    }
    return total;
  }

  double _getTotalPenjualan() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        if (_isFreeTransaction(tx)) continue;

        total += tx.subtotalSetelahPotongan;
      }
    }
    return total;
  }

  double _getCashRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        final paymentMethod = tx.paymentMethod.toLowerCase();

        if (_isFreeTransaction(tx)) continue;

        if (paymentMethod.contains('qris')) continue;

        total += tx.subtotalSetelahPotongan;
      }
    }
    return total;
  }

  double _getQrisRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        final paymentMethod = tx.paymentMethod.toLowerCase();

        if (_isFreeTransaction(tx)) continue;

        if (!paymentMethod.contains('qris')) continue;

        total += tx.subtotalSetelahPotongan;
      }
    }
    return total;
  }

  double _getTotalTax() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        if (_isFreeTransaction(tx)) continue;

        total += tx.calculatedTax;
      }
    }
    return total;
  }

  double _getTotalVoucherAmount() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        if (tx.isVoucherPayment) {
          total += tx.totalPotongan;
        }
      }
    }
    return total;
  }

  int _getVoucherCount() {
    int count = 0;
    for (final tx in widget.report.transactions) {
      if (_isInRange(tx.date)) {
        if (tx.isVoucherPayment) {
          count++;
        }
      }
    }
    return count;
  }

  int _getTransactionCount() {
    return widget.report.transactions.where((tx) => _isInRange(tx.date)).length;
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
    final totalPendapatan = _getTotalPendapatan();
    final totalPenjualan = _getTotalPenjualan();
    final transactionCount = _getTransactionCount();
    final cashRevenue = _getCashRevenue();
    final qrisRevenue = _getQrisRevenue();
    final totalTax = _getTotalTax();
    final totalVoucherAmount = _getTotalVoucherAmount();
    final voucherCount = _getVoucherCount();

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
                  width: constraints.maxWidth,
                  child: SummaryCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Total Pendapatan',
                    value: FinancialReport.formatCurrency(totalPendapatan),
                    subtitle: '$transactionCount transaksi',
                    color: const Color(0xFF1976D2),
                    infoNote: 'Setelah potongan voucher/discount, termasuk PB1',
                  ),
                ),

                SizedBox(
                  width: cardCount == 3 ? cardWidth : constraints.maxWidth,
                  child: SummaryCard(
                    icon: Icons.trending_up,
                    title: 'Total Penjualan',
                    value: FinancialReport.formatCurrency(totalPenjualan),
                    color: const Color(0xFF4CAF50),
                    infoNote: 'Setelah potongan voucher/discount, tanpa PB1',
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.money,
                    title: 'Pendapatan Cash',
                    value: FinancialReport.formatCurrency(cashRevenue),
                    color: const Color(0xFF66BB6A),
                    infoNote: 'Termasuk tambahan cash dari voucher',
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.qr_code,
                    title: 'Pendapatan QRIS',
                    value: FinancialReport.formatCurrency(qrisRevenue),
                    color: const Color(0xFF7C4DFF),
                    infoNote: 'Termasuk tambahan QRIS dari voucher',
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.account_balance,
                    title: 'PB1 Total (10%)',
                    value: FinancialReport.formatCurrency(totalTax),
                    color: const Color(0xFF00BCD4),
                    infoNote: 'Total pajak dari semua transaksi',
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    icon: Icons.card_giftcard,
                    title: 'Voucher Digunakan',
                    value: FinancialReport.formatCurrency(totalVoucherAmount),
                    subtitle: '$voucherCount voucher',
                    color: const Color(0xFFE91E63),
                    infoNote: 'Total nominal voucher yang digunakan',
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
  final String? subtitle;
  final String? infoNote;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
    this.infoNote,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final cardPadding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 22.0 : 26.0;
    final titleSize = isMobile ? 12.0 : 14.0;
    final valueSize = isMobile ? 18.0 : 22.0;
    final subtitleSize = isMobile ? 11.0 : 13.0;

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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
