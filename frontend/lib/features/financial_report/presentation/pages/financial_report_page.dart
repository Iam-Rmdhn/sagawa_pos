import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/features/financial_report/presentation/cubit/financial_report_cubit.dart';
import 'package:sagawa_pos/features/financial_report/presentation/widgets/widgets.dart';

enum ReportTab { today, week, month, custom }

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
      if (mounted) {
        context.read<FinancialReportCubit>().loadReportByDateRange(
          picked.start,
          picked.end,
        );
      }
    }
  }

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
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTabLabelForExport(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildExportButton(
                            iconPath: AppImages.pdfIcon,
                            label: 'PDF',
                            color: const Color(0xFFE53935),
                            onTap: () {
                              Navigator.pop(context);
                              _exportToPdf(report);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExportButton(
                            iconPath: AppImages.csvIcon,
                            label: 'CSV',
                            color: const Color(0xFF43A047),
                            onTap: () {
                              Navigator.pop(context);
                              _exportToCsv(report);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CSV mendukung semua transaksi tanpa batasan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String iconPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
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

    bool isInRange(DateTime txDate) {
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
          return !date.isBefore(start) && date.isBefore(end);
      }
    }

    bool isFreeTransaction(TransactionRecord tx) {
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

      if (tx.isVoucherPayment && tx.totalPotongan >= tx.subtotal) {
        return true;
      }

      return false;
    }

    double totalPendapatan = 0;
    double totalPenjualan = 0;
    int transactionCount = 0;
    double cashRevenue = 0;
    double qrisRevenue = 0;
    double totalTax = 0;
    double totalVoucherAmount = 0;
    int voucherCount = 0;

    for (final tx in report.transactions) {
      if (!isInRange(tx.date)) continue;

      transactionCount++;
      final paymentMethod = tx.paymentMethod.toLowerCase();

      if (tx.isVoucherPayment) {
        totalVoucherAmount += tx.totalPotongan;
        voucherCount++;
      }

      if (isFreeTransaction(tx)) {
        continue;
      }

      totalPendapatan += tx.calculatedTotal;
      totalPenjualan += tx.subtotalSetelahPotongan;
      totalTax += tx.calculatedTax;

      if (paymentMethod.contains('qris')) {
        qrisRevenue += tx.subtotalSetelahPotongan;
      } else {
        cashRevenue += tx.subtotalSetelahPotongan;
      }
    }

    final average = transactionCount > 0
        ? totalPenjualan / transactionCount
        : 0.0;

    return {
      'totalPendapatan': totalPendapatan,
      'totalPenjualan': totalPenjualan,
      'transactionCount': transactionCount,
      'average': average,
      'period': _getTabLabelForExport(),
      'cashRevenue': cashRevenue,
      'qrisRevenue': qrisRevenue,
      'totalVoucherAmount': totalVoucherAmount,
      'voucherCount': voucherCount,
      'totalTax': totalTax,
    };
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
            pw.Text(
              'RINGKASAN',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPdfSummaryTable(data),
            pw.SizedBox(height: 30),
            pw.Text(
              'BREAKDOWN METODE PEMBAYARAN',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildPdfPaymentBreakdownTable(data),
            pw.SizedBox(height: 8),
            pw.Text(
              'Catatan: Pendapatan Cash dan QRIS tidak termasuk PB1',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'DETAIL TRANSAKSI',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (filteredTransactions.isEmpty)
              _buildPdfEmptyTransactions()
            else
              _buildPdfTransactionTable(filteredTransactions),
          ],
        ),
      );

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

      // Handle specific errors with user-friendly messages
      String errorMessage;
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('too many') ||
          errorString.contains('page') ||
          errorString.contains('memory') ||
          errorString.contains('overflow')) {
        errorMessage =
            'Data terlalu banyak untuk PDF. Gunakan export CSV untuk data besar.';
      } else if (errorString.contains('storage') ||
          errorString.contains('space') ||
          errorString.contains('disk')) {
        errorMessage =
            'Penyimpanan tidak cukup. Hapus beberapa file dan coba lagi.';
      } else if (errorString.contains('permission')) {
        errorMessage = 'Tidak ada izin untuk menyimpan file.';
      } else {
        errorMessage = 'Gagal membuat PDF. Coba gunakan export CSV.';
      }

      _showExportErrorDialog(errorMessage);
    }
  }

  void _showExportErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 32,
          ),
        ),
        title: const Text(
          'Export PDF Gagal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tips: Export CSV mendukung semua transaksi tanpa batasan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final cubit = context.read<FinancialReportCubit>();
              if (cubit.state.report != null) {
                _exportToCsv(cubit.state.report!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Export CSV',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv(FinancialReport report) async {
    try {
      final data = _getExportData(report);
      final now = IndonesiaTime.now();
      final filteredTransactions = _getFilteredTransactionsForExport(report);

      // Helper function to check free transactions
      bool isFreeTransaction(TransactionRecord tx) {
        final paymentMethod = tx.paymentMethod.toLowerCase();
        if (paymentMethod.contains('discount')) {
          if (paymentMethod.contains('100%') ||
              paymentMethod.contains('100 %')) {
            if (!paymentMethod.contains('cash') &&
                !paymentMethod.contains('qris')) {
              return true;
            }
          }
          if (tx.subtotal <= 0) return true;
        }
        if (paymentMethod == 'voucher') return true;
        if (tx.isVoucherPayment && tx.totalPotongan >= tx.subtotal) return true;
        return false;
      }

      double getTransactionTotal(TransactionRecord tx) {
        if (isFreeTransaction(tx)) return 0.0;
        return tx.calculatedTotal;
      }

      // Build CSV data
      final List<List<dynamic>> csvData = [];

      // Header section - Summary
      csvData.add(['LAPORAN PENJUALAN']);
      csvData.add(['Periode', data['period']]);
      csvData.add(['Tanggal Export', '${now.day}/${now.month}/${now.year}']);
      csvData.add([]);

      // Summary section
      csvData.add(['RINGKASAN']);
      csvData.add(['Metrik', 'Nilai']);
      csvData.add(['Total Pendapatan', data['totalPendapatan']]);
      csvData.add(['Total Transaksi', data['transactionCount']]);
      csvData.add(['Rata-rata per Transaksi', data['average']]);
      csvData.add([]);

      // Payment breakdown
      csvData.add(['BREAKDOWN METODE PEMBAYARAN']);
      csvData.add(['Metode', 'Pendapatan']);
      csvData.add(['Cash', data['cashRevenue']]);
      csvData.add(['QRIS', data['qrisRevenue']]);
      csvData.add(['Voucher (jumlah)', data['voucherCount']]);
      csvData.add(['Total Voucher', data['totalVoucherAmount']]);
      csvData.add(['PB1 (10%)', data['totalTax']]);
      csvData.add([]);

      // Transaction details header
      csvData.add(['DETAIL TRANSAKSI']);
      csvData.add([
        'No',
        'Trx ID',
        'Tanggal',
        'Waktu',
        'Tipe',
        'Metode Pembayaran',
        'Menu',
        'Qty',
        'Subtotal',
        'Potongan',
        'Tax',
        'Total',
      ]);

      // Transaction data - NO LIMIT for CSV
      for (int i = 0; i < filteredTransactions.length; i++) {
        final tx = filteredTransactions[i];
        final total = getTransactionTotal(tx);

        csvData.add([
          i + 1,
          tx.trxId,
          tx.shortFormattedDate,
          '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
          tx.type.contains('Dine') ? 'Dine In' : 'Take Away',
          tx.paymentMethod,
          tx.menuItems,
          tx.qty,
          tx.subtotal,
          tx.totalPotongan,
          tx.calculatedTax,
          total,
        ]);
      }

      // Convert to CSV string
      const converter = ListToCsvConverter();
      final csvString = converter.convert(csvData);

      // Add BOM for Excel UTF-8 compatibility
      final csvBytes = utf8.encode('\uFEFF$csvString');

      // Save file
      final directory = await getTemporaryDirectory();
      final fileName =
          'Laporan_${_getFileNameSuffix()}_${now.day}${now.month}${now.year}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(csvBytes);

      // Share file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Laporan Penjualan - ${data['period']}');

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message:
            'CSV berhasil dibuat (${filteredTransactions.length} transaksi)',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal export CSV: $e',
        type: SnackbarType.error,
      );
    }
  }

  pw.Widget _buildPdfSummaryTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [
            _buildPdfCell('Metrik', bold: true, color: PdfColors.white),
            _buildPdfCell('Nilai', bold: true, color: PdfColors.white),
            _buildPdfCell('Keterangan', bold: true, color: PdfColors.white),
          ],
        ),
        pw.TableRow(
          children: [
            _buildPdfCell('Total Pendapatan'),
            _buildPdfCell(
              FinancialReport.formatCurrency(data['totalPendapatan']),
            ),
            _buildPdfCell(
              'Periode: ${data['period']}. Total pendapatan keseluruhan setelah potongan voucher/discount, termasuk pajak (PB1)',
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildPdfCell('Total Transaksi'),
            _buildPdfCell('${data['transactionCount']}'),
            _buildPdfCell('${data['transactionCount']} total transaksi'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildPdfCell('Rata-rata per Transaksi'),
            _buildPdfCell(FinancialReport.formatCurrency(data['average'])),
            _buildPdfCell('Nilai rata-rata'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfPaymentBreakdownTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange800),
          children: [
            _buildPdfCell(
              'Metode Pembayaran',
              bold: true,
              color: PdfColors.white,
            ),
            _buildPdfCell('Pendapatan', bold: true, color: PdfColors.white),
            _buildPdfCell('Keterangan', bold: true, color: PdfColors.white),
          ],
        ),
        pw.TableRow(
          children: [
            _buildPdfCell('Cash'),
            _buildPdfCell(FinancialReport.formatCurrency(data['cashRevenue'])),
            _buildPdfCell(
              'Pendapatan pemesanan dengan metode cash (termasuk biaya tambahan)',
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildPdfCell('QRIS'),
            _buildPdfCell(FinancialReport.formatCurrency(data['qrisRevenue'])),
            _buildPdfCell(
              'Pendapatan pemesanan dengan metode QRIS (termasuk biaya tambahan)',
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _buildPdfCell('Voucher'),
            _buildPdfCell('${data['voucherCount']}'),
            _buildPdfCell(
              'Total penggunaan transaksi menggunakan voucher (${FinancialReport.formatCurrency(data['totalVoucherAmount'])})',
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildPdfCell('PB1'),
            _buildPdfCell(FinancialReport.formatCurrency(data['totalTax'])),
            _buildPdfCell(
              'Total pendapatan keseluruhan pajak pada setiap transaksi',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfEmptyTransactions() {
    return pw.Container(
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
    );
  }

  pw.Widget _buildPdfTransactionTable(List<TransactionRecord> transactions) {
    bool isFreeTransaction(TransactionRecord tx) {
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

      if (tx.isVoucherPayment && tx.totalPotongan >= tx.subtotal) {
        return true;
      }

      return false;
    }

    double getTransactionTotal(TransactionRecord tx) {
      if (isFreeTransaction(tx)) return 0.0;

      return tx.calculatedTotal;
    }

    // Batasi maksimal 200 transaksi per tabel untuk menghindari error "too many pages"
    const int maxTransactionsPerTable = 200;
    final limitedTransactions = transactions.length > maxTransactionsPerTable
        ? transactions.sublist(0, maxTransactionsPerTable)
        : transactions;
    final hasMoreTransactions = transactions.length > maxTransactionsPerTable;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (hasMoreTransactions)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Catatan: Menampilkan ${limitedTransactions.length} dari ${transactions.length} transaksi. '
              'Export dibatasi untuk menjaga performa.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.amber900),
            ),
          ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(25),
            1: const pw.FlexColumnWidth(1.3),
            2: const pw.FlexColumnWidth(1.3),
            3: const pw.FixedColumnWidth(35),
            4: const pw.FixedColumnWidth(55),
            5: const pw.FlexColumnWidth(1.8),
            6: const pw.FixedColumnWidth(30),
            7: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green800),
              children: [
                _buildPdfCell(
                  'No',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Trx ID',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Tanggal',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Tipe',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Payment',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Menu',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Qty',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                _buildPdfCell(
                  'Total',
                  bold: true,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ],
            ),
            ...limitedTransactions.asMap().entries.map((entry) {
              final tx = entry.value;
              final total = getTransactionTotal(tx);
              final isAlternate = entry.key % 2 == 1;

              return pw.TableRow(
                decoration: isAlternate
                    ? const pw.BoxDecoration(color: PdfColors.grey100)
                    : null,
                children: [
                  _buildPdfCell('${entry.key + 1}', fontSize: 8),
                  _buildPdfCell(tx.trxId, fontSize: 8),
                  _buildPdfCell(tx.shortFormattedDate, fontSize: 8),
                  _buildPdfCell(
                    tx.type.contains('Dine') ? 'DI' : 'TA',
                    fontSize: 8,
                  ),
                  _buildPdfCell(
                    _getPdfPaymentLabel(tx.paymentMethod),
                    fontSize: 8,
                  ),
                  _buildPdfCell(tx.menuItems, fontSize: 8, maxLines: 1),
                  _buildPdfCell('${tx.qty}', fontSize: 8),
                  _buildPdfCell(
                    FinancialReport.formatCurrency(total),
                    fontSize: 8,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfCell(
    String text, {
    bool bold = false,
    double fontSize = 12,
    PdfColor? color,
    int maxLines = 2,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : null,
          fontSize: fontSize,
          color: color,
        ),
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  List<TransactionRecord> _getFilteredTransactionsForExport(
    FinancialReport report,
  ) {
    final tab = ReportTab.values[_selectedTabIndex];
    final now = IndonesiaTime.now();

    final filtered = report.transactions.where((tx) {
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

    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
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

  String _getPdfPaymentLabel(String paymentMethod) {
    if (paymentMethod.toLowerCase().contains('discount')) {
      if (paymentMethod.contains('100%')) {
        return '100%';
      }
      final simplified = paymentMethod.replaceAll(
        RegExp(r'Discount\s*', caseSensitive: false),
        '',
      );
      return simplified.trim();
    }

    final method = paymentMethod.toLowerCase();
    if (method.contains('voucher') && method.contains('qris')) {
      return 'V+Q';
    } else if (method.contains('voucher') && method.contains('cash')) {
      return 'V+C';
    } else if (method.contains('voucher')) {
      return 'Voucher';
    } else if (method.contains('qris')) {
      return 'QRIS';
    }
    return 'Cash';
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
          // Show skeleton when loading (both initial and when switching tabs)
          if (state.isLoading) {
            return Column(
              children: [
                _buildTabSelector(isTabletLandscape),
                const Expanded(child: FinancialReportSkeleton()),
              ],
            );
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
              _buildTabSelector(isTabletLandscape),
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

  Widget _buildTabSelector(bool isTabletLandscape) {
    return Container(
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
              index: 0,
              label: 'Hari Ini',
              icon: Icons.today,
              isTablet: isTabletLandscape,
            ),
            _buildTabItem(
              index: 1,
              label: 'Minggu Ini',
              icon: Icons.date_range,
              isTablet: isTabletLandscape,
            ),
            _buildTabItem(
              index: 2,
              label: 'Bulan Ini',
              icon: Icons.calendar_month,
              isTablet: isTabletLandscape,
            ),
            _buildTabItem(
              index: 3,
              label: 'Custom',
              icon: Icons.tune,
              isTablet: isTabletLandscape,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
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
        if (_selectedTabIndex == index && index != 3) return;

        setState(() {
          _selectedTabIndex = index;
        });

        // Load data based on selected tab - each tab fetches only its own data
        final cubit = context.read<FinancialReportCubit>();
        switch (index) {
          case 0: // Hari Ini
            cubit.loadReport();
            break;
          case 1: // Minggu Ini
            cubit.loadReportForWeek();
            break;
          case 2: // Bulan Ini
            cubit.loadReportForMonth();
            break;
          case 3: // Custom
            _selectCustomDateRange();
            break;
        }
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
            SummaryCardsSection(report: report, tab: tab),
            const SizedBox(height: 24),
            if (ResponsiveHelper.isTabletLandscape(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: RevenueChartSection(tab: tab, report: report),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: OrderTypeChartSection(report: report, tab: tab),
                  ),
                ],
              )
            else ...[
              RevenueChartSection(tab: tab, report: report),
              const SizedBox(height: 24),
              OrderTypeChartSection(report: report, tab: tab),
            ],
            const SizedBox(height: 24),
            TransactionTableSection(report: report, tab: tab),
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
            _buildDateRangeSelector(),
            const SizedBox(height: 24),
            if (_customDateRange != null) ...[
              SummaryCardsSection(
                report: report,
                tab: ReportTab.custom,
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 24),
              RevenueChartSection(
                tab: ReportTab.custom,
                report: report,
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 24),
              OrderTypeChartSection(
                report: report,
                tab: ReportTab.custom,
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 24),
              TransactionTableSection(
                report: report,
                tab: ReportTab.custom,
                customDateRange: _customDateRange,
              ),
            ] else
              _buildEmptyCustomState(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
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
          const Icon(Icons.date_range, color: Color(0xFFFF4B4B), size: 24),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildEmptyCustomState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Pilih rentang tanggal untuk melihat laporan',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
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
