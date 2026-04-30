import '../entities/cotizacion.dart';
import '../../../../core/models/paged_result.dart';

abstract class CotizacionRepository {
  Future<PagedResult<Cotizacion>> getCotizaciones({
    int page = 1,
    int limit = 20,
  });
  Future<void> markAsRead(int id);
  Future<void> createCotizacion(Cotizacion cotizacion);
  Future<void> updateCotizacion(Cotizacion cotizacion);
  Future<void> deleteCotizacion(int id);
  Future<void> updateEstado(int id, String estado);
  Future<Cotizacion> getCotizacion(int id);
}
