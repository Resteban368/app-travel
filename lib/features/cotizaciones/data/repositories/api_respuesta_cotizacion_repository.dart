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

  // ── LIST ALL ──────────────────────────────────────────────────────────────
  @override
  Future<List<RespuestaCotizacion>> getRespuestas({bool sinCotizacion = false}) async {
    final url = sinCotizacion ? '$_baseUrl?sinCotizacion=true' : _baseUrl;
    debugPrint('🌎 [RespuestaCotizacion] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> list =
          decoded is List ? decoded : (decoded['data'] ?? []);
      return list
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throw(response, 'listar respuestas de cotización');
    throw UnimplementedError();
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
      final List<dynamic> list =
          decoded is List ? decoded : (decoded['data'] ?? []);
      return list
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throw(response, 'listar respuestas de cotización #$cotizacionId');
    throw UnimplementedError();
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> _toJson(RespuestaCotizacion r) => {
        if (r.cotizacionId != null) 'cotizacion_id': r.cotizacionId,
        'titulo_viaje': r.tituloViaje,
        'imagenes_destino': r.imagenesDestino,
        'items_incluidos': r.itemsIncluidos,
        'items_no_incluidos': r.itemsNoIncluidos,
        'vuelos': r.vuelos.map(_vueloToJson).toList(),
        'opciones_hotel': r.opcionesHotel.map(_hotelToJson).toList(),
        'adicionales': r.adicionales.map(_adicionalToJson).toList(),
        'condiciones_generales': r.condicionesGenerales,
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
        'costo': v.costo,
        'numero_pasajeros': v.numeroPasajeros,
      };

  Map<String, dynamic> _hotelToJson(OpcionHotel h) => {
        'nombre': h.nombre,
        'tipo_habitacion': h.tipoHabitacion,
        'que_incluye': h.queIncluye,
        'fecha_entrada': h.fechaEntrada,
        'fecha_salida': h.fechaSalida,
        'precio_adulto': h.precioAdulto,
        'precio_menor': h.precioMenor,
        'precio_total': h.precioTotal,
        'fotos': h.fotos,
      };

  Map<String, dynamic> _adicionalToJson(AdicionalViaje a) => {
        'nombre': a.nombre,
        'descripcion': a.descripcion,
        'precio': a.precio,
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
      vuelos: asList(j['vuelos'])
          .map((e) => _vueloFromJson(e as Map<String, dynamic>))
          .toList(),
      opcionesHotel: asList(j['opciones_hotel'])
          .map((e) => _hotelFromJson(e as Map<String, dynamic>))
          .toList(),
      adicionales: asList(j['adicionales'])
          .map((e) => _adicionalFromJson(e as Map<String, dynamic>))
          .toList(),
      condicionesGenerales: j['condiciones_generales'] as String? ?? '',
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
    );
  }

  VueloItinerario _vueloFromJson(Map<String, dynamic> j) => VueloItinerario(
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
      );

  OpcionHotel _hotelFromJson(Map<String, dynamic> j) => OpcionHotel(
        nombre: j['nombre'] as String? ?? '',
        tipoHabitacion: j['tipo_habitacion'] as String? ?? '',
        queIncluye: List<String>.from(
          j['que_incluye'] is List ? j['que_incluye'] as List : [],
        ),
        fechaEntrada: j['fecha_entrada'] as String? ?? '',
        fechaSalida: j['fecha_salida'] as String? ?? '',
        precioAdulto: (j['precio_adulto'] as num?)?.toDouble() ?? 0,
        precioMenor: (j['precio_menor'] as num?)?.toDouble() ?? 0,
        precioTotal: (j['precio_total'] as num?)?.toDouble() ?? 0,
        fotos: List<String>.from(
          j['fotos'] is List ? j['fotos'] as List : [],
        ),
      );

  AdicionalViaje _adicionalFromJson(Map<String, dynamic> j) => AdicionalViaje(
        nombre: j['nombre'] as String? ?? '',
        descripcion: j['descripcion'] as String? ?? '',
        precio: (j['precio'] as num?)?.toDouble() ?? 0,
      );

  // ── UPDATE ────────────────────────────────────────────────────────────────
  @override
  Future<RespuestaCotizacion> updateRespuesta(RespuestaCotizacion respuesta) async {
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
}
