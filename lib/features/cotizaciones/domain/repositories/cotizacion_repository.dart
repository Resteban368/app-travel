import '../entities/cotizacion.dart';

abstract class CotizacionRepository {
  Future<List<Cotizacion>> getCotizaciones();
  Future<void> markAsRead(int id);
}
