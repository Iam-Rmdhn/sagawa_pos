import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos/features/order_history/domain/models/grouped_order_by_date.dart';
import 'package:sagawa_pos/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos/data/services/user_service.dart';

class OrderHistoryState {
  final List<GroupedOrderByDate> groupedOrders;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? selectedDate;
  final String? filterLabel;
  final String? currentOutletId;

  const OrderHistoryState({
    this.groupedOrders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDate,
    this.filterLabel,
    this.currentOutletId,
  });

  OrderHistoryState copyWith({
    List<GroupedOrderByDate>? groupedOrders,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? filterLabel,
    String? currentOutletId,
    bool clearFilter = false,
  }) {
    return OrderHistoryState(
      groupedOrders: groupedOrders ?? this.groupedOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedDate: clearFilter ? null : (selectedDate ?? this.selectedDate),
      filterLabel: clearFilter ? null : (filterLabel ?? this.filterLabel),
      currentOutletId: currentOutletId ?? this.currentOutletId,
    );
  }
}

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryRepository _repository;

  OrderHistoryCubit(this._repository) : super(const OrderHistoryState());

  Future<String?> _getCurrentOutletId() async {
    final user = await UserService.getUser();
    return user?.id;
  }

  Future<void> loadOrders() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final outletId = await _getCurrentOutletId();

      if (outletId == null || outletId.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            groupedOrders: [],
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final now = DateTime.now();
      // Default: fetch 30 hari terakhir
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 30));
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      print('[OrderHistoryCubit] Loading orders for outlet: $outletId');
      print('[OrderHistoryCubit] Date range: $startDate to $endDate');

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startDate,
        endDate,
      );

      print('[OrderHistoryCubit] Total orders fetched: ${orders.length}');

      // Log order dates for debugging
      if (orders.isNotEmpty) {
        final datesCounts = <String, int>{};
        for (final order in orders) {
          final dateKey =
              '${order.date.year}-${order.date.month.toString().padLeft(2, '0')}-${order.date.day.toString().padLeft(2, '0')}';
          datesCounts[dateKey] = (datesCounts[dateKey] ?? 0) + 1;
        }
        print('[OrderHistoryCubit] Orders per date:');
        datesCounts.forEach((date, count) {
          print('  $date: $count orders');
        });
      }

      final groupedOrders = GroupedOrderByDate.groupOrders(orders);

      print('[OrderHistoryCubit] Grouped into ${groupedOrders.length} days');
      for (final group in groupedOrders) {
        print(
          '  ${group.formattedDate}: ${group.transactionCount} transactions',
        );
      }

      emit(
        state.copyWith(
          groupedOrders: groupedOrders,
          isLoading: false,
          currentOutletId: outletId,
        ),
      );
    } catch (e) {
      print('[OrderHistoryCubit] Error: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat riwayat: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> filterByDate(DateTime date, String label) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final outletId = state.currentOutletId ?? await _getCurrentOutletId();

      if (outletId == null || outletId.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('[OrderHistoryCubit] filterByDate: $label');
      print('[OrderHistoryCubit] Date range: $startOfDay to $endOfDay');

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startOfDay,
        endOfDay,
      );

      print('[OrderHistoryCubit] Fetched ${orders.length} orders for $label');

      final groupedOrders = GroupedOrderByDate.groupOrders(orders);

      emit(
        state.copyWith(
          groupedOrders: groupedOrders,
          isLoading: false,
          selectedDate: date,
          filterLabel: label,
          currentOutletId: outletId,
        ),
      );
    } catch (e) {
      print('[OrderHistoryCubit] filterByDate error: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal filter data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> filterByYesterday() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final outletId = state.currentOutletId ?? await _getCurrentOutletId();

      if (outletId == null || outletId.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final startOfYesterday = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      final endOfYesterday = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      );

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startOfYesterday,
        endOfYesterday,
      );

      final groupedOrders = GroupedOrderByDate.groupOrders(orders);

      emit(
        state.copyWith(
          groupedOrders: groupedOrders,
          isLoading: false,
          selectedDate: yesterday,
          filterLabel: 'Kemarin',
          currentOutletId: outletId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal filter data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> filterByDateRange(
    DateTime startDate,
    DateTime endDate,
    String label,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final outletId = state.currentOutletId ?? await _getCurrentOutletId();

      if (outletId == null || outletId.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      print('[OrderHistoryCubit] filterByDateRange: $label');
      print('[OrderHistoryCubit] Date range: $startDate to $endDate');

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startDate,
        endDate,
      );

      print('[OrderHistoryCubit] Fetched ${orders.length} orders for $label');

      final groupedOrders = GroupedOrderByDate.groupOrders(orders);

      emit(
        state.copyWith(
          groupedOrders: groupedOrders,
          isLoading: false,
          selectedDate: startDate,
          filterLabel: label,
          currentOutletId: outletId,
        ),
      );
    } catch (e) {
      print('[OrderHistoryCubit] filterByDateRange error: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal filter data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> filterByMonth(DateTime month) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final outletId = state.currentOutletId ?? await _getCurrentOutletId();

      if (outletId == null || outletId.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      final orders = await _repository.getOrdersByOutletAndMonth(
        outletId,
        month.month,
        month.year,
      );

      final groupedOrders = GroupedOrderByDate.groupOrders(orders);

      emit(
        state.copyWith(
          groupedOrders: groupedOrders,
          isLoading: false,
          selectedDate: month,
          filterLabel: 'Bulan ${_getMonthName(month.month)} ${month.year}',
          currentOutletId: outletId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal filter data: ${e.toString()}',
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  Future<void> resetFilter() async {
    emit(state.copyWith(clearFilter: true));
    await loadOrders();
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _repository.deleteOrder(orderId);
      await loadOrders();
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Gagal menghapus order: ${e.toString()}'),
      );
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _repository.clearAllOrders();
      emit(state.copyWith(groupedOrders: []));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal menghapus semua data: ${e.toString()}',
        ),
      );
    }
  }
}
