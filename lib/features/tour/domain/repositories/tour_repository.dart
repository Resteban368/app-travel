import '../entities/tour.dart';
import '../entities/tour_detalle.dart';
import '../entities/tour_precio.dart';
import '../entities/tour_salida.dart';

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
  Future<List<String>> getAgentesForBus(String tourId, int busLayoutId, {int? salidaId});
  Future<void> updateAgentesForBus(String tourId, int busLayoutId, List<String> asientos, {int? salidaId});
  Future<List<TourSalida>> getTourSalidas(String tourId);
  Future<TourSalida> addTourSalida(String tourId, TourSalida salida);
  Future<void> updateTourSalida(String tourId, int salidaId, {required List<int> busLayoutIds});
}
