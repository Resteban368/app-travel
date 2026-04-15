import '../entities/cotizacion.dart';

abstract class CotizacionRepository {
  Future<List<Cotizacion>> getCotizaciones();
  Future<void> markAsRead(int id);
  Future<void> createCotizacion(Cotizacion cotizacion);
  Future<void> updateEstado(int id, String estado);
}
