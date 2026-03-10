import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/locations_dao.dart';
import '../../../core/providers/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocationsRepository(db.locationsDao);
});

class LocationsRepository {
  LocationsRepository(this._dao);
  final LocationsDao _dao;

  Stream<List<Location>> watchAll() => _dao.watchAll();
  Future<List<Location>> getAll() => _dao.getAll();
  Future<Location?> getById(int id) => _dao.getById(id);
  Future<List<Location>> getByParentId(int? parentId) => _dao.getByParentId(parentId);

  Future<int> create(String name, {int? parentId}) =>
      _dao.insertLocation(LocationsCompanion.insert(name: name, parentId: Value(parentId)));

  Future<void> update(Location l, {String? name, int? parentId}) =>
      _dao.updateLocation(l.toCompanion(true).copyWith(
        name: Value(name ?? l.name),
        parentId: Value(parentId ?? l.parentId),
      ));

  Future<void> delete(Location l) => _dao.deleteLocation(l);
}
