import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/reserva.dart';
import '../../domain/entities/integrante.dart';
import '../../domain/repositories/reserva_repository.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiReservaRepository implements ReservaRepository {
  final http.Client client;

  ApiReservaRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/reservas';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<List<Reserva>> getReservas({DateTime? startDate, DateTime? endDate, String? status}) async {
    debugPrint('🌎 [ApiReservaRepository] GET request to $_baseUrl');
    
    // Contruyendo los query parameters
    final Map<String, String> params = {};
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();
    if (status != null && status.isNotEmpty) params['estado'] = status;

    Uri uri = Uri.parse(_baseUrl);
    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }

    try {
      final response = await client.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => _fromJson(item)).toList();
      } else {
        debugPrint('❌ [ApiReservaRepository] Error: ${response.statusCode}');
        // As a fallback for UI testing if the backend is not yet ready, we could return empty list
        // returning an empty list instead of throwing an exact error to let UI render properly.
        return [];
      }
    } catch (e) {
       debugPrint('❌ [ApiReservaRepository] Exception: $e');
       throw Exception('Error al conectar con la API de reservas');
    }
  }

  @override
  Future<Reserva> getReservaById(String id) async {
    final response = await client.get(Uri.parse('$_baseUrl/$id'), headers: _headers);
    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
    throw Exception('Error al cargar detalle de reserva: ${response.statusCode}');
  }

  @override
  Future<void> createReserva(Reserva reserva) async {
    final body = json.encode(_toJson(reserva));
    debugPrint('📤 [ApiReservaRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear reserva: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Future<void> updateReserva(Reserva reserva) async {
    final body = json.encode(_toJson(reserva));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${reserva.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar reserva: ${response.statusCode} - ${response.body}');
    }
  }

  Reserva _fromJson(Map<String, dynamic> json) {
    // Parse integrantes
    List<Integrante> integrantes = [];
    if (json['integrantes'] != null && json['integrantes'] is List) {
      int idx = 0;
      integrantes = (json['integrantes'] as List).map((i) {
        final isRes = i['es_responsable'] ?? (idx == 0);
        idx++;
        return Integrante(
          nombre: i['nombre'] ?? '',
          telefono: i['telefono']?.toString() ?? '',
          fechaNacimiento: i['fecha_nacimiento'] != null ? DateTime.tryParse(i['fecha_nacimiento']) : null,
          esResponsable: isRes,
        );
      }).toList();
    }

    // Parse servicios adicionales
    List<int> serviciosIds = [];
    if (json['servicios_adicionales'] != null && json['servicios_adicionales'] is List) {
      serviciosIds = (json['servicios_adicionales'] as List).map((s) {
        if (s is int) return s;
        if (s is Map) return int.tryParse(s['id_servicio']?.toString() ?? '') ?? 0;
        return 0;
      }).where((id) => id != 0).cast<int>().toList();
    }

    // Identify Tour ID
    String tempIdTour = '';
    if (json['tour'] is Map && json['tour']['id'] != null) {
      tempIdTour = json['tour']['id'].toString();
    }

    return Reserva(
      id: json['id']?.toString(),
      idReserva: json['id_reserva']?.toString(),
      correo: json['correo'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      valorTotal: double.tryParse(json['valor_total']?.toString() ?? ''),
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.parse(json['fecha_creacion']) : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null ? DateTime.parse(json['fecha_actualizacion']) : DateTime.now(),
      notas: json['notas'] ?? '',
      serviciosIds: serviciosIds,
      integrantes: integrantes,
      responsableNombre: json['responsable_nombre'],
      responsableTelefono: json['responsable_telefono']?.toString(),
      responsableCedula: json['responsable_cedula']?.toString(),
      responsableFechaNacimiento: json['responsable_fecha_nacimiento'] != null
          ? DateTime.tryParse(json['responsable_fecha_nacimiento'])
          : null,
      idTour: json['id_tour']?.toString() ?? tempIdTour,
      tour: json['tour'] != null ? _parseTour(json['tour']) : null,
    );
  }

  Map<String, dynamic> _toJson(Reserva reserva) {
    return {
      'id_tour': int.tryParse(reserva.idTour) ?? 0,
      'correo': reserva.correo,
      'estado': reserva.estado,
      'notas': reserva.notas,
      'servicios_ids': reserva.serviciosIds,
      'integrantes': reserva.integrantes.map((i) => {
        'nombre': i.nombre,
        'telefono': i.telefono,
        'fecha_nacimiento': i.fechaNacimiento?.toIso8601String(),
        'es_responsable': i.esResponsable,
      }).toList(),
      if (reserva.responsableNombre != null) 'responsable_nombre': reserva.responsableNombre,
      if (reserva.responsableTelefono != null) 'responsable_telefono': reserva.responsableTelefono,
      if (reserva.responsableCedula != null) 'responsable_cedula': reserva.responsableCedula,
      if (reserva.responsableFechaNacimiento != null)
        'responsable_fecha_nacimiento': reserva.responsableFechaNacimiento!.toIso8601String(),
    };
  }

  Tour? _parseTour(Map<String, dynamic> jsonTour) {
    try {
      return Tour(
        id: jsonTour['id']?.toString() ?? '',
        idTour: int.tryParse(jsonTour['id']?.toString() ?? '0') ?? 0,
        name: jsonTour['nombre'] ?? jsonTour['name'] ?? '',
        agency: jsonTour['agency'] ?? '',
        startDate: DateTime.tryParse(jsonTour['fecha_inicio'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(jsonTour['fecha_fin'] ?? '') ?? DateTime.now(),
        price: double.tryParse(jsonTour['precio']?.toString() ?? '0') ?? 0.0,
        departurePoint: jsonTour['departurePoint'] ?? '',
        departureTime: jsonTour['departureTime'] ?? '',
        arrival: jsonTour['arrival'] ?? '',
        pdfLink: jsonTour['pdfLink'] ?? '',
        inclusions: [],
        exclusions: [],
        itinerary: [],
        imageUrl: jsonTour['imageUrl'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }
}
