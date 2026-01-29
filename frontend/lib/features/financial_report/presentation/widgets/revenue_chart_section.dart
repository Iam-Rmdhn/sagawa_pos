import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/features/financial_report/presentation/pages/financial_report_page.dart';

class RevenueChartSection extends StatefulWidget {
  final ReportTab tab;
  final FinancialReport report;
  final DateTimeRange? customDateRange;

  const RevenueChartSection({
    super.key,
    required this.tab,
    required this.report,
    this.customDateRange,
  });

  @override
  State<RevenueChartSection> createState() => _RevenueChartSectionState();
}

class _RevenueChartSectionState extends State<RevenueChartSection> {
  final ScrollController _scrollController = ScrollController();

  ReportTab get tab => widget.tab;
  FinancialReport get report => widget.report;
  DateTimeRange? get customDateRange => widget.customDateRange;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Menghitung total pendapatan per transaksi
  /// Total = (subtotal - voucherAmount/discountAmount) + tax (setelah potongan + pajak)
  /// Sinkron dengan nilai "After Tax" di detail order
  double _getTransactionRevenue(TransactionRecord tx) {
    // Skip free transactions
    if (_isFreeTransaction(tx)) return 0.0;

    // Gunakan computed property dari TransactionRecord
    return tx.calculatedTotal;
  }

  /// Check apakah transaksi free (discount 100% tanpa pembayaran atau pure voucher)
  bool _isFreeTransaction(TransactionRecord tx) {
    final paymentMethod = tx.paymentMethod.toLowerCase();

    // Discount 100% tanpa pembayaran cash/qris
    if (paymentMethod.contains('discount')) {
      if (paymentMethod.contains('100%') || paymentMethod.contains('100 %')) {
        if (!paymentMethod.contains('cash') &&
            !paymentMethod.contains('qris')) {
          return true;
        }
      }
      if (tx.subtotal <= 0) return true;
    }

    // Pure voucher (voucher menutupi semua)
    if (paymentMethod == 'voucher') {
      return true;
    }

    // Voucher yang menutupi seluruh subtotal
    if (tx.isVoucherPayment &&
        tx.voucherAmount != null &&
        tx.voucherAmount! >= tx.subtotal) {
      return true;
    }

    return false;
  }

  List<Map<String, dynamic>> _generateChartData() {
    switch (tab) {
      case ReportTab.today:
        return _getHourlyData();
      case ReportTab.week:
        return _getWeeklyData();
      case ReportTab.month:
        return _getMonthlyData();
      case ReportTab.custom:
        return _getCustomRangeData();
    }
  }

  List<Map<String, dynamic>> _getCustomRangeData() {
    if (customDateRange == null) {
      return [
        {'label': '-', 'value': 0.0},
      ];
    }

    final start = customDateRange!.start;
    final end = customDateRange!.end;
    final daysDiff = end.difference(start).inDays + 1;

    final dailyRevenue = List.generate(daysDiff, (i) => 0.0);
    final labels = List.generate(daysDiff, (i) {
      final date = start.add(Duration(days: i));
      return '${date.day}/${date.month}';
    });

    for (final transaction in report.transactions) {
      final txDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      final startDate = DateTime(start.year, start.month, start.day);
      final dayIndex = txDate.difference(startDate).inDays;
      if (dayIndex >= 0 && dayIndex < daysDiff) {
        dailyRevenue[dayIndex] += _getTransactionRevenue(transaction);
      }
    }

    return List.generate(daysDiff, (i) {
      return {'label': labels[i], 'value': dailyRevenue[i]};
    });
  }

  List<Map<String, dynamic>> _getHourlyData() {
    final hourlyRevenue = List.generate(24, (i) => 0.0);
    final today = IndonesiaTime.now();

    for (final transaction in report.transactions) {
      if (transaction.date.year == today.year &&
          transaction.date.month == today.month &&
          transaction.date.day == today.day) {
        final hour = transaction.date.hour;
        hourlyRevenue[hour] += _getTransactionRevenue(transaction);
      }
    }

    return List.generate(24, (i) {
      return {
        'label': '${i.toString().padLeft(2, '0')}:00',
        'value': hourlyRevenue[i],
      };
    });
  }

