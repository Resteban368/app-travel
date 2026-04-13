import '../entities/sede.dart';

/// Abstract contract for Sede CRUD operations.
abstract class SedeRepository {
  Future<List<Sede>> getSedes();
  Future<void> createSede(Sede sede);
  Future<void> updateSede(Sede sede);
  Future<void> deleteSede(String id);
}
