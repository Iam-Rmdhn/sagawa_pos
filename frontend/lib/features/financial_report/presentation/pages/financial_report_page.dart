import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/utils/indonesia_time.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos_new/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';

enum ReportTab { today, week, month, custom }

enum ExportType { spreadsheet, csv, pdf }

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({super.key});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    context.read<FinancialReportCubit>().loadReport();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4B4B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
      // Load data for custom date range
      if (mounted) {
        context.read<FinancialReportCubit>().loadReportByDateRange(
          picked.start,
          picked.end,
        );
      }
    }
  }

  // Export Dialog - Modern Bottom Sheet Style
  void _showExportDialog(BuildContext context, FinancialReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Export Laporan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTabLabelForExport(),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 28),
                // Export options in row
                Row(
                  children: [
                    Expanded(
                      child: _ExportOptionCard(
                        iconPath: AppImages.xlsIcon,
                        label: 'Excel',
                        color: const Color(0xFF217346),
                        onTap: () {
                          Navigator.pop(context);
                          _exportToSpreadsheet(report);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ExportOptionCard(
                        iconPath: AppImages.csvIcon,
                        label: 'CSV',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          Navigator.pop(context);
                          _exportToCsv(report);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ExportOptionCard(
                        iconPath: AppImages.pdfIcon,
                        label: 'PDF',
                        color: const Color(0xFFE53935),
                        onTap: () {
                          Navigator.pop(context);
                          _exportToPdf(report);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTabLabelForExport() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Hari Ini';
      case 1:
        return 'Minggu Ini';
      case 2:
        return 'Bulan Ini';
      case 3:
        if (_customDateRange != null) {
          return '${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}';
        }
        return 'Custom';
      default:
        return '';
    }
  }

  Map<String, dynamic> _getExportData(FinancialReport report) {
    final tab = ReportTab.values[_selectedTabIndex];
    final now = IndonesiaTime.now();
    double revenue = 0;
    int transactionCount = 0;

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
          if (_customDateRange != null) {
            final start = DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
            );
            final end = DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
            ).add(const Duration(days: 1));
            isInRange = !txDate.isBefore(start) && txDate.isBefore(end);
          }
          break;
      }

      if (isInRange) {
        revenue += tx.total;
        transactionCount++;
      }
    }

    final average = transactionCount > 0 ? revenue / transactionCount : 0.0;

    return {
      'revenue': revenue,
      'transactionCount': transactionCount,
      'average': average,
      'period': _getTabLabelForExport(),
    };
  }

  Future<void> _exportToSpreadsheet(FinancialReport report) async {
    try {
      final data = _getExportData(report);
      final now = IndonesiaTime.now();

      // Create CSV with Excel-compatible format (semicolon separator for better Excel compatibility)
      final buffer = StringBuffer();
      buffer.writeln('sep=;'); // Excel hint for separator
      buffer.writeln('LAPORAN PENJUALAN - ${data['period']}');
      buffer.writeln(
        'Tanggal Export: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
      buffer.writeln('');
      buffer.writeln('Metrik;Nilai;Keterangan');
      buffer.writeln(
        'Total Penjualan;${FinancialReport.formatCurrency(data['revenue'])};Periode: ${data['period']}',
      );
      buffer.writeln(
        'Total Transaksi;${data['transactionCount']};${data['transactionCount']} transaksi',
      );
      buffer.writeln(
        'Rata-rata per Transaksi;${FinancialReport.formatCurrency(data['average'])};Nilai rata-rata',
      );
      buffer.writeln('');
      buffer.writeln('DETAIL TRANSAKSI');
      buffer.writeln('No;Trx ID;Tanggal;Tipe;Menu;Qty;Tax;Subtotal;Total');

      final filteredTransactions = _getFilteredTransactionsForExport(report);
      int no = 1;
      for (final tx in filteredTransactions) {
        buffer.writeln(
          '$no;${tx.trxId};${tx.shortFormattedDate};${tx.type};${tx.menuItems};${tx.qty};${tx.tax};${tx.subtotal};${tx.total}',
        );
        no++;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'laporan_${_getFileNameSuffix()}_${now.day}${now.month}${now.year}.xlsx.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Penjualan - ${data['period']}');

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'File spreadsheet berhasil dibuat',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal export: $e',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _exportToCsv(FinancialReport report) async {
    try {
      final data = _getExportData(report);
      final now = IndonesiaTime.now();

      final buffer = StringBuffer();
      buffer.writeln('LAPORAN PENJUALAN - ${data['period']}');
      buffer.writeln(
        'Tanggal Export,${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
      buffer.writeln('');
      buffer.writeln('Metrik,Nilai,Keterangan');
      buffer.writeln(
        'Total Penjualan,${FinancialReport.formatCurrency(data['revenue'])},Periode: ${data['period']}',
      );
      buffer.writeln(
        'Total Transaksi,${data['transactionCount']},${data['transactionCount']} transaksi',
      );
      buffer.writeln(
        'Rata-rata per Transaksi,${FinancialReport.formatCurrency(data['average'])},Nilai rata-rata',
      );
      buffer.writeln('');
      buffer.writeln('DETAIL TRANSAKSI');
      buffer.writeln('No,Trx ID,Tanggal,Tipe,Menu,Qty,Tax,Subtotal,Total');

      final filteredTransactions = _getFilteredTransactionsForExport(report);
      int no = 1;
      for (final tx in filteredTransactions) {
        final menu = tx.menuItems.replaceAll(',', ';'); // Escape commas in menu
        buffer.writeln(
          '$no,${tx.trxId},${tx.shortFormattedDate},${tx.type},"$menu",${tx.qty},${tx.tax},${tx.subtotal},${tx.total}',
        );
        no++;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'laporan_${_getFileNameSuffix()}_${now.day}${now.month}${now.year}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Penjualan - ${data['period']}');

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'File CSV berhasil dibuat',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal export: $e',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _exportToPdf(FinancialReport report) async {
    try {
      final data = _getExportData(report);
      final now = IndonesiaTime.now();
      final filteredTransactions = _getFilteredTransactionsForExport(report);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LAPORAN PENJUALAN',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${now.day}/${now.month}/${now.year}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periode: ${data['period']}',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2, color: PdfColors.red),
              pw.SizedBox(height: 20),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Sagawa POS - Laporan Penjualan',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.Text(
                'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
          build: (context) => [
            // Summary Table
            pw.Text(
              'RINGKASAN',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Metrik',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Nilai',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Keterangan',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Data rows
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Penjualan'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        FinancialReport.formatCurrency(data['revenue']),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Periode: ${data['period']}'),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Transaksi'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${data['transactionCount']}'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${data['transactionCount']} transaksi'),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Rata-rata per Transaksi'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        FinancialReport.formatCurrency(data['average']),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Nilai rata-rata'),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            // Transaction Details
            pw.Text(
              'DETAIL TRANSAKSI',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (filteredTransactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Tidak ada transaksi pada periode ini',
                    style: const pw.TextStyle(color: PdfColors.grey),
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FixedColumnWidth(50),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FixedColumnWidth(35),
                  6: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'No',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Trx ID',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Tanggal',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Tipe',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Menu',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...filteredTransactions.asMap().entries.map((entry) {
                    final tx = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${entry.key + 1}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            tx.trxId,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            tx.shortFormattedDate,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            tx.type.contains('Dine') ? 'DI' : 'TA',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            tx.menuItems,
                            style: const pw.TextStyle(fontSize: 8),
                            maxLines: 2,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${tx.qty}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            FinancialReport.formatShortCurrency(tx.total),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      );

      // Save PDF and share
      final pdfBytes = await pdf.save();
      final directory = await getTemporaryDirectory();
      final fileName =
          'Laporan_${_getFileNameSuffix()}_${now.day}${now.month}${now.year}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Penjualan - ${data['period']}');

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'PDF berhasil dibuat',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal export PDF: $e',
        type: SnackbarType.error,
      );
    }
  }

  List<TransactionRecord> _getFilteredTransactionsForExport(
    FinancialReport report,
  ) {
    final tab = ReportTab.values[_selectedTabIndex];
    final now = IndonesiaTime.now();

    return report.transactions.where((tx) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      switch (tab) {
        case ReportTab.today:
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        case ReportTab.week:
          final weekday = now.weekday;
          final startOfWeek = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return !txDate.isBefore(startOfWeek) && txDate.isBefore(endOfWeek);
        case ReportTab.month:
          return tx.date.year == now.year && tx.date.month == now.month;
        case ReportTab.custom:
          if (_customDateRange == null) return false;
          final start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );
          final end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
          ).add(const Duration(days: 1));
          return !txDate.isBefore(start) && txDate.isBefore(end);
      }
    }).toList();
  }

  String _getFileNameSuffix() {
    switch (_selectedTabIndex) {
      case 0:
        return 'hari_ini';
      case 1:
        return 'minggu_ini';
      case 2:
        return 'bulan_ini';
      case 3:
        return 'custom';
      default:
        return 'laporan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape = ResponsiveHelper.isTabletLandscape(context);
    final borderRadius = isTabletLandscape ? 24.0 : 30.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFFFF4B4B),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Laporan Penjualan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              BlocBuilder<FinancialReportCubit, FinancialReportState>(
                builder: (context, state) {
                  return IconButton(
                    icon: const Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'Export Laporan',
                    onPressed: state.report != null
                        ? () => _showExportDialog(context, state.report!)
                        : null,
                  );
                },
              ),
            ],
          ),
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

          return Column(
            children: [
              // Custom Tab Selector (Capsule Style)
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isTabletLandscape ? 12 : 16,
                  vertical: isTabletLandscape ? 12 : 16,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabItem(
                        context,
                        index: 0,
                        label: 'Hari Ini',
                        icon: Icons.today,
                        isTablet: isTabletLandscape,
                      ),
                      _buildTabItem(
                        context,
                        index: 1,
                        label: 'Minggu Ini',
                        icon: Icons.date_range,
                        isTablet: isTabletLandscape,
                      ),
                      _buildTabItem(
                        context,
                        index: 2,
                        label: 'Bulan Ini',
                        icon: Icons.calendar_month,
                        isTablet: isTabletLandscape,
                      ),
                      _buildTabItem(
                        context,
                        index: 3,
                        label: 'Custom',
                        icon: Icons.tune,
                        isTablet: isTabletLandscape,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildTabContent(
                    context,
                    report,
                    state,
                    _selectedTabIndex,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
    required bool isTablet,
  }) {
    final isSelected = _selectedTabIndex == index;
    final fontSize = isTablet ? 11.0 : 13.0;
    final iconSize = isTablet ? 16.0 : 18.0;

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          _selectCustomDateRange();
        }
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 12,
          vertical: isTablet ? 10 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4B4B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            if (!isTablet || index == _selectedTabIndex) ...[
              SizedBox(width: isTablet ? 4 : 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    FinancialReport report,
    FinancialReportState state,
    int tabIndex,
  ) {
    final tab = ReportTab.values[tabIndex];

    return Container(
      key: ValueKey(tabIndex),
      child: tabIndex == 3
          ? _buildCustomReportContent(context, report, state)
          : _buildReportContent(context, report, state, tab),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    FinancialReport report,
    FinancialReportState state,
    ReportTab tab,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<FinancialReportCubit>().refresh();
      },
      color: const Color(0xFFFF4B4B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _SummaryCardsSection(report: report, tab: tab),
            const SizedBox(height: 24),

            // Charts
            if (ResponsiveHelper.isTabletLandscape(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _RevenueChartSection(tab: tab, report: report),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _OrderTypeChartSection(report: report, tab: tab),
                  ),
                ],
              )
            else ...[
              _RevenueChartSection(tab: tab, report: report),
              const SizedBox(height: 24),
              _OrderTypeChartSection(report: report, tab: tab),
            ],
            const SizedBox(height: 24),
            // Transaction Table
            _TransactionTableSection(report: report, tab: tab),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReportContent(
    BuildContext context,
    FinancialReport report,
    FinancialReportState state,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<FinancialReportCubit>().refresh();
      },
      color: const Color(0xFFFF4B4B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(ResponsiveHelper.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    color: Color(0xFFFF4B4B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Rentang Tanggal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customDateRange == null
                              ? 'Belum dipilih'
                              : '${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectCustomDateRange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B4B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Pilih',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_customDateRange != null) ...[
              _SummaryCardsSection(
                report: report,
                tab: ReportTab.custom,
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 24),
              _RevenueChartSection(
                tab: ReportTab.custom,
                report: report,
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 24),
              _OrderTypeChartSection(
                report: report,
                tab: ReportTab.custom,
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 24),
              _TransactionTableSection(
                report: report,
                tab: ReportTab.custom,
                customDateRange: _customDateRange,
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pilih rentang tanggal untuk melihat laporan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryCardsSection extends StatelessWidget {
  final FinancialReport report;
  final ReportTab tab;
  final DateTimeRange? customDateRange;

  const _SummaryCardsSection({
    required this.report,
    required this.tab,
    this.customDateRange,
  });

  bool _isInRange(DateTime txDate) {
    final now = IndonesiaTime.now();
    final date = DateTime(txDate.year, txDate.month, txDate.day);

    switch (tab) {
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
        if (customDateRange == null) return false;
        final start = DateTime(
          customDateRange!.start.year,
          customDateRange!.start.month,
          customDateRange!.start.day,
        );
        final end = DateTime(
          customDateRange!.end.year,
          customDateRange!.end.month,
          customDateRange!.end.day,
        ).add(const Duration(days: 1)); // Include end date
        return !date.isBefore(start) && date.isBefore(end);
    }
  }

  double _getRevenue() {
    // Calculate revenue from filtered transactions
    double total = 0;
    for (final tx in report.transactions) {
      if (_isInRange(tx.date)) {
        total += tx.total;
      }
    }
    return total;
  }

  int _getTransactionCount() {
    return report.transactions.where((tx) => _isInRange(tx.date)).length;
  }

  double _getAveragePerTransaction() {
    final count = _getTransactionCount();
    if (count == 0) return 0;
    return _getRevenue() / count;
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _getRevenue();
    final transactionCount = _getTransactionCount();
    final average = _getAveragePerTransaction();

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
                  child: _SummaryCard(
                    icon: Icons.trending_up,
                    title: 'Total Penjualan',
                    value: FinancialReport.formatCurrency(revenue),
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    icon: Icons.receipt_long,
                    title: 'Jumlah Transaksi',
                    value: '$transactionCount',
                    color: const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    icon: Icons.calculate,
                    title: 'Rata-rata / Transaksi',
                    value: FinancialReport.formatCurrency(average),
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _getTabLabel() {
    switch (tab) {
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
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section Line Chart pendapatan
class _RevenueChartSection extends StatefulWidget {
  final ReportTab tab;
  final FinancialReport report;
  final DateTimeRange? customDateRange;

  const _RevenueChartSection({
    required this.tab,
    required this.report,
    this.customDateRange,
  });

  @override
  State<_RevenueChartSection> createState() => _RevenueChartSectionState();
}

class _RevenueChartSectionState extends State<_RevenueChartSection> {
  final ScrollController _scrollController = ScrollController();

  ReportTab get tab => widget.tab;
  FinancialReport get report => widget.report;
  DateTimeRange? get customDateRange => widget.customDateRange;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _generateChartData() {
    switch (tab) {
      case ReportTab.today:
        // Hourly data (00:00 - 23:00) from transactions
        return _getHourlyData();
      case ReportTab.week:
        // Weekly data (7 days) from dailyRevenueList
        return _getWeeklyData();
      case ReportTab.month:
        // Monthly data (current month) from transactions
        return _getMonthlyData();
      case ReportTab.custom:
        // For custom, show daily data within date range
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

    // Initialize days with 0 revenue
    final dailyRevenue = List.generate(daysDiff, (i) => 0.0);
    final labels = List.generate(daysDiff, (i) {
      final date = start.add(Duration(days: i));
      return '${date.day}/${date.month}';
    });

    // Aggregate transactions by day
    for (final transaction in report.transactions) {
      final txDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      final startDate = DateTime(start.year, start.month, start.day);
      final dayIndex = txDate.difference(startDate).inDays;
      if (dayIndex >= 0 && dayIndex < daysDiff) {
        dailyRevenue[dayIndex] += transaction.total;
      }
    }

    return List.generate(daysDiff, (i) {
      return {'label': labels[i], 'value': dailyRevenue[i]};
    });
  }

  List<Map<String, dynamic>> _getHourlyData() {
    // Initialize 24 hours with 0 revenue
    final hourlyRevenue = List.generate(24, (i) => 0.0);

    final today = IndonesiaTime.now();

    // Aggregate transactions by hour for today
    for (final transaction in report.transactions) {
      if (transaction.date.year == today.year &&
          transaction.date.month == today.month &&
          transaction.date.day == today.day) {
        final hour = transaction.date.hour;
        hourlyRevenue[hour] += transaction.total;
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
    // Get current week data (Monday to Sunday)
    final now = IndonesiaTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday

    // Calculate start of week (Monday)
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));

    // Initialize 7 days (Mon-Sun) with 0 revenue
    final weeklyRevenue = List.generate(7, (i) => 0.0);
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Aggregate transactions by day of week
    for (final transaction in report.transactions) {
      final txDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      // Check if transaction is within this week
      final daysDiff = txDate.difference(startOfWeek).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        weeklyRevenue[daysDiff] += transaction.total;
      }
    }

    return List.generate(7, (i) {
      return {'label': dayLabels[i], 'value': weeklyRevenue[i]};
    });
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final now = IndonesiaTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Initialize all days with 0 revenue
    final dailyRevenue = List.generate(daysInMonth, (i) => 0.0);

    // Aggregate transactions by day for current month
    for (final transaction in report.transactions) {
      if (transaction.date.year == now.year &&
          transaction.date.month == now.month) {
        final day = transaction.date.day - 1; // 0-indexed
        dailyRevenue[day] += transaction.total;
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
        // Return current hour (0-23)
        return now.hour;
      case ReportTab.week:
        // Weekly chart shows Mon-Sun (index 0-6)
        // weekday: 1 = Monday, 7 = Sunday
        // So we return weekday - 1 to get index (0-6)
        return now.weekday - 1;
      case ReportTab.month:
        // Return current day of month (1-31) as index (0-30)
        return now.day - 1;
      case ReportTab.custom:
        // No realtime highlighting for custom
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
    // Calculate minimum width based on number of items
    // For "Hari Ini" (24 hours), we want more space per bar
    final double minBarWidth;
    final double minChartWidth;

    if (tab == ReportTab.today) {
      minBarWidth = 20.0; // Width for each bar in hourly view
      minChartWidth = chartData.length * 35.0; // Total width with spacing
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
    // Find max value for scaling
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
            fitInsideVertically: true, // Prevent tooltip from being clipped
            fitInsideHorizontally: true,
            getTooltipColor: (group) => const Color(0xFF2D2D2D),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = chartData[group.x.toInt()];
              // Show actual value (0) instead of display value for tooltip
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

                // For today (hourly), show all hours
                // For week, show all days
                // For month, show every label since we have horizontal scroll
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

          // Use a minimum height for empty bars so they're still visible
          final value = (entry.value['value'] as num).toDouble();
          final displayValue = value == 0
              ? maxY * 0.02
              : value; // 2% of maxY for empty bars
          final isEmpty = value == 0;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: displayValue,
                gradient: LinearGradient(
                  colors: isEmpty
                      ? [
                          Colors.grey.shade300,
                          Colors.grey.shade200,
                        ] // Grey for empty
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

/// Section untuk Pie Chart tipe pesanan
class _OrderTypeChartSection extends StatelessWidget {
  final FinancialReport report;
  final ReportTab tab;
  final DateTimeRange? customDateRange;

  const _OrderTypeChartSection({
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
        // Pie Chart
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
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                color: const Color(0xFF42A5F5),
                label: 'Dine In',
                count: dineInCount,
              ),
              const SizedBox(height: 16),
              _LegendItem(
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
        // Pie Chart - Compact with total below
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
        // Legend - Compact
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactLegendItem(
                color: const Color(0xFF42A5F5),
                label: 'Dine In',
                count: dineInCount,
              ),
              const SizedBox(height: 8),
              _CompactLegendItem(
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

// Compact legend untuk landscape mode
class _CompactLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _CompactLegendItem({
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

/// Section untuk tabel transaksi dengan pagination
class _TransactionTableSection extends StatefulWidget {
  final FinancialReport report;
  final ReportTab tab;
  final DateTimeRange? customDateRange;

  const _TransactionTableSection({
    required this.report,
    required this.tab,
    this.customDateRange,
  });

  @override
  State<_TransactionTableSection> createState() =>
      _TransactionTableSectionState();
}

class _TransactionTableSectionState extends State<_TransactionTableSection> {
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  FinancialReport get report => widget.report;
  ReportTab get tab => widget.tab;
  DateTimeRange? get customDateRange => widget.customDateRange;

  @override
  void didUpdateWidget(covariant _TransactionTableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset page when tab changes
    if (oldWidget.tab != widget.tab) {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  List<TransactionRecord> _getFilteredTransactions() {
    final now = IndonesiaTime.now();

    return report.transactions.where((tx) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      switch (tab) {
        case ReportTab.today:
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        case ReportTab.week:
          final weekday = now.weekday;
          final startOfWeek = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return !txDate.isBefore(startOfWeek) && txDate.isBefore(endOfWeek);
        case ReportTab.month:
          return tx.date.year == now.year && tx.date.month == now.month;
        case ReportTab.custom:
          if (customDateRange == null) return false;
          final start = DateTime(
            customDateRange!.start.year,
            customDateRange!.start.month,
            customDateRange!.start.day,
          );
          final end = DateTime(
            customDateRange!.end.year,
            customDateRange!.end.month,
            customDateRange!.end.day,
          ).add(const Duration(days: 1)); // Include end date
          return !txDate.isBefore(start) && txDate.isBefore(end);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape = ResponsiveHelper.isTabletLandscape(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Get filtered transactions based on tab
    final allTransactions = _getFilteredTransactions();
    final totalPages = allTransactions.isEmpty
        ? 1
        : (allTransactions.length / _itemsPerPage).ceil();
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, allTransactions.length);
    final transactions = allTransactions.isEmpty
        ? <TransactionRecord>[]
        : allTransactions.sublist(start, end);

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
            padding: EdgeInsets.all(isTabletLandscape ? 16 : 20),
            child: Text(
              'Rekap Transaksi',
              style: TextStyle(
                fontSize: isTabletLandscape ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),

          // Table
          if (transactions.isEmpty)
            Padding(
              padding: EdgeInsets.all(isTabletLandscape ? 30 : 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: isTabletLandscape ? 50 : 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: isTabletLandscape ? 14 : 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isTabletLandscape)
            // Tablet Landscape: Full width responsive table
            _buildResponsiveTable(context, screenWidth, transactions)
          else
            // Mobile: Horizontal scroll table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(context, isTabletLandscape, transactions),
            ),

          // Pagination
          if (transactions.isNotEmpty)
            Container(
              padding: EdgeInsets.all(isTabletLandscape ? 12 : 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${allTransactions.length} transaksi',
                    style: TextStyle(
                      fontSize: isTabletLandscape ? 11 : 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    children: [
                      // Previous Button
                      Material(
                        color: _currentPage > 0
                            ? const Color(0xFFFF4B4B)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _currentPage > 0 ? _previousPage : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(isTabletLandscape ? 6 : 8),
                            child: Icon(
                              Icons.chevron_left,
                              size: isTabletLandscape ? 18 : 20,
                              color: _currentPage > 0
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTabletLandscape ? 10 : 12),
                      // Page indicator
                      Text(
                        '${_currentPage + 1} / $totalPages',
                        style: TextStyle(
                          fontSize: isTabletLandscape ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: isTabletLandscape ? 10 : 12),
                      // Next Button
                      Material(
                        color: _currentPage < totalPages - 1
                            ? const Color(0xFFFF4B4B)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _currentPage < totalPages - 1
                              ? () => _nextPage(totalPages)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(isTabletLandscape ? 6 : 8),
                            child: Icon(
                              Icons.chevron_right,
                              size: isTabletLandscape ? 18 : 20,
                              color: _currentPage < totalPages - 1
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

  /// Build responsive table for tablet landscape
  Widget _buildResponsiveTable(
    BuildContext context,
    double screenWidth,
    List<TransactionRecord> transactions,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Table Header
            Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _buildHeaderCell('Trx ID', flex: 2),
                  _buildHeaderCell('Tanggal', flex: 2),
                  _buildHeaderCell('Tipe', flex: 1),
                  _buildHeaderCell('Menu', flex: 3),
                  _buildHeaderCell('Qty', flex: 1, isNumeric: true),
                  _buildHeaderCell('Tax', flex: 1, isNumeric: true),
                  _buildHeaderCell('Subtotal', flex: 2, isNumeric: true),
                  _buildHeaderCell('Total', flex: 2, isNumeric: true),
                ],
              ),
            ),
            // Table Body
            ...transactions.map((tx) => _buildResponsiveRow(tx)),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCell(
    String label, {
    int flex = 1,
    bool isNumeric = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F1F1F),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(TransactionRecord tx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Trx ID
          Expanded(
            flex: 2,
            child: Text(
              tx.trxId,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Tanggal
          Expanded(
            flex: 2,
            child: Text(
              tx.shortFormattedDate,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          // Tipe
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: tx.type.toLowerCase().contains('dine')
                    ? const Color(0xFF42A5F5).withOpacity(0.1)
                    : const Color(0xFF66BB6A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tx.type.toLowerCase().contains('dine')
                    ? 'Dine In'
                    : 'Take Away',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: tx.type.toLowerCase().contains('dine')
                      ? const Color(0xFF42A5F5)
                      : const Color(0xFF66BB6A),
                ),
              ),
            ),
          ),
          // Menu
          Expanded(
            flex: 3,
            child: Text(
              tx.menuItems,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          // Qty
          Expanded(
            flex: 1,
            child: Text(
              '${tx.qty}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          // Tax
          Expanded(
            flex: 1,
            child: Text(
              _formatCompactCurrency(tx.tax),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          // Subtotal
          Expanded(
            flex: 2,
            child: Text(
              _formatCompactCurrency(tx.subtotal),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          // Total
          Expanded(
            flex: 2,
            child: Text(
              _formatCompactCurrency(tx.total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }

  /// Build standard DataTable for mobile
  Widget _buildDataTable(
    BuildContext context,
    bool isCompact,
    List<TransactionRecord> transactions,
  ) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
      dataRowMinHeight: 48,
      dataRowMaxHeight: 64,
      columnSpacing: 16,
      horizontalMargin: 20,
      headingTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F1F1F),
      ),
      dataTextStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tx.type.toLowerCase().contains('dine')
                      ? const Color(0xFF42A5F5).withOpacity(0.1)
                      : const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tx.type.toLowerCase().contains('dine')
                      ? 'Dine In'
                      : 'Take Away',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tx.type.toLowerCase().contains('dine')
                        ? const Color(0xFF42A5F5)
                        : const Color(0xFF66BB6A),
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
            DataCell(Text(FinancialReport.formatShortCurrency(tx.tax))),
            DataCell(Text(FinancialReport.formatShortCurrency(tx.subtotal))),
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

// Widget untuk opsi export - Modern Card Style
class _ExportOptionCard extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
