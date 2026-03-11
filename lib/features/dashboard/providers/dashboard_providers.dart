import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../items/data/items_repository.dart';
import '../../categories/data/categories_repository.dart';

/// Real-time: cập nhật ngay khi thêm/xóa/sửa item.
final totalItemsProvider = StreamProvider<int>((ref) {
  return ref.watch(itemsRepositoryProvider).watchTotalCount();
});

/// Real-time: cập nhật khi thêm/xóa/sửa danh mục.
final totalCategoriesProvider = StreamProvider<int>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll().map((l) => l.length);
});

/// Real-time: số item dưới ngưỡng low stock.
final lowStockCountProvider = StreamProvider<int>((ref) {
  return ref.watch(itemsRepositoryProvider).watchLowStockCount(AppConstants.lowStockThreshold);
});

/// Real-time: danh sách item gần đây.
final recentActivityProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(itemsRepositoryProvider).watchRecent(AppConstants.recentActivityLimit);
});
