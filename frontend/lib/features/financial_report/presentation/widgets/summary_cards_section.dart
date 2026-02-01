import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
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
      if (_isFreeTransaction(tx)) continue;
      total += tx.calculatedTotal;
    }
    return total;
  }

  double _getTotalPenjualan() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isFreeTransaction(tx)) continue;
      total += tx.subtotalSetelahPotongan;
    }
    return total;
  }

  double _getCashRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      final paymentMethod = tx.paymentMethod.toLowerCase();
      if (_isFreeTransaction(tx)) continue;
      if (paymentMethod.contains('qris')) continue;
      total += tx.subtotalSetelahPotongan;
    }
    return total;
  }

  double _getQrisRevenue() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      final paymentMethod = tx.paymentMethod.toLowerCase();
      if (_isFreeTransaction(tx)) continue;
      if (!paymentMethod.contains('qris')) continue;
      total += tx.subtotalSetelahPotongan;
    }
    return total;
  }

  double _getTotalTax() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (_isFreeTransaction(tx)) continue;
      total += tx.calculatedTax;
    }
    return total;
  }

  double _getTotalVoucherAmount() {
    double total = 0;
    for (final tx in widget.report.transactions) {
      if (tx.isVoucherPayment) {
        total += tx.totalPotongan;
      }
    }
    return total;
  }

  int _getVoucherCount() {
    int count = 0;
    for (final tx in widget.report.transactions) {
      if (tx.isVoucherPayment) {
        count++;
      }
    }
    return count;
  }

  int _getTransactionCount() {
    return widget.report.transactions.length;
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

    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isTablet = ResponsiveHelper.isTablet(context);

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
        if (isLandscape)
          _buildLandscapeLayout(
            context: context,
            isTablet: isTablet,
            totalPendapatan: totalPendapatan,
            totalPenjualan: totalPenjualan,
            transactionCount: transactionCount,
            cashRevenue: cashRevenue,
            qrisRevenue: qrisRevenue,
            totalTax: totalTax,
            totalVoucherAmount: totalVoucherAmount,
            voucherCount: voucherCount,
          )
        else
          _buildPortraitLayout(
            context: context,
            totalPendapatan: totalPendapatan,
            totalPenjualan: totalPenjualan,
            transactionCount: transactionCount,
            cashRevenue: cashRevenue,
            qrisRevenue: qrisRevenue,
            totalTax: totalTax,
            totalVoucherAmount: totalVoucherAmount,
            voucherCount: voucherCount,
          ),
      ],
    );
  }

  Widget _buildPortraitLayout({
    required BuildContext context,
    required double totalPendapatan,
    required double totalPenjualan,
    required int transactionCount,
    required double cashRevenue,
    required double qrisRevenue,
    required double totalTax,
    required double totalVoucherAmount,
    required int voucherCount,
  }) {
    return Column(
      children: [
        // Main card - Total Pendapatan (Featured)
        _MainSummaryCard(
          iconPath: AppImages.incomeIcon,
          title: 'Total Pendapatan',
          value: FinancialReport.formatCurrency(totalPendapatan),
          subtitle: '$transactionCount transaksi',
          color: const Color(0xFF1976D2),
          infoNote: 'Setelah potongan voucher/discount, termasuk PB1',
        ),
        const SizedBox(height: 12),

        // Row cards for other metrics
        _RowSummaryCard(
          iconPath: AppImages.salesIcon,
          title: 'Total Penjualan',
          value: FinancialReport.formatCurrency(totalPenjualan),
          color: const Color(0xFF4CAF50),
          infoNote: 'Setelah potongan voucher/discount, tanpa PB1',
        ),
        const SizedBox(height: 10),

        _RowSummaryCard(
          iconPath: AppImages.rupiahIcon,
          title: 'Pendapatan Cash',
          value: FinancialReport.formatCurrency(cashRevenue),
          color: const Color(0xFF66BB6A),
          infoNote: 'Termasuk tambahan cash dari voucher',
        ),
        const SizedBox(height: 10),

        _RowSummaryCard(
          iconPath: AppImages.qrcodeIcon,
          title: 'Pendapatan QRIS',
          value: FinancialReport.formatCurrency(qrisRevenue),
          color: const Color(0xFF7C4DFF),
          infoNote: 'Termasuk tambahan QRIS dari voucher',
        ),
        const SizedBox(height: 10),

        _RowSummaryCard(
          iconPath: AppImages.pajakIcon,
          title: 'Total PB1 (10%)',
          value: FinancialReport.formatCurrency(totalTax),
          color: const Color(0xFF00BCD4),
          infoNote: 'Total pajak dari semua transaksi',
        ),
        const SizedBox(height: 10),

        _RowSummaryCard(
          iconPath: AppImages.pocerIcon,
          title: 'Total Voucher',
          value: FinancialReport.formatCurrency(totalVoucherAmount),
          color: const Color(0xFFE91E63),
          badge: '$voucherCount voucher',
          infoNote: 'Total nominal voucher yang digunakan',
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout({
    required BuildContext context,
    required bool isTablet,
    required double totalPendapatan,
    required double totalPenjualan,
    required int transactionCount,
    required double cashRevenue,
    required double qrisRevenue,
    required double totalTax,
    required double totalVoucherAmount,
    required int voucherCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardHeight = 130.0;
        const spacing = 16.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side - Wider Cards (Top/Bottom)
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  SizedBox(
                    height: cardHeight,
                    child: SummaryCard(
                      iconPath: AppImages.incomeIcon,
                      title: 'Total Pendapatan',
                      value: FinancialReport.formatCurrency(totalPendapatan),
                      subtitle: '$transactionCount transaksi',
                      color: const Color(0xFF1976D2),
                      infoNote:
                          'Setelah potongan voucher/discount, termasuk PB1',
                      isLandscape: true,
                    ),
                  ),
                  const SizedBox(height: spacing),
                  SizedBox(
                    height: cardHeight,
                    child: SummaryCard(
                      iconPath: AppImages.salesIcon,
                      title: 'Total Penjualan',
                      value: FinancialReport.formatCurrency(totalPenjualan),
                      color: const Color(0xFF4CAF50),
                      infoNote: 'Setelah potongan voucher/discount, tanpa PB1',
                      isLandscape: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: spacing),
            // Right Side - 2x2 Grid
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: SummaryCard(
                            iconPath: AppImages.rupiahIcon,
                            title: 'Pendapatan Cash',
                            value: FinancialReport.formatCurrency(cashRevenue),
                            color: const Color(0xFF66BB6A),
                            infoNote: 'Termasuk tambahan cash dari voucher',
                            isLandscape: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: SummaryCard(
                            iconPath: AppImages.qrcodeIcon,
                            title: 'Pendapatan QRIS',
                            value: FinancialReport.formatCurrency(qrisRevenue),
                            color: const Color(0xFF7C4DFF),
                            infoNote: 'Termasuk tambahan QRIS dari voucher',
                            isLandscape: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacing),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: SummaryCard(
                            iconPath: AppImages.pajakIcon,
                            title: 'Total PB1 (10%)',
                            value: FinancialReport.formatCurrency(totalTax),
                            color: const Color(0xFF00BCD4),
                            infoNote: 'Total pajak dari semua transaksi',
                            isLandscape: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: SizedBox(
                          height: cardHeight,
                          child: SummaryCard(
                            iconPath: AppImages.pocerIcon,
                            title: 'Total Voucher',
                            value: FinancialReport.formatCurrency(
                              totalVoucherAmount,
                            ),
                            subtitle: '$voucherCount voucher',
                            color: const Color(0xFFE91E63),
                            infoNote: 'Total nominal voucher yang digunakan',
                            isLandscape: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Main featured card for portrait mode
class _MainSummaryCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final String? infoNote;

  const _MainSummaryCard({
    required this.iconPath,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
    this.infoNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ),
          ],
          if (infoNote != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    infoNote!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
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

/// Row style card for portrait mode
class _RowSummaryCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String value;
  final Color color;
  final String? infoNote;
  final String? badge;

  const _RowSummaryCard({
    required this.iconPath,
    required this.title,
    required this.value,
    required this.color,
    this.infoNote,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          SvgPicture.asset(
            iconPath,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 14),

          // Title and info description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (infoNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    infoNote!,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

          // Value and badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;
  final String? infoNote;
  final bool isLandscape;

  const SummaryCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
    this.infoNote,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    // Adjust sizes based on orientation
    final cardPadding = isLandscape ? 14.0 : (isMobile ? 16.0 : 20.0);
    final iconSize = isLandscape ? 24.0 : (isMobile ? 22.0 : 26.0);
    final titleSize = isLandscape ? 11.0 : (isMobile ? 12.0 : 14.0);
    final valueSize = isLandscape ? 16.0 : (isMobile ? 18.0 : 22.0);
    final subtitleSize = isLandscape ? 10.0 : (isMobile ? 11.0 : 13.0);
    final infoFontSize = isLandscape ? 9.0 : (isMobile ? 10.0 : 12.0);
    final infoIconSize = isLandscape ? 10.0 : (isMobile ? 12.0 : 14.0);

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
              SvgPicture.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isLandscape ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: isLandscape ? FontWeight.w900 : FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: isLandscape ? 2 : 4),
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
            SizedBox(height: isLandscape ? 4 : 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: infoIconSize,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    infoNote!,
                    style: TextStyle(
                      fontSize: infoFontSize,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: isLandscape ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
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
