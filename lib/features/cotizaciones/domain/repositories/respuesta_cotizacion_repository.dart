import '../entities/respuesta_cotizacion.dart';

abstract class RespuestaCotizacionRepository {
  /// POST /v1/respuestas-cotizacion
  Future<RespuestaCotizacion> createRespuesta(RespuestaCotizacion respuesta);

  /// GET /v1/respuestas-cotizacion
  Future<List<RespuestaCotizacion>> getRespuestas({bool sinCotizacion = false});

  /// GET /v1/respuestas-cotizacion/:id
  Future<RespuestaCotizacion> getRespuestaById(int id);

  /// GET /v1/respuestas-cotizacion/cotizacion/:id
  Future<List<RespuestaCotizacion>> getRespuestasByCotizacion(int cotizacionId);

  /// PATCH /v1/respuestas-cotizacion/:id
  Future<RespuestaCotizacion> updateRespuesta(RespuestaCotizacion respuesta);
}
