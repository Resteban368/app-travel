import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/respuesta_cotizacion.dart';
import '../../domain/repositories/respuesta_cotizacion_repository.dart';

class ApiRespuestaCotizacionRepository
    implements RespuestaCotizacionRepository {
  final http.Client client;

  ApiRespuestaCotizacionRepository({required this.client});

  static String get _baseUrl =>
      '${ApiConstants.kBaseUrl}/v1/respuestas-cotizacion';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // ── CREATE ────────────────────────────────────────────────────────────────
  @override
  Future<RespuestaCotizacion> createRespuesta(
    RespuestaCotizacion respuesta,
  ) async {
    final body = json.encode(_toJson(respuesta));
    debugPrint('📤 [RespuestaCotizacion] POST $_baseUrl\n$body');

    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    _throw(response, 'crear respuesta de cotización');
    throw UnimplementedError();
  }

  // ── LIST (paginated, agent sees only theirs) ──────────────────────────────
  @override
  Future<RespuestaPage> getRespuestas({int page = 1, int limit = 20}) async {
    final url = '$_baseUrl?page=$page&limit=$limit';
    debugPrint('🌎 [RespuestaCotizacion] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return _parsePage(response.body, 'listar respuestas de cotización');
    }
    _throw(response, 'listar respuestas de cotización');
    throw UnimplementedError();
  }

  // ── PLANTILLAS (paginated, es_publica=true) ───────────────────────────────
  @override
  Future<RespuestaPage> getPlantillas({int page = 1, int limit = 20}) async {
    final url = '$_baseUrl/plantillas?page=$page&limit=$limit';
    debugPrint('🌎 [RespuestaCotizacion] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return _parsePage(response.body, 'listar plantillas');
    }
    _throw(response, 'listar plantillas');
    throw UnimplementedError();
  }

  RespuestaPage _parsePage(String body, String action) {
    final decoded = json.decode(body);
    final List<dynamic> list;
    int total = 0;
    int totalPages = 1;
    int page = 1;

    if (decoded is List) {
      list = decoded;
      total = decoded.length;
    } else {
      list = (decoded['data'] ?? []) as List<dynamic>;
      total = (decoded['total'] as num?)?.toInt() ?? list.length;
      totalPages = (decoded['totalPages'] as num?)?.toInt() ??
          (decoded['total_pages'] as num?)?.toInt() ?? 1;
      page = (decoded['page'] as num?)?.toInt() ?? 1;
    }

    return (
      data: list.map((e) => _fromJson(e as Map<String, dynamic>)).toList(),
      total: total,
      totalPages: totalPages,
      page: page,
    );
  }

  // ── GET BY ID ─────────────────────────────────────────────────────────────
  @override
  Future<RespuestaCotizacion> getRespuestaById(int id) async {
    final url = '$_baseUrl/$id';
    debugPrint('🌎 [RespuestaCotizacion] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    _throw(response, 'obtener respuesta #$id');
    throw UnimplementedError();
  }

  // ── GET BY COTIZACION ─────────────────────────────────────────────────────
  @override
  Future<List<RespuestaCotizacion>> getRespuestasByCotizacion(
    int cotizacionId,
  ) async {
    final url = '$_baseUrl/cotizacion/$cotizacionId';
    debugPrint('🌎 [RespuestaCotizacion] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded['data'] ?? []);
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    }
    _throw(response, 'listar respuestas de cotización #$cotizacionId');
    throw UnimplementedError();
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> _toJson(RespuestaCotizacion r) => {
    if (r.cotizacionId != null) 'cotizacion_id': r.cotizacionId,
    'titulo_viaje': r.tituloViaje,
    'nombre_cliente': r.nombreCliente ?? '',
    'telefono_cliente': r.telefonoCliente ?? '',
    'imagenes_destino': r.imagenesDestino,
    'items_incluidos': r.itemsIncluidos,
    'items_no_incluidos': r.itemsNoIncluidos,
    'vuelos': r.vuelos.map(_vueloToJson).toList(),
    'opciones_hotel': r.opcionesHotel.map(_hotelToJson).toList(),
    'adicionales': r.adicionales.map(_adicionalToJson).toList(),
    'condiciones_generales': r.condicionesGenerales,
    'es_publica': r.esPublica,
  };

  Map<String, dynamic> _vueloToJson(VueloItinerario v) => {
    'tipo': v.tipo,
    if (v.aerolineaId != null) 'aerolinea_id': v.aerolineaId,
    'numero_vuelo': v.numeroVuelo,
    'origen': v.origen,
    'destino': v.destino,
    'fecha': v.fecha,
    'hora_salida': v.horaSalida,
    'hora_llegada': v.horaLlegada,
    if (v.costo > 0) 'costo': v.costo,
    'numero_pasajeros': v.numeroPasajeros,
    'escalas': v.escalas.map(_escalaToJson).toList(),
  };

  Map<String, dynamic> _escalaToJson(EscalaVuelo e) => {
    if (e.aerolineaId != null) 'aerolinea_id': e.aerolineaId,
    'aerolinea': e.aerolinea,
    'numero_vuelo': e.numeroVuelo,
    'origen': e.origen,
    'destino': e.destino,
    'hora_salida': e.horaSalida,
    'hora_llegada': e.horaLlegada,
    'tiempo_conexion': e.tiempoConexion,
  };

  Map<String, dynamic> _hotelToJson(OpcionHotel h) => {
    'nombre': h.nombre,
    'tipo_habitacion': h.tipoHabitacion,
    'que_incluye': h.queIncluye,
    'fecha_entrada': h.fechaEntrada,
    'hora_entrada': h.horaEntrada,
    'fecha_salida': h.fechaSalida,
    'hora_salida': h.horaSalida,
    if (h.precioAdulto > 0) 'precio_adulto': h.precioAdulto,
    if (h.precioMenor > 0) 'precio_menor': h.precioMenor,
    'precio_total': h.precioTotal,
    'fotos': h.fotos,
    'notas': h.notas,
  };

  Map<String, dynamic> _adicionalToJson(AdicionalViaje a) => {
    'nombre': a.nombre,
    'descripcion': a.descripcion,
    'precio': a.precio,
    'es_seleccionable': a.esSeleccionable,
  };

  RespuestaCotizacion _fromJson(Map<String, dynamic> j) {
    List<dynamic> asList(dynamic v) => v is List ? v : [];

    return RespuestaCotizacion(
      id: j['id'] as int?,
      cotizacionId: j['cotizacion_id'] as int?,
      token: j['token'] as String?,
      tituloViaje: j['titulo_viaje'] as String? ?? '',
      imagenesDestino: List<String>.from(asList(j['imagenes_destino'])),
      itemsIncluidos: List<String>.from(asList(j['items_incluidos'])),
      itemsNoIncluidos: List<String>.from(asList(j['items_no_incluidos'])),
      vuelos: asList(
        j['vuelos'],
      ).map((e) => _vueloFromJson(e as Map<String, dynamic>)).toList(),
      opcionesHotel: asList(
        j['opciones_hotel'],
      ).map((e) => _hotelFromJson(e as Map<String, dynamic>)).toList(),
      adicionales: asList(
        j['adicionales'],
      ).map((e) => _adicionalFromJson(e as Map<String, dynamic>)).toList(),
      condicionesGenerales: j['condiciones_generales'] as String? ?? '',
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
      nombreCliente: j['nombre_cliente'] as String?,
      telefonoCliente: j['telefono_cliente'] as String?,
      creadoPorId: j['creado_por_id'] as int?,
      creadoPorNombre: j['creado_por_nombre'] as String?,
      anclada: j['anclada'] as bool? ?? false,
      esPublica: j['es_publica'] as bool? ?? false,
      totalVistas: (j['total_vistas'] as num?)?.toInt(),
      precioTotal: (j['precio_total'] as num?)?.toDouble(),
      primeraVista: j['primera_vista'] != null
          ? DateTime.tryParse(j['primera_vista'] as String)
          : null,
      ultimaVista: j['ultima_vista'] != null
          ? DateTime.tryParse(j['ultima_vista'] as String)
          : null,
      vistas: asList(j['vistas'])
          .map((e) => _vistaFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  VistaRespuesta _vistaFromJson(Map<String, dynamic> j) => VistaRespuesta(
    id: (j['id'] as num).toInt(),
    respuestaId: (j['respuesta_id'] as num).toInt(),
    ip: j['ip'] as String? ?? '',
    userAgent: j['user_agent'] as String? ?? '',
    createdAt: j['created_at'] != null
        ? DateTime.parse(j['created_at'] as String)
        : DateTime.now(),
  );

  VueloItinerario _vueloFromJson(Map<String, dynamic> j) {
    List<dynamic> asList(dynamic v) => v is List ? v : [];
    // Backward compat: formato antiguo (tiene_escala / ciudad_escala / tiempo_escala)
    List<EscalaVuelo> escalas;
    if (j.containsKey('escalas')) {
      escalas = asList(j['escalas'])
          .map((e) => _escalaFromJson(e as Map<String, dynamic>))
          .toList();
    } else if (j['tiene_escala'] as bool? ?? false) {
      escalas = [
        EscalaVuelo(
          origen: j['ciudad_escala'] as String? ?? '',
          destino: j['ciudad_escala'] as String? ?? '',
          tiempoConexion: j['tiempo_escala'] as String? ?? '',
        ),
      ];
    } else {
      escalas = const [];
    }
    return VueloItinerario(
      tipo: j['tipo'] as String? ?? 'ida',
      aerolineaId: j['aerolinea_id'] as int?,
      aerolinea: j['aerolinea'] as String? ?? '',
      numeroVuelo: j['numero_vuelo'] as String? ?? '',
      origen: j['origen'] as String? ?? '',
      destino: j['destino'] as String? ?? '',
      fecha: j['fecha'] as String? ?? '',
      horaSalida: j['hora_salida'] as String? ?? '',
      horaLlegada: j['hora_llegada'] as String? ?? '',
      costo: (j['costo'] as num?)?.toDouble() ?? 0,
      numeroPasajeros: (j['numero_pasajeros'] as int?) ?? 1,
      escalas: escalas,
    );
  }

  EscalaVuelo _escalaFromJson(Map<String, dynamic> j) => EscalaVuelo(
    aerolineaId: j['aerolinea_id'] as int?,
    aerolinea: j['aerolinea'] as String? ?? '',
    numeroVuelo: j['numero_vuelo'] as String? ?? '',
    origen: j['origen'] as String? ?? '',
    destino: j['destino'] as String? ?? '',
    horaSalida: j['hora_salida'] as String? ?? '',
    horaLlegada: j['hora_llegada'] as String? ?? '',
    tiempoConexion: j['tiempo_conexion'] as String? ?? '',
  );

  OpcionHotel _hotelFromJson(Map<String, dynamic> j) => OpcionHotel(
    nombre: j['nombre'] as String? ?? '',
    tipoHabitacion: j['tipo_habitacion'] as String? ?? '',
    queIncluye: List<String>.from(
      j['que_incluye'] is List ? j['que_incluye'] as List : [],
    ),
    fechaEntrada: j['fecha_entrada'] as String? ?? '',
    horaEntrada: j['hora_entrada'] as String? ?? '',
    fechaSalida: j['fecha_salida'] as String? ?? '',
    horaSalida: j['hora_salida'] as String? ?? '',
    precioAdulto: (j['precio_adulto'] as num?)?.toDouble() ?? 0,
    precioMenor: (j['precio_menor'] as num?)?.toDouble() ?? 0,
    precioTotal: (j['precio_total'] as num?)?.toDouble() ?? 0,
    fotos: List<String>.from(j['fotos'] is List ? j['fotos'] as List : []),
    notas: j['notas'] as String? ?? '',
  );

  AdicionalViaje _adicionalFromJson(Map<String, dynamic> j) => AdicionalViaje(
    nombre: j['nombre'] as String? ?? '',
    descripcion: j['descripcion'] as String? ?? '',
    precio: (j['precio'] as num?)?.toDouble() ?? 0,
    esSeleccionable: j['es_seleccionable'] as bool? ?? true,
  );

  // ── UPDATE ────────────────────────────────────────────────────────────────
  @override
  Future<RespuestaCotizacion> updateRespuesta(
    RespuestaCotizacion respuesta,
  ) async {
    final url = '$_baseUrl/${respuesta.id}';
    final body = json.encode(_toJson(respuesta));
    debugPrint('📤 [RespuestaCotizacion] PATCH $url\n$body');

    final response = await client.patch(
      Uri.parse(url),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    _throw(response, 'actualizar respuesta de cotización');
    throw UnimplementedError();
  }

  // ── Error handling ────────────────────────────────────────────────────────

  void _throw(http.Response response, String action) {
    String message = 'Error al $action (${response.statusCode})';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        final serverMsg = decoded['message'];
        if (serverMsg is List) {
          message = serverMsg.join('\n');
        } else {
          message = serverMsg.toString();
        }
      }
    } catch (_) {}
    debugPrint('❌ [RespuestaCotizacion] $message');
    throw Exception(message);
  }

  // ── TOGGLE ANCLADA ────────────────────────────────────────────────────────
  @override
  Future<void> toggleAnclada(int id, {required bool anclada}) async {
    debugPrint('📌 [RespuestaCotizacion] PATCH $_baseUrl/$id {anclada: $anclada}');
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'anclada': anclada}),
    );
    if (response.statusCode == 200 || response.statusCode == 204) return;
    _throw(response, 'anclar respuesta de cotización');
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  @override
  Future<void> deleteRespuesta(int id) async {
    debugPrint('🗑️ [RespuestaCotizacion] DELETE $_baseUrl/$id');
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) return;
    _throw(response, 'eliminar respuesta de cotización');
  }
}
