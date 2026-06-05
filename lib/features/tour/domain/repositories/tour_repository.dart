import '../entities/tour.dart';
import '../entities/tour_detalle.dart';
import '../entities/tour_precio.dart';

/// Abstract contract for tour CRUD operations.
abstract class TourRepository {
  Future<List<Tour>> getTours();
  Future<List<Tour>> getToursHistoricos();
  Future<Tour> getTourById(String id);
  Future<String> createTour(Tour tour); // returns created tour id
  Future<void> updateTour(Tour tour, {List<TourPrecio>? preciosPayload});
  Future<void> deleteTour(String id);
  Future<void> toggleActive(String id, bool isActive);
  Future<TourDetalle> getTourDetalle(String id);
  Future<void> finalizarTour(String id);
  Future<void> duplicarTour(String id);
  Future<List<String>> getAgentesForBus(String tourId, int busLayoutId);
  Future<void> updateAgentesForBus(String tourId, int busLayoutId, List<String> asientos);
}
