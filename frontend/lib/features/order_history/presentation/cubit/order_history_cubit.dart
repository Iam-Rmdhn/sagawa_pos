import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/features/order_history/data/repositories/order_history_repository.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';

/// State untuk Order History
class OrderHistoryState {
  final List<OrderHistory> orders;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? selectedDate;
  final String? filterLabel;
  final String? currentOutletId; // ID outlet yang sedang login

  const OrderHistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDate,
    this.filterLabel,
    this.currentOutletId,
  });

  OrderHistoryState copyWith({
    List<OrderHistory>? orders,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? filterLabel,
    String? currentOutletId,
    bool clearFilter = false,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedDate: clearFilter ? null : (selectedDate ?? this.selectedDate),
      filterLabel: clearFilter ? null : (filterLabel ?? this.filterLabel),
      currentOutletId: currentOutletId ?? this.currentOutletId,
    );
  }
}

/// Cubit untuk mengelola Order History
class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryRepository _repository;

  OrderHistoryCubit(this._repository) : super(const OrderHistoryState());

  /// Get outlet ID dari user yang login
  Future<String?> _getCurrentOutletId() async {
    final user = await UserService.getUser();
    return user?.id; // Menggunakan user.id sebagai outlet identifier
  }

  /// Load semua order history berdasarkan outlet ID
  Future<void> loadOrders() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final outletId = await _getCurrentOutletId();

      if (outletId == null || outletId.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            orders: [],
            errorMessage: 'Silakan login terlebih dahulu',
          ),
        );
        return;
      }

      // Filter orders berdasarkan outlet ID
      final orders = await _repository.getOrdersByOutlet(outletId);
      emit(
        state.copyWith(
          orders: orders,
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

  /// Filter berdasarkan tanggal (dengan outlet ID)
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

      // Filter orders untuk tanggal yang dipilih DAN outlet ID
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final orders = await _repository.getOrdersByOutletAndDateRange(
        outletId,
        startOfDay,
        endOfDay,
      );

      emit(
        state.copyWith(
          orders: orders,
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

  /// Filter berdasarkan range tanggal (dengan outlet ID)
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

      emit(
        state.copyWith(
          orders: orders,
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

  /// Filter berdasarkan bulan (dengan outlet ID)
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

      emit(
        state.copyWith(
          orders: orders,
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

  /// Reset filter (tampilkan semua)
  Future<void> resetFilter() async {
    emit(state.copyWith(clearFilter: true));
    await loadOrders();
  }

  /// Hapus order tertentu
  Future<void> deleteOrder(String orderId) async {
    try {
      await _repository.deleteOrder(orderId);
      await loadOrders(); // Reload after delete
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Gagal menghapus order: ${e.toString()}'),
      );
    }
  }

  /// Clear semua history
  Future<void> clearAllHistory() async {
    try {
      await _repository.clearAllOrders();
      emit(state.copyWith(orders: []));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal menghapus semua data: ${e.toString()}',
        ),
      );
    }
  }
}
