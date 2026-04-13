import '../entities/catalogue.dart';

abstract class CatalogueRepository {
  Future<List<Catalogue>> getCatalogues();
  Future<void> createCatalogue(Catalogue catalogue);
  Future<void> updateCatalogue(Catalogue catalogue);
  Future<void> deleteCatalogue(int id);
}
