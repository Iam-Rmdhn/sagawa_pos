import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos_new/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  @override
  void initState() {
    super.initState();
    context.read<FinancialReportCubit>().loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: const Color(0xFFFF4B4B),
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Laporan Keuangan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                context.read<FinancialReportCubit>().refresh();
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<FinancialReportCubit, FinancialReportState>(
        builder: (context, state) {
          if (state.isLoading && state.report == null) {
            return const _FinancialReportSkeleton();
          }

          if (state.errorMessage != null && state.report == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FinancialReportCubit>().loadReport();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B4B),
                    ),
                    child: const Text(
                      'Coba Lagi',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final report = state.report;
          if (report == null) {
            return const Center(child: Text('Tidak ada data'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<FinancialReportCubit>().refresh();
            },
            color: const Color(0xFFFF4B4B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Summary Cards
                  _RevenueCardsSection(report: report),
                  const SizedBox(height: 24),

                  // Line Chart - Pendapatan
                  _RevenueChartSection(
                    chartData: state.chartData,
                    selectedPeriod: state.selectedPeriod,
                    onPeriodChanged: (period) {
                      context.read<FinancialReportCubit>().changePeriod(period);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Pie Chart - Order Type
                  _OrderTypeChartSection(report: report),
                  const SizedBox(height: 24),

                  // Transaction Table
                  _TransactionTableSection(
                    transactions: state.paginatedTransactions,
                    allTransactions: state.filteredTransactions,
                    tableFilter: state.tableFilter,
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    onFilterChanged: (filter) {
                      context.read<FinancialReportCubit>().changeTableFilter(
                        filter,
                      );
                    },
                    onNextPage: () {
                      context.read<FinancialReportCubit>().nextPage();
                    },
                    onPreviousPage: () {
                      context.read<FinancialReportCubit>().previousPage();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Section untuk kartu revenue (Harian, Mingguan, Bulanan)
class _RevenueCardsSection extends StatelessWidget {
  final FinancialReport report;

  const _RevenueCardsSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Pendapatan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RevenueCard(
                title: 'Hari Ini',
                amount: report.dailyRevenue,
                color: const Color(0xFFFF4B4B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RevenueCard(
                title: 'Minggu Ini',
                amount: report.weeklyRevenue,
                color: const Color(0xFFFFB000),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RevenueCard(
          title: 'Bulan Ini',
          amount: report.monthlyRevenue,
          color: const Color(0xFF4CAF50),
          isLarge: true,
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final bool isLarge;

  const _RevenueCard({
    required this.title,
    required this.amount,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FinancialReport.formatCurrency(amount),
            style: TextStyle(
              fontSize: isLarge ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section untuk Line Chart pendapatan
class _RevenueChartSection extends StatelessWidget {
  final List<DailyRevenue> chartData;
  final ReportPeriod selectedPeriod;
  final Function(ReportPeriod) onPeriodChanged;

  const _RevenueChartSection({
    required this.chartData,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grafik Pendapatan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportPeriod>(
                    value: selectedPeriod,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                    items: ReportPeriod.values.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onPeriodChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: chartData.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // Find max value for scaling
    double maxY = 0;
    for (var data in chartData) {
      if (data.revenue > maxY) maxY = data.revenue;
    }
    // Add 20% padding to max
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100000; // Default if no data

    // Create spots for the chart
    final spots = chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.revenue);
    }).toList();

    return LineChart(
      LineChartData(
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
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 4,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  FinancialReport.formatShortCurrency(value),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const Text('');
                }

                // Show label based on period
                final data = chartData[index];
                String label;
                if (selectedPeriod == ReportPeriod.monthly) {
                  // Show month name for monthly view
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'Mei',
                    'Jun',
                    'Jul',
                    'Agu',
                    'Sep',
                    'Okt',
                    'Nov',
                    'Des',
                  ];
                  label = months[data.date.month - 1];
                } else {
                  // Show day name for daily/weekly
                  label = data.dayName;
                }

                // Only show every nth label to avoid crowding
                int showInterval = chartData.length > 10 ? 3 : 1;
                if (index % showInterval != 0 &&
                    index != chartData.length - 1) {
                  return const Text('');
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF4CAF50),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF4CAF50),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.3),
                  const Color(0xFF4CAF50).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF2D2D2D),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final data = chartData[spot.x.toInt()];
                return LineTooltipItem(
                  '${data.shortDate}\n${FinancialReport.formatCurrency(spot.y)}\n${data.orderCount} pesanan',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }
}

/// Section untuk Pie Chart tipe pesanan
class _OrderTypeChartSection extends StatelessWidget {
  final FinancialReport report;

  const _OrderTypeChartSection({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.dineInCount + report.takeAwayCount;

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          const Text(
            'Tipe Pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 20),
          total == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'Belum ada data pesanan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: report.dineInCount.toDouble(),
                                color: const Color(0xFF42A5F5),
                                radius: 50,
                                title:
                                    '${report.dineInPercentage.toStringAsFixed(1)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: report.takeAwayCount.toDouble(),
                                color: const Color(0xFF1565C0),
                                radius: 50,
                                title:
                                    '${report.takeAwayPercentage.toStringAsFixed(1)}%',
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
                    // Legend
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(
                            color: const Color(0xFF42A5F5),
                            label: 'Dine In',
                            count: report.dineInCount,
                          ),
                          const SizedBox(height: 16),
                          _LegendItem(
                            color: const Color(0xFF1565C0),
                            label: 'Take Away',
                            count: report.takeAwayCount,
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
                ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
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

/// Section untuk tabel transaksi dengan pagination
class _TransactionTableSection extends StatelessWidget {
  final List<TransactionRecord> transactions;
  final List<TransactionRecord> allTransactions;
  final TableFilter tableFilter;
  final int currentPage;
  final int totalPages;
  final Function(TableFilter) onFilterChanged;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  const _TransactionTableSection({
    required this.transactions,
    required this.allTransactions,
    required this.tableFilter,
    required this.currentPage,
    required this.totalPages,
    required this.onFilterChanged,
    required this.onNextPage,
    required this.onPreviousPage,
  });

  Future<void> _exportToCsv(BuildContext context) async {
    try {
      if (allTransactions.isEmpty) {
        CustomSnackbar.show(
          context,
          message: 'Tidak ada data untuk diexport',
          type: SnackbarType.warning,
        );
        return;
      }

      // Generate CSV content
      final buffer = StringBuffer();

      // Add headers
      buffer.writeln(TransactionRecord.csvHeaders.join(','));

      // Add data rows
      for (final transaction in allTransactions) {
        final row = transaction
            .toCsvRow()
            .map((cell) {
              // Escape commas and quotes in cell values
              if (cell.contains(',') || cell.contains('"')) {
                return '"${cell.replaceAll('"', '""')}"';
              }
              return cell;
            })
            .join(',');
        buffer.writeln(row);
      }

      // Get directory and save file
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'laporan_${tableFilter.label.toLowerCase()}_${now.day}${now.month}${now.year}_${now.hour}${now.minute}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Keuangan ${tableFilter.label}');

      if (!context.mounted) return;
      CustomSnackbar.show(
        context,
        message: 'File CSV berhasil dibuat',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal export CSV: $e',
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekap Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                Row(
                  children: [
                    // Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TableFilter>(
                          value: tableFilter,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                          ),
                          items: TableFilter.values.map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              onFilterChanged(value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Export Button
                    Material(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _exportToCsv(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'CSV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8F9FA),
                ),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 64,
                columnSpacing: 16,
                horizontalMargin: 20,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1F1F),
                ),
                dataTextStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                columns: const [
                  DataColumn(label: Text('Trx ID')),
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Tipe')),
                  DataColumn(label: Text('Menu')),
                  DataColumn(label: Text('Qty'), numeric: true),
                  DataColumn(label: Text('Tax'), numeric: true),
                  DataColumn(label: Text('Subtotal'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                ],
                rows: transactions.map((tx) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          tx.trxId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      DataCell(Text(tx.shortFormattedDate)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tx.type.toLowerCase().contains('dine')
                                ? const Color(0xFF42A5F5).withOpacity(0.1)
                                : const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tx.type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tx.type.toLowerCase().contains('dine')
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            tx.menuItems,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(Text('${tx.qty}')),
                      DataCell(
                        Text(FinancialReport.formatShortCurrency(tx.tax)),
                      ),
                      DataCell(
                        Text(FinancialReport.formatShortCurrency(tx.subtotal)),
                      ),
                      DataCell(
                        Text(
                          FinancialReport.formatShortCurrency(tx.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

          // Pagination
          if (transactions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${allTransactions.length} transaksi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      // Previous Button
                      Material(
                        color: currentPage > 0
                            ? const Color(0xFFFF4B4B)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: currentPage > 0 ? onPreviousPage : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: currentPage > 0
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Page indicator
                      Text(
                        '${currentPage + 1} / $totalPages',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next Button
                      Material(
                        color: currentPage < totalPages - 1
                            ? const Color(0xFFFF4B4B)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: currentPage < totalPages - 1
                              ? onNextPage
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: currentPage < totalPages - 1
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton loading untuk financial report dengan efek shimmer
class _FinancialReportSkeleton extends StatelessWidget {
  const _FinancialReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(
              width: 180,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Revenue Cards
            Row(
              children: [
                Expanded(child: _buildRevenueCardSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildRevenueCardSkeleton()),
              ],
            ),
            const SizedBox(height: 12),
            _buildRevenueCardSkeleton(isLarge: true),
            const SizedBox(height: 24),

            // Chart Section
            _buildChartSkeleton(),
            const SizedBox(height: 24),

            // Pie Chart Section
            _buildPieChartSkeleton(),
            const SizedBox(height: 24),

            // Table Section
            _buildTableSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCardSkeleton({bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: isLarge ? 14 : 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: isLarge ? 22 : 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 140,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart placeholder
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final heights = [
                        60.0,
                        100.0,
                        80.0,
                        140.0,
                        120.0,
                        90.0,
                        110.0,
                      ];
                      return Container(
                        width: 12,
                        height: heights[index],
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie chart placeholder
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 180,
                  child: Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItemSkeleton(),
                    const SizedBox(height: 16),
                    _buildLegendItemSkeleton(),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItemSkeleton() {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 13,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 70,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 130,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Table header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(4, (index) {
                final widths = [60.0, 60.0, 40.0, 80.0];
                return Expanded(
                  child: Container(
                    width: widths[index],
                    height: 12,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Table rows
          ...List.generate(5, (index) => _buildTableRowSkeleton()),
          // Pagination
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final widths = [80.0, 70.0, 50.0, 60.0];
          return Expanded(
            child: Container(
              width: widths[index],
              height: index == 2 ? 20 : 12,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(index == 2 ? 10 : 4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
