import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/cotizacion.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../../../core/models/paged_result.dart';

class ApiCotizacionRepository implements CotizacionRepository {
  final http.Client client;

  ApiCotizacionRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/cotizaciones';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<PagedResult<Cotizacion>> getCotizaciones({
    int page = 1,
    int limit = 20,
  }) async {
    String url = '$_baseUrl?page=$page&limit=$limit';
    debugPrint('🌎 [ApiCotizacionRepository] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      debugPrint(
        '📦 [ApiCotizacionRepository] Response body: ${response.body}',
      );
      try {
        final dynamic decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          final List<dynamic> data = decoded['data'] ?? [];
          return PagedResult<Cotizacion>(
            data: data
                .map((item) => _fromJson(item as Map<String, dynamic>))
                .toList(),
            total: (decoded['total'] as num?)?.toInt() ?? data.length,
            totalPages: (decoded['totalPages'] as num?)?.toInt() ?? 1,
            page: (decoded['page'] as num?)?.toInt() ?? page,
            limit: (decoded['limit'] as num?)?.toInt() ?? limit,
          );
        } else if (decoded is List) {
          debugPrint(
            '⚠️ [ApiCotizacionRepository] Received legacy List format',
          );
          return PagedResult<Cotizacion>(
            data: decoded
                .map((item) => _fromJson(item as Map<String, dynamic>))
                .toList(),
            total: decoded.length,
            totalPages: 1,
            page: 1,
            limit: decoded.length,
          );
        } else {
          throw Exception(
            'Formato de respuesta desconocido: ${decoded.runtimeType}',
          );
        }
      } catch (e) {
        debugPrint('❌ [ApiCotizacionRepository] Parsing Error: $e');
        rethrow;
      }
    }
    _handleAndThrowError(response, 'cargar cotizaciones');
    throw UnimplementedError(); // Never reached
  }

  @override
  Future<void> markAsRead(int id) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'is_read': true}),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      _handleAndThrowError(response, 'marcar como leída');
    }
  }

  @override
  Future<void> updateEstado(int id, String estado) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'estado': estado}),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      _handleAndThrowError(response, 'actualizar estado');
    }
  }

  @override
  Future<void> createCotizacion(Cotizacion cotizacion) async {
    final body = json.encode({
      'chat_id': cotizacion.chatId,
      'nombre_completo': cotizacion.nombreCompleto,
      'correo_electronico': cotizacion.correoElectronico,
      'detalles_plan': cotizacion.detallesPlan,
      'numero_pasajeros': cotizacion.numeroPasajeros,
      'fecha_salida': cotizacion.fechaSalida,
      'fecha_regreso': cotizacion.fechaRegreso,
      'origen_destino': cotizacion.origenDestino,
      'edades_menores': cotizacion.edadesMenuores,
      'especificaciones': cotizacion.especificaciones,
      'respuesta_cotizacion_id': cotizacion.respuestaCotizacionId,
    });
    debugPrint('📤 [ApiCotizacionRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _handleAndThrowError(response, 'crear cotización');
    }
  }

  @override
  Future<void> updateCotizacion(Cotizacion cotizacion) async {
    final body = json.encode({
      'chat_id': cotizacion.chatId,
      'nombre_completo': cotizacion.nombreCompleto,
      'correo_electronico': cotizacion.correoElectronico,
      'detalles_plan': cotizacion.detallesPlan,
      'numero_pasajeros': cotizacion.numeroPasajeros,
      'fecha_salida': cotizacion.fechaSalida,
      'fecha_regreso': cotizacion.fechaRegreso,
      'origen_destino': cotizacion.origenDestino,
      'edades_menores': cotizacion.edadesMenuores,
      'especificaciones': cotizacion.especificaciones,
      'respuesta_cotizacion_id': cotizacion.respuestaCotizacionId,
    });
    debugPrint(
      '📤 [ApiCotizacionRepository] Updating #${cotizacion.id}: $body',
    );
    final response = await client.patch(
      Uri.parse('$_baseUrl/${cotizacion.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      _handleAndThrowError(response, 'actualizar cotización');
    }
  }

  @override
  Future<void> deleteCotizacion(int id) async {
    debugPrint('🗑️ [ApiCotizacionRepository] Deleting #$id');
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      _handleAndThrowError(response, 'eliminar cotización');
    }
  }

  @override
  Future<Cotizacion> getCotizacion(int id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
    _handleAndThrowError(response, 'obtener cotización');
    throw UnimplementedError();
  }

  void _handleAndThrowError(http.Response response, String action) {
    String message = 'Error al $action (${response.statusCode})';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        final serverMsg = decoded['message'];
        if (serverMsg is List) {
          message = serverMsg.join('\n');
        } else if (serverMsg is String) {
          message = serverMsg;
        }
      }
    } catch (_) {
      // Usar mensaje por defecto si falla el parseo
    }
    debugPrint('❌ [ApiCotizacionRepository] $message');
    throw Exception(message);
  }

  Cotizacion _fromJson(Map<String, dynamic> json) {
    return Cotizacion(
      id: json['id'] ?? 0,
      chatId: json['chat_id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      correoElectronico: json['correo_electronico'],
      detallesPlan: json['detalles_plan'] ?? '',
      numeroPasajeros: json['numero_pasajeros'] ?? 0,
      fechaSalida: json['fecha_salida'],
      fechaRegreso: json['fecha_regreso'],
      origenDestino: json['origen_destino'],
      edadesMenuores: json['edades_menores'],
      especificaciones: json['especificaciones'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      respuestaCotizacionId: json['respuesta_cotizacion_id'],
    );
  }
}
