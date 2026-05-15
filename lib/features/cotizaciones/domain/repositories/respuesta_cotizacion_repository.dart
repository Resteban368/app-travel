import '../entities/respuesta_cotizacion.dart';

typedef RespuestaPage = ({
  List<RespuestaCotizacion> data,
  int total,
  int totalPages,
  int page,
});

abstract class RespuestaCotizacionRepository {
  /// POST /v1/respuestas-cotizacion
  Future<RespuestaCotizacion> createRespuesta(RespuestaCotizacion respuesta);

  /// GET /v1/respuestas-cotizacion?page=X&limit=Y  (non-public, agent sees only theirs)
  Future<RespuestaPage> getRespuestas({int page = 1, int limit = 20});

  /// GET /v1/respuestas-cotizacion/plantillas?page=X&limit=Y (es_publica=true)
  Future<RespuestaPage> getPlantillas({int page = 1, int limit = 20});

  /// GET /v1/respuestas-cotizacion/:id
  Future<RespuestaCotizacion> getRespuestaById(int id);

  /// GET /v1/respuestas-cotizacion/cotizacion/:id
  Future<List<RespuestaCotizacion>> getRespuestasByCotizacion(int cotizacionId);

  /// PATCH /v1/respuestas-cotizacion/:id
  Future<RespuestaCotizacion> updateRespuesta(RespuestaCotizacion respuesta);

  /// DELETE /v1/respuestas-cotizacion/:id
  Future<void> deleteRespuesta(int id);

  /// PATCH /v1/respuestas-cotizacion/:id  { anclada: bool }
  Future<void> toggleAnclada(int id, {required bool anclada});
}
