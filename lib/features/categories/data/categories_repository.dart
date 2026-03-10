import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/categories_dao.dart';
import '../../../core/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoriesRepository(db.categoriesDao);
});

class CategoriesRepository {
  CategoriesRepository(this._dao);
  final CategoriesDao _dao;

  Stream<List<Category>> watchAll() => _dao.watchAll();
  Future<List<Category>> getAll() => _dao.getAll();
  Future<Category?> getById(int id) => _dao.getById(id);

  Future<int> create(String name, {String? colorHex}) =>
      _dao.insertCategory(CategoriesCompanion.insert(name: name, colorHex: Value(colorHex)));

  Future<void> update(Category c, {String? name, String? colorHex}) =>
      _dao.updateCategory(c.toCompanion(true).copyWith(
        name: Value(name ?? c.name),
        colorHex: Value(colorHex ?? c.colorHex),
      ));

  Future<void> delete(Category c) => _dao.deleteCategory(c);
}
