import 'package:drift/drift.dart';
import '../app_database.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> getAll() => select(categories).get();
  Stream<List<Category>> watchAll() => select(categories).watch();

  Future<Category?> getById(int id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion c) => into(categories).insert(c);
  Future<bool> updateCategory(CategoriesCompanion c) => update(categories).replace(c);
  Future<int> deleteCategory(Category c) => delete(categories).delete(c);
}
