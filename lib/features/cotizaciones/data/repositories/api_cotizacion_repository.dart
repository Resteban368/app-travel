import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/cotizacion.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiCotizacionRepository implements CotizacionRepository {
  final http.Client client;

  ApiCotizacionRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/cotizaciones';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<List<Cotizacion>> getCotizaciones() async {
    debugPrint('API CALL: GET $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Error al cargar cotizaciones: ${response.statusCode}');
  }

  @override
  Future<void> markAsRead(int id) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'is_read': true}),
    );

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Error al marcar como leída: ${response.statusCode}');
    }
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
      estado: json['estado'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
