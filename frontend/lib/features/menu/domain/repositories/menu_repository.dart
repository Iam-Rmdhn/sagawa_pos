import 'package:sagawa_pos_new/features/menu/domain/models/menu_item.dart';

abstract class MenuRepository {
  Future<List<MenuItem>> getMenuItems();
  Future<void> updateMenuItem(MenuItem item);
  Future<void> updateMultipleMenuItems(List<MenuItem> items);
}
