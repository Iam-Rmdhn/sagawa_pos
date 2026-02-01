import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/core/utils/responsive_helper.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/features/financial_report/presentation/pages/financial_report_page.dart';

class TransactionTableSection extends StatefulWidget {
  final FinancialReport report;
  final ReportTab tab;
  final DateTimeRange? customDateRange;

  const TransactionTableSection({
    super.key,
    required this.report,
    required this.tab,
    this.customDateRange,
  });

  @override
  State<TransactionTableSection> createState() =>
      _TransactionTableSectionState();
}

class _TransactionTableSectionState extends State<TransactionTableSection> {
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  FinancialReport get report => widget.report;
  ReportTab get tab => widget.tab;
  DateTimeRange? get customDateRange => widget.customDateRange;

  @override
  void didUpdateWidget(covariant TransactionTableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  double _getTransactionTotal(TransactionRecord tx) {
    if (_isFreeTransaction(tx)) return 0.0;

    return tx.calculatedTotal;
  }

  double _getTransactionTax(TransactionRecord tx) {
    if (_isFreeTransaction(tx)) return 0.0;

    return tx.calculatedTax;
  }

  double _getTransactionSubtotalAfterDiscount(TransactionRecord tx) {
    if (_isFreeTransaction(tx)) return 0.0;

    return tx.subtotalSetelahPotongan;
  }

  List<TransactionRecord> _getFilteredTransactions() {
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
          ).add(const Duration(days: 1));
          return !txDate.isBefore(start) && txDate.isBefore(end);
      }
    }).toList();

    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  String _getPaymentMethodLabel(String paymentMethod) {
    final method = paymentMethod.toLowerCase();
    if (method.contains('discount') && method.contains('qris')) {
      return 'Discount+QRIS';
    } else if (method.contains('discount') && method.contains('cash')) {
      return 'Discount+Cash';
    } else if (method.contains('discount')) {
      return 'Discount 100%';
    } else if (method.contains('voucher') && method.contains('qris')) {
      return 'Voucher+QRIS';
    } else if (method.contains('voucher') && method.contains('cash')) {
      return 'Voucher+Cash';
    } else if (method.contains('voucher')) {
      return 'Voucher';
    } else if (method.contains('qris')) {
      return 'QRIS';
    }
    return 'Cash';
  }

  Color _getPaymentMethodColor(String paymentMethod) {
    final method = paymentMethod.toLowerCase();
    if (method.contains('discount')) {
      return const Color(0xFFFF5722);
    } else if (method.contains('voucher')) {
      return const Color(0xFFE91E63);
    } else if (method.contains('qris')) {
      return const Color(0xFF7C4DFF);
    }
    return const Color(0xFF66BB6A);
  }

  @override
  Widget build(BuildContext context) {
    final isTabletLandscape = ResponsiveHelper.isTabletLandscape(context);
    final screenWidth = MediaQuery.of(context).size.width;

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
            _buildResponsiveTable(context, screenWidth, transactions)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(context, isTabletLandscape, transactions),
            ),
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
                      Text(
                        '${_currentPage + 1} / $totalPages',
                        style: TextStyle(
                          fontSize: isTabletLandscape ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: isTabletLandscape ? 10 : 12),
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

  Widget _buildResponsiveTable(
    BuildContext context,
    double screenWidth,
    List<TransactionRecord> transactions,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _buildHeaderCell('Trx ID', flex: 2),
                  _buildHeaderCell('Tanggal', flex: 2),
                  _buildHeaderCell('Tipe', flex: 1),
                  _buildHeaderCell('Payment', flex: 2),
                  _buildHeaderCell('Menu', flex: 3),
                  _buildHeaderCell('Qty', flex: 1, isNumeric: true),
                  _buildHeaderCell('Tax', flex: 1, isNumeric: true),
                  _buildHeaderCell('Subtotal', flex: 2, isNumeric: true),
                  _buildHeaderCell('Total', flex: 2, isNumeric: true),
                ],
              ),
            ),
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
          Expanded(
            flex: 2,
            child: Text(
              tx.trxId,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tx.shortFormattedDate,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: tx.type.toLowerCase().contains('dine')
                    ? const Color(0xFF42A5F5).withOpacity(0.1)
                    : const Color(0xFF66BB6A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tx.type.toLowerCase().contains('dine') ? 'DI' : 'TA',
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
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor(
                  tx.paymentMethod,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getPaymentMethodLabel(tx.paymentMethod),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _getPaymentMethodColor(tx.paymentMethod),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tx.menuItems,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${tx.qty}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              FinancialReport.formatNumberOnly(_getTransactionTax(tx)),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              FinancialReport.formatNumberOnly(
                _getTransactionSubtotalAfterDiscount(tx),
              ),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              FinancialReport.formatNumberOnly(_getTransactionTotal(tx)),
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
        DataColumn(label: Text('Payment')),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentMethodColor(
                    tx.paymentMethod,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPaymentMethodLabel(tx.paymentMethod),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getPaymentMethodColor(tx.paymentMethod),
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
              Text(FinancialReport.formatNumberOnly(_getTransactionTax(tx))),
            ),
            DataCell(
              Text(
                FinancialReport.formatNumberOnly(
                  _getTransactionSubtotalAfterDiscount(tx),
                ),
              ),
            ),
            DataCell(
              Text(
                FinancialReport.formatNumberOnly(_getTransactionTotal(tx)),
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
