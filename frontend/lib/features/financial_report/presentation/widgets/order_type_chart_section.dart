import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/features/financial_report/presentation/pages/financial_report_page.dart';

class OrderTypeChartSection extends StatelessWidget {
  final FinancialReport report;
  final ReportTab tab;
  final DateTimeRange? customDateRange;

  const OrderTypeChartSection({
    super.key,
    required this.report,
    required this.tab,
    this.customDateRange,
  });

  Map<String, int> _getOrderTypeCounts() {
    final now = IndonesiaTime.now();
    int dineInCount = 0;
    int takeAwayCount = 0;

    for (final tx in report.transactions) {
      bool isInRange = false;
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      switch (tab) {
        case ReportTab.today:
          isInRange =
              tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
          break;
        case ReportTab.week:
          final weekday = now.weekday;
          final startOfWeek = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          isInRange =
              !txDate.isBefore(startOfWeek) && txDate.isBefore(endOfWeek);
          break;
        case ReportTab.month:
          isInRange = tx.date.year == now.year && tx.date.month == now.month;
          break;
        case ReportTab.custom:
          if (customDateRange != null) {
            final start = DateTime(
              customDateRange!.start.year,
              customDateRange!.start.month,
              customDateRange!.start.day,
            );
            final end = DateTime(
              customDateRange!.end.year,
              customDateRange!.end.month,
              customDateRange!.end.day,
            ).add(const Duration(days: 1));
            isInRange = !txDate.isBefore(start) && txDate.isBefore(end);
          }
          break;
      }

      if (isInRange) {
        if (tx.type.toLowerCase() == 'dine in' ||
            tx.type.toLowerCase() == 'dine-in') {
          dineInCount++;
        } else {
          takeAwayCount++;
        }
      }
    }

    return {'dineIn': dineInCount, 'takeAway': takeAwayCount};
  }

  @override
  Widget build(BuildContext context) {
    final counts = _getOrderTypeCounts();
    final dineInCount = counts['dineIn']!;
    final takeAwayCount = counts['takeAway']!;
    final total = dineInCount + takeAwayCount;

    final dineInPercentage = total > 0 ? (dineInCount / total) * 100 : 0.0;
    final takeAwayPercentage = total > 0 ? (takeAwayCount / total) * 100 : 0.0;

    final isLandscape = ResponsiveHelper.isTabletLandscape(context);
    final padding = isLandscape ? 16.0 : 20.0;
    final titleSize = isLandscape ? 16.0 : 18.0;
    final chartHeight = isLandscape ? 140.0 : 180.0;
    final centerRadius = isLandscape ? 30.0 : 40.0;
    final pieRadius = isLandscape ? 40.0 : 50.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tipe Pesanan',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 20),
          total == 0
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(isLandscape ? 20 : 40),
                    child: const Text(
                      'Belum ada data pesanan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : isLandscape
              ? _buildLandscapeLayout(
                  dineInCount,
                  takeAwayCount,
                  dineInPercentage,
                  takeAwayPercentage,
                  total,
                  chartHeight,
                  centerRadius,
                  pieRadius,
                )
              : _buildPortraitLayout(
                  dineInCount,
                  takeAwayCount,
                  dineInPercentage,
                  takeAwayPercentage,
                  total,
                  chartHeight,
                  centerRadius,
                  pieRadius,
                ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    int dineInCount,
    int takeAwayCount,
    double dineInPercentage,
    double takeAwayPercentage,
    int total,
    double chartHeight,
    double centerRadius,
    double pieRadius,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: chartHeight,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: centerRadius,
                sections: [
                  PieChartSectionData(
                    value: dineInCount.toDouble(),
                    color: const Color(0xFF42A5F5),
                    radius: pieRadius,
                    title: '${dineInPercentage.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: takeAwayCount.toDouble(),
                    color: const Color(0xFF66BB6A),
                    radius: pieRadius,
                    title: '${takeAwayPercentage.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendItem(
                color: const Color(0xFF42A5F5),
                label: 'Dine In',
                count: dineInCount,
              ),
              const SizedBox(height: 16),
              LegendItem(
                color: const Color(0xFF66BB6A),
                label: 'Take Away',
                count: takeAwayCount,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Total: $total pesanan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    int dineInCount,
    int takeAwayCount,
    double dineInPercentage,
    double takeAwayPercentage,
    int total,
    double chartHeight,
    double centerRadius,
    double pieRadius,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: chartHeight,
              height: chartHeight,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: centerRadius,
                  sections: [
                    PieChartSectionData(
                      value: dineInCount.toDouble(),
                      color: const Color(0xFF42A5F5),
                      radius: pieRadius,
                      title: '${dineInPercentage.toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: takeAwayCount.toDouble(),
                      color: const Color(0xFF66BB6A),
                      radius: pieRadius,
                      title: '${takeAwayPercentage.toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $total pesanan',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CompactLegendItem(
                color: const Color(0xFF42A5F5),
                label: 'Dine In',
                count: dineInCount,
              ),
              const SizedBox(height: 8),
              CompactLegendItem(
                color: const Color(0xFF66BB6A),
                label: 'Take Away',
                count: takeAwayCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count pesanan',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CompactLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const CompactLegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
