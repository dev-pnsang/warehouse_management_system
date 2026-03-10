import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/wishlist_dao.dart';
import '../../../core/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WishlistRepository(db.wishlistDao);
});

class WishlistRepository {
  WishlistRepository(this._dao);
  final WishlistDao _dao;

  Stream<List<WishlistData>> watchAll() => _dao.watchAll();
  Future<List<WishlistData>> getAll() => _dao.getAll();

  Future<int> add(String name, {String? notes, String? imagePath}) =>
      _dao.insertWishlistItem(WishlistCompanion.insert(
        name: name,
        notes: Value(notes),
        imagePath: Value(imagePath),
      ));

  Future<void> update(WishlistData w, {String? name, String? notes}) =>
      _dao.updateWishlistItem(w.toCompanion(true).copyWith(
        name: Value(name ?? w.name),
        notes: Value(notes ?? w.notes),
      ));

  Future<void> delete(WishlistData w) => _dao.deleteWishlistItem(w);
}
