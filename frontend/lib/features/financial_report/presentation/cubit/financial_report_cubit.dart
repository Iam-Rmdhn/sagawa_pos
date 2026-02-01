import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos/features/financial_report/data/repositories/financial_report_repository.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';
import 'package:sagawa_pos/data/services/user_service.dart';

/// Enum to track which tab is currently active
enum ActiveReportTab { today, week, month, custom }

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
  final String? currentOutletId;
  final String? outletName;
  final ActiveReportTab activeTab;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

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
    this.activeTab = ActiveReportTab.today,
    this.customStartDate,
    this.customEndDate,
  });

  int get totalPages {
    if (filteredTransactions.isEmpty) return 1;
    return (filteredTransactions.length / itemsPerPage).ceil();
  }

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
    ActiveReportTab? activeTab,
    DateTime? customStartDate,
    DateTime? customEndDate,
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
      activeTab: activeTab ?? this.activeTab,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

class FinancialReportCubit extends Cubit<FinancialReportState> {
  final FinancialReportRepository _repository;

  FinancialReportCubit(this._repository) : super(const FinancialReportState());

  void _safeEmit(FinancialReportState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  /// Load report for TODAY only - default when opening the page
  Future<void> loadReport() async {
    _safeEmit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await UserService.getUser();

      if (isClosed) return;

      if (user == null || user.id.isEmpty) {
        _safeEmit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      // Load today's report only - optimized for initial page load
      final report = await _repository.generateReport();
      if (isClosed) return;

      _safeEmit(
        state.copyWith(
          isLoading: false,
          report: report,
          chartData: report.dailyRevenueList,
          filteredTransactions: report.transactions,
          currentPage: 0,
          currentOutletId: user.id,
          outletName: user.outlet,
          tableFilter: TableFilter.daily,
          activeTab: ActiveReportTab.today,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat laporan: ${e.toString()}',
        ),
      );
    }
  }

  /// Load report for THIS WEEK
  Future<void> loadReportForWeek() async {
    _safeEmit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await UserService.getUser();
      if (isClosed) return;

      if (user == null || user.id.isEmpty) {
        _safeEmit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final report = await _repository.generateReportForWeek();
      if (isClosed) return;

      _safeEmit(
        state.copyWith(
          isLoading: false,
          report: report,
          chartData: report.dailyRevenueList,
          filteredTransactions: report.transactions,
          currentPage: 0,
          currentOutletId: user.id,
          outletName: user.outlet,
          activeTab: ActiveReportTab.week,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat laporan: ${e.toString()}',
        ),
      );
    }
  }

  /// Load report for THIS MONTH
  Future<void> loadReportForMonth() async {
    _safeEmit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await UserService.getUser();
      if (isClosed) return;

      if (user == null || user.id.isEmpty) {
        _safeEmit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final report = await _repository.generateReportForMonth();
      if (isClosed) return;

      _safeEmit(
        state.copyWith(
          isLoading: false,
          report: report,
          chartData: report.dailyRevenueList,
          filteredTransactions: report.transactions,
          currentPage: 0,
          currentOutletId: user.id,
          outletName: user.outlet,
          activeTab: ActiveReportTab.month,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat laporan: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> changePeriod(ReportPeriod period) async {
    if (period == state.selectedPeriod) return;

    _safeEmit(state.copyWith(isLoading: true, selectedPeriod: period));

    try {
      final chartData = await _repository.getRevenueByPeriod(period);
      if (isClosed) return;
      _safeEmit(state.copyWith(isLoading: false, chartData: chartData));
    } catch (e) {
      _safeEmit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> changeTableFilter(TableFilter filter) async {
    if (filter == state.tableFilter) return;

    _safeEmit(state.copyWith(isLoading: true, tableFilter: filter));

    try {
      final filteredTransactions = await _repository.getTransactionsByFilter(
        filter,
      );
      if (isClosed) return;
      _safeEmit(
        state.copyWith(
          isLoading: false,
          filteredTransactions: filteredTransactions,
          currentPage: 0,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat data: ${e.toString()}',
        ),
      );
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      _safeEmit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void previousPage() {
    if (state.currentPage > 0) {
      _safeEmit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      _safeEmit(state.copyWith(currentPage: page));
    }
  }

  Future<void> refresh() async {
    // Refresh based on current active tab
    switch (state.activeTab) {
      case ActiveReportTab.today:
        await loadReport();
        break;
      case ActiveReportTab.week:
        await loadReportForWeek();
        break;
      case ActiveReportTab.month:
        await loadReportForMonth();
        break;
      case ActiveReportTab.custom:
        if (state.customStartDate != null && state.customEndDate != null) {
          await loadReportByDateRange(
            state.customStartDate!,
            state.customEndDate!,
          );
        } else {
          await loadReport();
        }
        break;
    }
  }

  Future<void> loadReportByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _safeEmit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await UserService.getUser();
      if (isClosed) return;

      if (user == null || user.id.isEmpty) {
        _safeEmit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final report = await _repository.generateReportByDateRange(
        startDate,
        endDate,
      );
      if (isClosed) return;

      _safeEmit(
        state.copyWith(
          isLoading: false,
          report: report,
          filteredTransactions: report.transactions,
          currentPage: 0,
          currentOutletId: user.id,
          outletName: user.outlet,
          activeTab: ActiveReportTab.custom,
          customStartDate: startDate,
          customEndDate: endDate,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat laporan: ${e.toString()}',
        ),
      );
    }
  }
}
