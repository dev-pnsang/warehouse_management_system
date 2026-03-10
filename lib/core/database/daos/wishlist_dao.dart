import 'package:drift/drift.dart';
import '../app_database.dart';

part 'wishlist_dao.g.dart';

@DriftAccessor(tables: [Wishlist])
class WishlistDao extends DatabaseAccessor<AppDatabase> with _$WishlistDaoMixin {
  WishlistDao(super.db);

  Future<List<WishlistData>> getAll() => select(wishlist).get();
  Stream<List<WishlistData>> watchAll() => select(wishlist).watch();

  Future<int> insertWishlistItem(WishlistCompanion c) => into(wishlist).insert(c);
  Future<bool> updateWishlistItem(WishlistCompanion c) => update(wishlist).replace(c);
  Future<int> deleteWishlistItem(WishlistData c) => delete(wishlist).delete(c);
}
