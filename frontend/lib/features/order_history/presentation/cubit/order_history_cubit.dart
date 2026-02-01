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
      final startDate = DateTime(now.year, now.month - 1, now.day);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startDate,
        endDate,
      );

      final groupedOrders = GroupedOrderByDate.groupOrders(orders);

      emit(
        state.copyWith(
          groupedOrders: groupedOrders,
          isLoading: false,
          currentOutletId: outletId,
        ),
      );
    } catch (e) {
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

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startOfDay,
        endOfDay,
      );

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

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startDate,
        endDate,
      );

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
