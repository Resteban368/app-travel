import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/pago_realizado.dart';
import '../../domain/repositories/pago_realizado_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiPagoRealizadoRepository implements PagoRealizadoRepository {
  final http.Client client;

  ApiPagoRealizadoRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/pagos-realizados';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<PagoRealizado>> getPagos({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var url = _baseUrl;
    if (startDate != null && endDate != null) {
      final startStr = startDate.toUtc().toIso8601String();
      final endStr = endDate.toUtc().toIso8601String();
      url = '$_baseUrl?startDate=$startStr&endDate=$endStr';
    }

    debugPrint('API CALL: GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);
    debugPrint('API RESPONSE: ${response.statusCode}');
    debugPrint('API BODY: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Error loading payments: ${response.statusCode}');
  }

  @override
  Future<List<PagoRealizado>> getPagosByReserva(int reservaId) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {'reserva_id': reservaId.toString()});
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => _fromJson(j)).toList();
    }
    throw Exception('Error al cargar pagos de la reserva: ${response.statusCode}');
  }

  @override
  Future<PagoRealizado> getPagoById(int id) async {
    final response = await client.get(Uri.parse('$_baseUrl/$id'), headers: _headers);
    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
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
      throw Exception('Error deleting payment: ${response.statusCode}');
    }
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
      isValidated: json['is_validated'] ?? false,
      urlImagen: json['url_imagen'] ?? '',
      reservaId: json['reserva_id'] is int ? json['reserva_id'] : int.tryParse(json['reserva_id']?.toString() ?? ''),
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
      'nit': pago.nit,
      'metodo_pago': pago.metodoPago,
      'referencia': pago.referencia,
      'fecha_documento': pago.fechaDocumento,
      'is_validated': pago.isValidated,
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
