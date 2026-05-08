import '../entities/bus_manifiesto.dart';

abstract class BusManifiestoRepository {
  Future<BusManifiesto> getBusManifiesto(int tourId);
  Future<void> autoAsignarAsientos(int tourId);
  Future<void> liberarAsiento({required int tourId, required int reservaId, required String numeroAsiento});
  Future<void> moverAsiento({
    required int tourId,
    required int busLayoutId,
    required int reservaIdOrigen,
    required String asientoOrigen,
    required String asientoDestino,
  });
}