  List<Map<String, dynamic>> _getWeeklyData() {
    final now = IndonesiaTime.now();
    final weekday = now.weekday;

    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));

    final weeklyRevenue = List.generate(7, (i) => 0.0);
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    for (final transaction in report.transactions) {
      final txDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      final daysDiff = txDate.difference(startOfWeek).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        weeklyRevenue[daysDiff] += _getTransactionRevenue(transaction);
      }
    }

    return List.generate(7, (i) {
      return {'label': dayLabels[i], 'value': weeklyRevenue[i]};
    });
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final now = IndonesiaTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final dailyRevenue = List.generate(daysInMonth, (i) => 0.0);

    for (final transaction in report.transactions) {
      if (transaction.date.year == now.year &&
          transaction.date.month == now.month) {
        final day = transaction.date.day - 1;
        dailyRevenue[day] += _getTransactionRevenue(transaction);
      }
    }

    return List.generate(daysInMonth, (i) {
      return {'label': '${i + 1}', 'value': dailyRevenue[i]};
    });
  }

  String _getChartTitle() {
    switch (tab) {
      case ReportTab.today:
        return 'Grafik Pendapatan (Per Jam)';
      case ReportTab.week:
        return 'Grafik Pendapatan (Per Hari)';
      case ReportTab.month:
        return 'Grafik Pendapatan (Per Tanggal)';
      case ReportTab.custom:
        return 'Grafik Pendapatan (Custom)';
    }
  }

  int? _getCurrentIndex() {
    final now = IndonesiaTime.now();

    switch (tab) {
      case ReportTab.today:
        return now.hour;
      case ReportTab.week:
        return now.weekday - 1;
      case ReportTab.month:
        return now.day - 1;
      case ReportTab.custom:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _generateChartData();
    final isLandscape = ResponsiveHelper.isTabletLandscape(context);
    final padding = isLandscape ? 16.0 : 20.0;
    final titleSize = isLandscape ? 16.0 : 18.0;
    final chartHeight = isLandscape ? 200.0 : 280.0;

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
            _getChartTitle(),
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          SizedBox(height: isLandscape ? 16 : 24),
          SizedBox(
            height: chartHeight,
            child: chartData.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildScrollableBarChart(chartData),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableBarChart(List<Map<String, dynamic>> chartData) {
    final double minBarWidth;
    final double minChartWidth;

    if (tab == ReportTab.today) {
      minBarWidth = 20.0;
      minChartWidth = chartData.length * 35.0;
    } else if (tab == ReportTab.month) {
      minBarWidth = 16.0;
      minChartWidth = chartData.length * 28.0;
    } else {
      minBarWidth = 24.0;
      minChartWidth = chartData.length * 60.0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final needsScroll = minChartWidth > constraints.maxWidth;

        if (!needsScroll) {
          return Container(
            width: constraints.maxWidth,
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: _buildBarChart(chartData, minBarWidth),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(3),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: minChartWidth,
                    padding: const EdgeInsets.only(
                      right: 16,
                      top: 8,
                      bottom: 12,
                    ),
                    child: _buildBarChart(chartData, minBarWidth),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> chartData, double barWidth) {
    double maxY = 0;
    for (var data in chartData) {
      final value = (data['value'] as num).toDouble();
      if (value > maxY) maxY = value;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipColor: (group) => const Color(0xFF2D2D2D),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = chartData[group.x.toInt()];
              final actualValue = (data['value'] as num).toDouble();
              return BarTooltipItem(
                '${data['label']}\n${FinancialReport.formatCurrency(actualValue)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const Text('');
                }
                final label = chartData[index]['label'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: tab == ReportTab.today ? 9 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((entry) {
          final currentIndex = _getCurrentIndex();
          final isCurrentBar =
              currentIndex != null && entry.key == currentIndex;

          final value = (entry.value['value'] as num).toDouble();
          final displayValue = value == 0 ? maxY * 0.02 : value;
          final isEmpty = value == 0;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: displayValue,
                gradient: LinearGradient(
                  colors: isEmpty
                      ? [Colors.grey.shade300, Colors.grey.shade200]
                      : isCurrentBar
                      ? [const Color(0xFFFF9800), const Color(0xFFFFB74D)]
                      : [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
