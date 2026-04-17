import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/reserva.dart';
import '../../domain/entities/integrante.dart';
import '../../domain/entities/aerolinea.dart';
import '../../domain/entities/vuelo_reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/models/paged_result.dart';

class ApiReservaRepository implements ReservaRepository {
  final http.Client client;

  ApiReservaRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/reservas';
  static String get _aerolineasUrl => '${ApiConstants.kBaseUrl}/v1/aerolineas';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<PagedResult<Reserva>> getReservas({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    debugPrint('🌎 [ApiReservaRepository] GET request to $_baseUrl');

    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();
    if (status != null && status.isNotEmpty) params['estado'] = status;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    try {
      final response = await client.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as List<dynamic>)
            .map((item) => _fromJson(item as Map<String, dynamic>))
            .toList();
        return PagedResult(
          data: data,
          total: (body['total'] as num?)?.toInt() ?? data.length,
          totalPages: (body['totalPages'] as num?)?.toInt() ?? 1,
          page: (body['page'] as num?)?.toInt() ?? page,
          limit: (body['limit'] as num?)?.toInt() ?? limit,
        );
      } else {
        debugPrint('❌ [ApiReservaRepository] Error: ${response.statusCode}');
        return PagedResult(
          data: const [],
          total: 0,
          totalPages: 1,
          page: 1,
          limit: limit,
        );
      }
    } catch (e) {
      debugPrint('❌ [ApiReservaRepository] Exception: $e');
      throw Exception('Error al conectar con la API de reservas');
    }
  }

  @override
  Future<Reserva> getReservaById(String id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
    throw Exception(
      'Error al cargar detalle de reserva: ${response.statusCode}',
    );
  }

  @override
  Future<void> createReserva(Reserva reserva) async {
    final Map<String, dynamic> bodyMap = {
      'tipo_reserva': reserva.tipoReserva,
      'correo': reserva.correo,
      'id_responsable': reserva.idResponsable,
      'estado': reserva.estado,
      'servicios_ids': reserva.serviciosIds,
      'integrantes': _serializeIntegrantes(reserva.integrantes),
    };

    if (reserva.tipoReserva == 'tour') {
      bodyMap['id_tour'] = int.tryParse(reserva.idTour ?? '') ?? 0;
    } else {
      bodyMap['valor_total'] = reserva.valorTotal ?? 0;
    }

    if (reserva.vuelos.isNotEmpty) {
      bodyMap['vuelos'] = _serializeVuelos(reserva.vuelos);
    }

    final body = json.encode(bodyMap);
    debugPrint('📤 [ApiReservaRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Error al crear reserva: ${response.statusCode} - ${response.body}',
      );
    }
  }

  @override
  Future<void> updateReserva(Reserva reserva) async {
    final Map<String, dynamic> bodyMap = {
      'tipo_reserva': reserva.tipoReserva,
      'correo': reserva.correo,
      'id_responsable': reserva.idResponsable,
      'estado': reserva.estado,
      'notas': reserva.notas,
      'servicios_ids': reserva.serviciosIds,
      'integrantes': _serializeIntegrantes(reserva.integrantes),
    };

    if (reserva.tipoReserva == 'tour') {
      bodyMap['id_tour'] = int.tryParse(reserva.idTour ?? '') ?? 0;
    } else {
      if (reserva.valorTotal != null) {
        bodyMap['valor_total'] = reserva.valorTotal;
      }
    }

    if (reserva.vuelos.isNotEmpty) {
      bodyMap['vuelos'] = _serializeVuelos(reserva.vuelos);
    }

    final body = json.encode(bodyMap);
    debugPrint('📤 [ApiReservaRepository] Updating: $body');
    final response = await client.patch(
      Uri.parse('$_baseUrl/${reserva.id}'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al actualizar reserva: ${response.statusCode} - ${response.body}',
      );
    }
  }

  @override
  Future<List<Aerolinea>> getAerolineas() async {
    debugPrint('🌎 [ApiReservaRepository] GET $_aerolineasUrl');
    try {
      final response = await client.get(
        Uri.parse(_aerolineasUrl),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data
            .map((item) => _parseAerolinea(item as Map<String, dynamic>))
            .toList();
      }
      debugPrint(
        '❌ [ApiReservaRepository] getAerolineas error: ${response.statusCode}',
      );
      return [];
    } catch (e) {
      debugPrint('❌ [ApiReservaRepository] getAerolineas exception: $e');
      return [];
    }
  }

  // ─── Serializers ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _serializeIntegrantes(List<Integrante> list) {
    return list
        .map(
          (i) => {
            'nombre': i.nombre,
            'telefono': i.telefono,
            if (i.fechaNacimiento != null)
              'fecha_nacimiento': i.fechaNacimiento!
                  .toIso8601String()
                  .split('T')
                  .first,
            'tipo_documento': i.tipoDocumento,
            'documento': i.documento,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _serializeVuelos(List<VueloReserva> list) {
    return list
        .map(
          (v) => {
            'aerolinea_id': v.aerolineaId ?? v.aerolinea?.id,
            'numero_vuelo': v.numeroVuelo,
            'origen': v.origen,
            'destino': v.destino,
            'fecha_salida': v.fechaSalida,
            'fecha_llegada': v.fechaLlegada,
            'hora_salida': v.horaSalida,
            'hora_llegada': v.horaLlegada,
            'clase': v.clase,
            'precio': v.precio,
          },
        )
        .toList();
  }

  // ─── Parsers ──────────────────────────────────────────────────────────────

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
          fechaNacimiento: i['fecha_nacimiento'] != null
              ? DateTime.tryParse(i['fecha_nacimiento'])
              : null,
          esResponsable: isRes,
          tipoDocumento: i['tipo_documento'] ?? 'cedula',
          documento: i['documento']?.toString() ?? '',
        );
      }).toList();
    }

    // Parse servicios adicionales
    List<int> serviciosIds = [];
    if (json['servicios_adicionales'] != null &&
        json['servicios_adicionales'] is List) {
      serviciosIds = (json['servicios_adicionales'] as List)
          .map((s) {
            if (s is int) return s;
            if (s is Map) {
              return int.tryParse(s['id_servicio']?.toString() ?? '') ?? 0;
            }
            return 0;
          })
          .where((id) => id != 0)
          .cast<int>()
          .toList();
    }

    // Parse vuelos
    List<VueloReserva> vuelos = [];
    if (json['vuelos'] != null && json['vuelos'] is List) {
      vuelos = (json['vuelos'] as List)
          .map((v) => _parseVuelo(v as Map<String, dynamic>))
          .toList();
    }

    // Identify Tour ID
    String? tempIdTour;
    if (json['tour'] is Map && json['tour']['id'] != null) {
      tempIdTour = json['tour']['id'].toString();
    }

    // Parse responsable
    Cliente? parsedResponsable;
    int? idResponsable = int.tryParse(json['id_responsable']?.toString() ?? '');

    final responsableJson = json['responsable'] ?? json['cliente'];
    if (responsableJson is Map<String, dynamic>) {
      idResponsable ??= int.tryParse(
        (responsableJson['id_cliente'] ?? responsableJson['id'] ?? '')
            .toString(),
      );
      parsedResponsable = _parseCliente(responsableJson);
    }

    debugPrint(
      '📦 [ApiReservaRepository] _fromJson id=${json['id']} id_responsable=$idResponsable responsable=${parsedResponsable?.nombre}',
    );
    return Reserva(
      id: json['id']?.toString(),
      idReserva: json['id_reserva']?.toString(),
      tipoReserva: json['tipo_reserva']?.toString() ?? 'tour',
      correo: json['correo'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      valorTotal: double.tryParse(json['valor_total']?.toString() ?? ''),
      saldoPendiente: double.tryParse(
        json['saldo_pendiente']?.toString() ?? '',
      ),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : DateTime.now(),
      notas: json['notas'] ?? '',
      serviciosIds: serviciosIds,
      integrantes: integrantes,
      vuelos: vuelos,
      idResponsable: idResponsable,
      idTour: json['id_tour']?.toString() ?? tempIdTour,
      tour: json['tour'] != null ? _parseTour(json['tour']) : null,
      responsable: parsedResponsable,
    );
  }

  VueloReserva _parseVuelo(Map<String, dynamic> json) {
    Aerolinea? aerolinea;
    if (json['aerolinea'] is Map<String, dynamic>) {
      aerolinea = _parseAerolinea(json['aerolinea'] as Map<String, dynamic>);
    }
    return VueloReserva(
      id: int.tryParse(json['id']?.toString() ?? ''),
      aerolinea: aerolinea,
      aerolineaId: aerolinea?.id,
      numeroVuelo: json['numero_vuelo']?.toString() ?? '',
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      fechaSalida: json['fecha_salida']?.toString() ?? '',
      fechaLlegada: json['fecha_llegada']?.toString() ?? '',
      horaSalida: json['hora_salida']?.toString() ?? '',
      horaLlegada: json['hora_llegada']?.toString() ?? '',
      clase: json['clase']?.toString() ?? 'economy',
      precio: double.tryParse(json['precio']?.toString() ?? ''),
    );
  }

  Aerolinea _parseAerolinea(Map<String, dynamic> json) {
    return Aerolinea(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigoIata: json['codigo_iata']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      pais: json['pais']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Tour? _parseTour(Map<String, dynamic> jsonTour) {
    try {
      return Tour(
        id: jsonTour['id']?.toString() ?? '',
        idTour: int.tryParse(jsonTour['id']?.toString() ?? '0') ?? 0,
        name: jsonTour['nombre'] ?? jsonTour['name'] ?? '',
        agency: jsonTour['agency'] ?? '',
        startDate:
            DateTime.tryParse(jsonTour['fecha_inicio'] ?? '') ?? DateTime.now(),
        endDate:
            DateTime.tryParse(jsonTour['fecha_fin'] ?? '') ?? DateTime.now(),
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

  Cliente? _parseCliente(Map<String, dynamic> json) {
    try {
      return Cliente(
        id: int.tryParse((json['id_cliente'] ?? json['id'] ?? '').toString()),
        nombre: json['nombre'] ?? '',
        correo: json['correo'] ?? json['email'] ?? '',
        telefono: json['telefono']?.toString() ?? '',
        tipoDocumento: json['tipo_documento'] ?? 'CC',
        documento: json['documento']?.toString() ?? '',
        fechaNacimiento: json['fecha_nacimiento'] != null
            ? DateTime.tryParse(json['fecha_nacimiento'].toString())
            : null,
      );
    } catch (e) {
      return null;
    }
  }
}
