import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/features/menu/domain/models/menu_item.dart';
import 'package:sagawa_pos_new/features/menu/domain/repositories/menu_repository.dart';

// States
abstract class MenuState {}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItem> items;
  final List<MenuItem> modifiedItems;

  MenuLoaded(this.items, {List<MenuItem>? modifiedItems})
    : modifiedItems = modifiedItems ?? [];

  bool get hasChanges => modifiedItems.isNotEmpty;
}

class MenuError extends MenuState {
  final String message;

  MenuError(this.message);
}

class MenuSaving extends MenuState {
  final List<MenuItem> items;

  MenuSaving(this.items);
}

// Cubit
class MenuCubit extends Cubit<MenuState> {
  final MenuRepository _repository;

  MenuCubit(this._repository) : super(MenuInitial());

  Future<void> loadMenuItems() async {
    emit(MenuLoading());
    try {
      final items = await _repository.getMenuItems();
      emit(MenuLoaded(items));
    } catch (e) {
      emit(MenuError('Gagal memuat menu: $e'));
    }
  }

  void toggleEnabled(String itemId, bool enabled) {
    final currentState = state;
    if (currentState is! MenuLoaded) return;

    final updatedItems = currentState.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isEnabled: enabled);
      }
      return item;
    }).toList();

    // Track modified items
    final modifiedItem = updatedItems.firstWhere((item) => item.id == itemId);
    final modifiedList = List<MenuItem>.from(currentState.modifiedItems);

    // Remove old version if exists, add new version
    modifiedList.removeWhere((item) => item.id == itemId);
    modifiedList.add(modifiedItem);

    emit(MenuLoaded(updatedItems, modifiedItems: modifiedList));
  }

  void updateStock(String itemId, int stock) {
    final currentState = state;
    if (currentState is! MenuLoaded) return;

    final updatedItems = currentState.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(stock: stock);
      }
      return item;
    }).toList();

    // Track modified items
    final modifiedItem = updatedItems.firstWhere((item) => item.id == itemId);
    final modifiedList = List<MenuItem>.from(currentState.modifiedItems);

    // Remove old version if exists, add new version
    modifiedList.removeWhere((item) => item.id == itemId);
    modifiedList.add(modifiedItem);

    emit(MenuLoaded(updatedItems, modifiedItems: modifiedList));
  }

  Future<void> saveChanges() async {
    final currentState = state;
    if (currentState is! MenuLoaded) return;

    emit(MenuSaving(currentState.items));

    try {
      // Save only modified items
      if (currentState.modifiedItems.isNotEmpty) {
        await _repository.updateMultipleMenuItems(currentState.modifiedItems);
      }

      // Reload to get fresh data
      await loadMenuItems();
    } catch (e) {
      emit(MenuError('Gagal menyimpan perubahan: $e'));
      // Restore previous state
      emit(currentState);
    }
  }
}
