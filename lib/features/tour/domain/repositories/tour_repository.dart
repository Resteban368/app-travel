import '../entities/tour.dart';
import '../entities/tour_detalle.dart';

/// Abstract contract for tour CRUD operations.
abstract class TourRepository {
  Future<List<Tour>> getTours();
  Future<Tour> getTourById(String id);
  Future<void> createTour(Tour tour);
  Future<void> updateTour(Tour tour);
  Future<void> deleteTour(String id);
  Future<void> toggleActive(String id, bool isActive);
  Future<TourDetalle> getTourDetalle(String id);
}
