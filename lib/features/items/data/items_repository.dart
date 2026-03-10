import 'dart:io';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/items_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/image_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ItemsRepository(db.itemsDao);
});

class ItemsRepository {
  ItemsRepository(this._dao);

  final ItemsDao _dao;

  Stream<List<Item>> watchAll() => _dao.watchAll();
  Stream<List<Item>> watchSearch(String query) => _dao.watchSearch(query);
  Stream<List<Item>> watchByCategory(int? categoryId) => _dao.watchByCategoryId(categoryId);

  Future<Item?> getById(int id) => _dao.getById(id);
  Future<List<Item>> search(String query) => _dao.search(query);
  Future<List<Item>> getByBarcode(String barcode) => _dao.getByBarcode(barcode);

  Future<int> getTotalCount() => _dao.getTotalCount();
  Future<int> getLowStockCount(int threshold) => _dao.getLowStockCount(threshold);

  Future<List<Item>> getRecent(int limit) async {
    final all = await _dao.getAll();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.take(limit).toList();
  }

  Future<int> addItem({
    required String imagePath,
    String? name,
    int quantity = 1,
    int? categoryId,
    int? locationId,
    String? barcode,
  }) async {
    final id = await _dao.insertItem(ItemsCompanion.insert(
      imagePath: imagePath,
      name: Value(name),
      quantity: Value(quantity),
      categoryId: Value(categoryId),
      locationId: Value(locationId),
      barcode: Value(barcode),
    ));
    await _dao.insertHistory(ItemHistoryCompanion.insert(
      itemId: id,
      description: 'Added (qty: $quantity)',
      quantityDelta: quantity,
    ));
    return id;
  }

  Future<void> updateItem(Item item, {int? newQuantity, String? name, String? notes, int? categoryId, int? locationId}) async {
    final delta = newQuantity != null ? newQuantity - item.quantity : 0;
    final c = item.toCompanion(true).copyWith(
      name: Value(name ?? item.name),
      quantity: Value(newQuantity ?? item.quantity),
      notes: Value(notes ?? item.notes),
      categoryId: Value(categoryId ?? item.categoryId),
      locationId: Value(locationId ?? item.locationId),
      updatedAt: Value(DateTime.now()),
    );
    await _dao.updateItem(c);
    if (delta != 0) {
      await _dao.insertHistory(ItemHistoryCompanion.insert(
        itemId: item.id,
        description: delta > 0 ? '+$delta' : '$delta',
        quantityDelta: delta,
      ));
    }
  }

  Future<void> addQuantity(Item item, int add) async {
    await _dao.updateItem(item.toCompanion(true).copyWith(
      quantity: Value(item.quantity + add),
      updatedAt: Value(DateTime.now()),
    ));
    await _dao.insertHistory(ItemHistoryCompanion.insert(
      itemId: item.id,
      description: '+$add',
      quantityDelta: add,
    ));
  }

  Future<void> deleteItem(Item item) async {
    try {
      final f = File(item.imagePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await _dao.deleteItem(item);
  }

  Future<List<ItemImage>> getItemImages(int itemId) => _dao.getImagesForItem(itemId);
  Future<List<ItemHistoryData>> getItemHistory(int itemId) => _dao.getHistoryForItem(itemId);

  Future<void> addItemImage(int itemId, File imageFile) async {
    final path = await ImageStorage.saveItemImage(imageFile);
    final images = await _dao.getImagesForItem(itemId);
    await _dao.insertItemImage(ItemImagesCompanion.insert(
      itemId: itemId,
      path: path,
      sortOrder: Value(images.length),
    ));
  }

  Future<void> deleteItemImage(ItemImage img) async {
    await ImageStorage.deleteImage(img.path);
    await _dao.deleteItemImage(img);
  }
}
