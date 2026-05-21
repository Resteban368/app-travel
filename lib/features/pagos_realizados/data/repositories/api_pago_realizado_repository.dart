import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/pago_realizado.dart';
import '../../domain/repositories/pago_realizado_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/network/api_exception.dart';
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
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) {
      params['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) params['endDate'] = endDate.toUtc().toIso8601String();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    debugPrint('API CALL: GET $uri');
    final response = await client.get(uri, headers: _headers);
    debugPrint('API RESPONSE: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
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

  @override
  Future<List<PagoRealizado>> getPagosByReserva(int reservaId) async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'reserva_id': reservaId.toString()});
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
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

  @override
  Future<PagoRealizado> getPagoById(int id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    return _fromJson(json.decode(response.body));
  }

  @override
  Future<void> createPago(PagoRealizado pago) async {
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: json.encode(_toJson(pago)),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException.fromResponse(response);
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
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> deletePago(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response);
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
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromResponse(response);
    }
    return _fromJson(json.decode(response.body) as Map<String, dynamic>);
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
      conversationId: json['conversation_id'] is int
          ? json['conversation_id']
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      entidadTipo: json['entidad_tipo']?.toString() ?? 'reserva',
      clienteNombre: json['cliente_nombre']?.toString(),
      clienteIdentificacion: json['cliente_identificacion']?.toString(),
      concepto: json['concepto']?.toString(),
      proveedorId: json['proveedor_id'] is int
          ? json['proveedor_id']
          : int.tryParse(json['proveedor_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> _toJson(PagoRealizado pago) {
    final base = <String, dynamic>{
      'entidad_tipo': pago.entidadTipo,
      'tipo_documento': pago.tipoDocumento,
      'monto': pago.monto,
      'metodo_pago': pago.metodoPago,
      'referencia': pago.referencia,
      'fecha_documento': pago.fechaDocumento,
      'url_imagen': pago.urlImagen,
      'is_validated': pago.isValidated,
      'is_rechazado': pago.isRechazado,
      if (pago.motivoRechazo != null) 'motivo_rechazo': pago.motivoRechazo,
    };

    switch (pago.entidadTipo) {
      case 'reserva':
        return {
          ...base,
          if (pago.reservaId != null) 'reserva_id': pago.reservaId,
          'chat_id': pago.chatId,
          if (pago.clienteNombre?.isNotEmpty == true)
            'cliente_nombre': pago.clienteNombre,
          if (pago.clienteIdentificacion?.isNotEmpty == true)
            'cliente_identificacion': pago.clienteIdentificacion,
          if (pago.conversationId != null) 'conversation_id': pago.conversationId,
        };
      case 'servicio':
        return {
          ...base,
          if (pago.concepto?.isNotEmpty == true) 'concepto': pago.concepto,
          if (pago.clienteNombre?.isNotEmpty == true)
            'cliente_nombre': pago.clienteNombre,
          if (pago.clienteIdentificacion?.isNotEmpty == true)
            'cliente_identificacion': pago.clienteIdentificacion,
        };
      case 'proveedor':
        return {
          ...base,
          if (pago.proveedorId != null) 'proveedor_id': pago.proveedorId,
          if (pago.concepto?.isNotEmpty == true) 'concepto': pago.concepto,
        };
      default:
        return base;
    }
  }
}
