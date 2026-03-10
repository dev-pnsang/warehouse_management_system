import 'package:drift/drift.dart';
import '../app_database.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items, ItemImages, ItemHistory, Categories, Locations])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Future<List<Item>> getAll() => select(items).get();
  Stream<List<Item>> watchAll() => select(items).watch();

  Future<Item?> getById(int id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<Item>> watchByCategoryId(int? categoryId) {
    if (categoryId == null) return select(items).watch();
    return (select(items)..where((t) => t.categoryId.equals(categoryId))).watch();
  }

  Future<List<Item>> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return select(items).get();
    final pattern = '%$q%';
    return (select(items)
          ..where((t) =>
              t.name.like(pattern) |
              t.barcode.like(pattern) |
              t.tags.like(pattern)))
        .get();
  }

  Stream<List<Item>> watchSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return select(items).watch();
    final pattern = '%$q%';
    return (select(items)
          ..where((t) =>
              t.name.like(pattern) |
              t.barcode.like(pattern) |
              t.tags.like(pattern)))
        .watch();
  }

  Future<List<Item>> getByBarcode(String barcode) =>
      (select(items)..where((t) => t.barcode.equals(barcode))).get();

  Future<int> getTotalCount() => select(items).get().then((l) => l.length);

  Future<int> getLowStockCount(int threshold) =>
      (select(items)..where((t) => t.quantity.isSmallerThanValue(threshold))).get().then((l) => l.length);

  Future<int> insertItem(ItemsCompanion c) => into(items).insert(c);
  Future<bool> updateItem(ItemsCompanion c) => update(items).replace(c);
  Future<int> deleteItem(Item c) => delete(items).delete(c);

  // Item images
  Future<List<ItemImage>> getImagesForItem(int itemId) =>
      (select(itemImages)..where((t) => t.itemId.equals(itemId))..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  Future<int> insertItemImage(ItemImagesCompanion c) => into(itemImages).insert(c);
  Future<int> deleteItemImage(ItemImage c) => delete(itemImages).delete(c);

  // Item history
  Future<List<ItemHistoryData>> getHistoryForItem(int itemId) =>
      (select(itemHistory)..where((t) => t.itemId.equals(itemId))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  Future<int> insertHistory(ItemHistoryCompanion c) => into(itemHistory).insert(c);
}
