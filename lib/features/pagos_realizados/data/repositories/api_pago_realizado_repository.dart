import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/pago_realizado.dart';
import '../../domain/repositories/pago_realizado_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/models/paged_result.dart';

class ApiPagoRealizadoRepository implements PagoRealizadoRepository {
  final http.Client client;

  ApiPagoRealizadoRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/pagos-realizados';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<PagedResult<PagoRealizado>> getPagos({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null)
      params['startDate'] = startDate.toUtc().toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toUtc().toIso8601String();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    debugPrint('API CALL: GET $uri');
    final response = await client.get(uri, headers: _headers);
    debugPrint('API RESPONSE: ${response.statusCode}');

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as List<dynamic>)
          .map((j) => _fromJson(j as Map<String, dynamic>))
          .toList();
      return PagedResult(
        data: data,
        total: (body['total'] as num?)?.toInt() ?? data.length,
        totalPages: (body['totalPages'] as num?)?.toInt() ?? 1,
        page: (body['page'] as num?)?.toInt() ?? page,
        limit: (body['limit'] as num?)?.toInt() ?? limit,
      );
    }
    debugPrint('API RESPONSE: ${response.body}');
    throw Exception('Error loading payments: ${response.statusCode}');
  }

  @override
  Future<List<PagoRealizado>> getPagosByReserva(int reservaId) async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'reserva_id': reservaId.toString()});
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      List<dynamic> data = [];
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        data = decoded;
      }
      debugPrint('API RESPONSE: ${response.body}');
      return data.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(
      'Error al cargar pagos de la reserva: ${response.statusCode}',
    );
  }

  @override
  Future<PagoRealizado> getPagoById(int id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
    debugPrint('API RESPONSE: ${response.body}');
    throw Exception('Error loading payment $id: ${response.statusCode}');
  }

  @override
  Future<void> createPago(PagoRealizado pago) async {
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: json.encode(_toJson(pago)),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      debugPrint('API RESPONSE: ${response.body}');
      throw Exception('Error creating payment: ${response.statusCode}');
    }
  }

  @override
  Future<void> updatePago(PagoRealizado pago) async {
    final body = json.encode(_toJson(pago));
    debugPrint('[PagoRepo] PATCH body → $body');
    final response = await client.patch(
      Uri.parse('$_baseUrl/${pago.id}'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode != 200) {
      debugPrint('API RESPONSE: ${response.body}');
      throw Exception('Error updating payment: ${response.statusCode}');
    }
  }

  @override
  Future<void> deletePago(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      debugPrint('API RESPONSE: ${response.body}');
      throw Exception('Error deleting payment: ${response.statusCode}');
    }
  }

  @override
  Future<PagoRealizado> cambiarEstadoPago(
    int idPago,
    String accion, {
    String? motivoRechazo,
  }) async {
    final body = <String, dynamic>{'accion': accion};
    if (motivoRechazo != null) body['motivo_rechazo'] = motivoRechazo;

    final response = await client.patch(
      Uri.parse('$_baseUrl/$idPago/estado'),
      headers: _headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    debugPrint('API RESPONSE: ${response.body}');
    throw Exception('Error al cambiar estado: ${response.statusCode}');
  }

  PagoRealizado _fromJson(Map<String, dynamic> json) {
    return PagoRealizado(
      id: json['id_pago'] ?? 0,
      chatId: json['chat_id'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? '',
      monto: double.tryParse(json['monto']?.toString() ?? '0') ?? 0.0,
      proveedorComercio: json['proveedor_comercio'] ?? '',
      nit: json['nit'] ?? '',
      metodoPago: json['metodo_pago'] ?? '',
      referencia: json['referencia'] ?? '',
      fechaDocumento: json['fecha_documento'] ?? '',
      isValidated: json['is_validated'] == true || json['is_validated'] == 1,
      isRechazado: json['is_rechazado'] == true || json['is_rechazado'] == 1,
      motivoRechazo: json['motivo_rechazo']?.toString(),
      urlImagen: json['url_imagen'] ?? '',
      reservaId: json['reserva_id'] is int
          ? json['reserva_id']
          : int.tryParse(json['reserva_id']?.toString() ?? ''),
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
      updatedAt: json['ultimo_cambio'] != null
          ? DateTime.parse(json['ultimo_cambio'])
          : null,
    );
  }

  Map<String, dynamic> _toJson(PagoRealizado pago) {
    final map = <String, dynamic>{
      'chat_id': pago.chatId,
      'tipo_documento': pago.tipoDocumento,
      'monto': pago.monto,
      'proveedor_comercio': pago.proveedorComercio,
      if (pago.nit.isNotEmpty) 'nit': pago.nit,
      'metodo_pago': pago.metodoPago,
      'referencia': pago.referencia,
      'fecha_documento': pago.fechaDocumento,
      'is_validated': pago.isValidated,
      'is_rechazado': pago.isRechazado,
      if (pago.motivoRechazo != null) 'motivo_rechazo': pago.motivoRechazo,
      'url_imagen': pago.urlImagen,
    };
    // Only include reserva_id if it's not null — sending null would overwrite
    // the existing FK value in the DB since the backend treats null as a valid value.
    if (pago.reservaId != null) {
      map['reserva_id'] = pago.reservaId;
    }
    return map;
  }
}
