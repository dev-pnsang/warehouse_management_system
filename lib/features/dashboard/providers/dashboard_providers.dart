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

final expiringSoonCountProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  final limit = now.add(Duration(days: AppConstants.expirySoonDays));
  return ref.watch(itemsRepositoryProvider).watchAll().map((items) {
    return items.where((i) {
      final d = _parseDate(i.expiryDate);
      if (d == null) return false;
      return !d.isBefore(now) && !d.isAfter(limit);
    }).length;
  });
});

final expiredCountProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  return ref.watch(itemsRepositoryProvider).watchAll().map((items) {
    return items.where((i) {
      final d = _parseDate(i.expiryDate);
      return d != null && d.isBefore(now);
    }).length;
  });
});

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim());
}
