import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/features/financial_report/data/repositories/financial_report_repository.dart';
import 'package:sagawa_pos_new/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';

/// State untuk Financial Report
class FinancialReportState {
  final bool isLoading;
  final String? errorMessage;
  final FinancialReport? report;
  final ReportPeriod selectedPeriod;
  final List<DailyRevenue> chartData;
  final TableFilter tableFilter;
  final List<TransactionRecord> filteredTransactions;
  final int currentPage;
  final int itemsPerPage;
  final String? currentOutletId; // ID outlet yang sedang login
  final String? outletName; // Nama outlet untuk display

  const FinancialReportState({
    this.isLoading = false,
    this.errorMessage,
    this.report,
    this.selectedPeriod = ReportPeriod.daily,
    this.chartData = const [],
    this.tableFilter = TableFilter.daily,
    this.filteredTransactions = const [],
    this.currentPage = 0,
    this.itemsPerPage = 10,
    this.currentOutletId,
    this.outletName,
  });

  /// Get total pages
  int get totalPages {
    if (filteredTransactions.isEmpty) return 1;
    return (filteredTransactions.length / itemsPerPage).ceil();
  }

  /// Get paginated transactions for current page
  List<TransactionRecord> get paginatedTransactions {
    if (filteredTransactions.isEmpty) return [];
    final start = currentPage * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, filteredTransactions.length);
    return filteredTransactions.sublist(start, end);
  }

  FinancialReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    FinancialReport? report,
    ReportPeriod? selectedPeriod,
    List<DailyRevenue>? chartData,
    TableFilter? tableFilter,
    List<TransactionRecord>? filteredTransactions,
    int? currentPage,
    int? itemsPerPage,
    String? currentOutletId,
    String? outletName,
  }) {
    return FinancialReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      report: report ?? this.report,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      chartData: chartData ?? this.chartData,
      tableFilter: tableFilter ?? this.tableFilter,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      currentOutletId: currentOutletId ?? this.currentOutletId,
      outletName: outletName ?? this.outletName,
    );
  }
}

/// Cubit untuk mengelola state Financial Report
class FinancialReportCubit extends Cubit<FinancialReportState> {
  final FinancialReportRepository _repository;

  FinancialReportCubit(this._repository) : super(const FinancialReportState());

  /// Load laporan keuangan (filtered by outlet ID)
  Future<void> loadReport() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Get current user/outlet info
      final user = await UserService.getUser();

      if (user == null || user.id.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final report = await _repository.generateReport();
      final chartData = await _repository.getRevenueByPeriod(
        state.selectedPeriod,
      );
      final filteredTransactions = await _repository.getTransactionsByFilter(
        state.tableFilter,
      );

      emit(
        state.copyWith(
          isLoading: false,
          report: report,
          chartData: chartData,
          filteredTransactions: filteredTransactions,
          currentPage: 0,
          currentOutletId: user.id,
          outletName: user.outlet,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat laporan: ${e.toString()}',
        ),
      );
    }
  }

  /// Ubah periode chart
  Future<void> changePeriod(ReportPeriod period) async {
    if (period == state.selectedPeriod) return;

    emit(state.copyWith(isLoading: true, selectedPeriod: period));

    try {
      final chartData = await _repository.getRevenueByPeriod(period);
      emit(state.copyWith(isLoading: false, chartData: chartData));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat data: ${e.toString()}',
        ),
      );
    }
  }

  /// Ubah filter tabel
  Future<void> changeTableFilter(TableFilter filter) async {
    if (filter == state.tableFilter) return;

    emit(state.copyWith(isLoading: true, tableFilter: filter));

    try {
      final filteredTransactions = await _repository.getTransactionsByFilter(
        filter,
      );
      emit(
        state.copyWith(
          isLoading: false,
          filteredTransactions: filteredTransactions,
          currentPage: 0,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat data: ${e.toString()}',
        ),
      );
    }
  }

  /// Go to next page
  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  /// Go to previous page
  void previousPage() {
    if (state.currentPage > 0) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  /// Go to specific page
  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      emit(state.copyWith(currentPage: page));
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadReport();
  }
}
