import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../items/data/items_repository.dart';
import '../../categories/data/categories_repository.dart';

final totalItemsProvider = FutureProvider<int>((ref) {
  return ref.watch(itemsRepositoryProvider).getTotalCount();
});

final totalCategoriesProvider = FutureProvider<int>((ref) {
  return ref.watch(categoriesRepositoryProvider).getAll().then((l) => l.length);
});

final lowStockCountProvider = FutureProvider<int>((ref) {
  return ref.watch(itemsRepositoryProvider).getLowStockCount(AppConstants.lowStockThreshold);
});

final recentActivityProvider = FutureProvider((ref) {
  return ref.watch(itemsRepositoryProvider).getRecent(AppConstants.recentActivityLimit);
});
