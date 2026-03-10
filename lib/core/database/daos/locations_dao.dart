import 'package:drift/drift.dart';
import '../app_database.dart';

part 'locations_dao.g.dart';

@DriftAccessor(tables: [Locations])
class LocationsDao extends DatabaseAccessor<AppDatabase> with _$LocationsDaoMixin {
  LocationsDao(super.db);

  Future<List<Location>> getAll() => select(locations).get();
  Stream<List<Location>> watchAll() => select(locations).watch();

  Future<Location?> getById(int id) =>
      (select(locations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Location>> getByParentId(int? parentId) =>
      (select(locations)..where((t) => t.parentId.equalsNullable(parentId))).get();

  Future<int> insertLocation(LocationsCompanion c) => into(locations).insert(c);
  Future<bool> updateLocation(LocationsCompanion c) => update(locations).replace(c);
  Future<int> deleteLocation(Location c) => delete(locations).delete(c);
}
