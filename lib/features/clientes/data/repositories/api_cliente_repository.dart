import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_historial.dart';
import '../../domain/repositories/cliente_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/features/reservas/domain/entities/reserva.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';

class ApiClienteRepository implements ClienteRepository {
  final http.Client client;

  ApiClienteRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/clientes';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Cliente>> getClientes() async {
    debugPrint('🌎 [ApiClienteRepository] GET $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Handle both paginated { data: [] } and simple list []
      final List<dynamic> data = (decoded is Map)
          ? (decoded['data'] ?? [])
          : decoded;
      return data
          .map((item) => _fromJson(item as Map<String, dynamic>))
          .toList();
    }
    print(
      'Error al cargar clientes: ${response.statusCode} - ${response.body}',
    );
    throw Exception('Error al cargar clientes: ${response.statusCode}');
  }

  @override
  Future<Cliente> getClienteById(int id) async {
    debugPrint('🌎 [ApiClienteRepository] GET $_baseUrl/$id');
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    debugPrint(
      '📥 [ApiClienteRepository] getClienteById status=${response.statusCode} body=${response.body}',
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final Map<String, dynamic> data =
          (decoded is Map && decoded.containsKey('data'))
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;
      return _fromJson(data);
    }
    print('Error al cargar cliente: ${response.statusCode} - ${response.body}');
    throw Exception('Error al cargar cliente: ${response.statusCode}');
  }

  @override
  Future<String?> createCliente(Cliente cliente) async {
    final body = json.encode(_toJson(cliente));
    debugPrint('📤 [ApiClienteRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        return decoded['message'] as String;
      }
      return null;
    } else {
      String errorMessage = 'Error al crear cliente';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}

      print(
        'Error al crear cliente: ${response.statusCode} - ${response.body}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> updateCliente(Cliente cliente) async {
    final body = json.encode(_toJson(cliente));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${cliente.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      print(
        'Error al actualizar cliente: ${response.statusCode} - ${response.body}',
      );
      throw Exception(
        'Error al actualizar cliente: ${response.statusCode} - ${response.body}',
      );
    }
  }

  @override
  Future<void> deleteCliente(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      print(
        'Error al eliminar cliente: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Error al eliminar cliente: ${response.statusCode}');
    }
  }

  @override
  Future<ClienteHistorial> getClienteHistorial(int id) async {
    final url = '${ApiConstants.kBaseUrl}/v1/reservas/cliente/$id';
    debugPrint('🌎 [ApiClienteRepository] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return _parseHistorial(decoded);
    }

    print(
      'Error al cargar historial: ${response.statusCode} - ${response.body}',
    );
    throw Exception('Error al cargar historial: ${response.statusCode}');
  }

  ClienteHistorial _parseHistorial(Map<String, dynamic> json) {
    return ClienteHistorial(
      cliente: _fromJson(json['cliente'] ?? {}),
      totalViajes: json['total_viajes'] ?? 0,
      reservas: (json['reservas'] as List? ?? [])
          .map((r) => _parseReserva(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Reserva _parseReserva(Map<String, dynamic> json) {
    // Basic parsing for Reserva in Historial context
    return Reserva(
      id: json['id']?.toString(),
      idReserva: json['id_reserva']?.toString(),
      tipoReserva: json['tipo_reserva']?.toString() ?? 'tour',
      correo: json['correo'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      valorTotal: double.tryParse(json['valor_total']?.toString() ?? ''),
      saldoPendiente: double.tryParse(json['saldo_pendiente']?.toString() ?? ''),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : DateTime.now(),
      notas: json['notas'] ?? '',
      serviciosIds: const [], // simplified for history
      integrantes: const [], // simplified for history
      tour: json['tour'] != null ? _parseTour(json['tour']) : null,
    );
  }

  Tour? _parseTour(Map<String, dynamic> jsonTour) {
    try {
      return Tour(
        id: jsonTour['id']?.toString() ?? '',
        idTour: int.tryParse(jsonTour['id']?.toString() ?? '0') ?? 0,
        name: jsonTour['nombre'] ?? jsonTour['name'] ?? '',
        agency: jsonTour['agencia'] ?? jsonTour['agency'] ?? '',
        startDate:
            DateTime.tryParse(jsonTour['fecha_inicio'] ?? '') ?? DateTime.now(),
        endDate:
            DateTime.tryParse(jsonTour['fecha_fin'] ?? '') ?? DateTime.now(),
        price: double.tryParse(jsonTour['precio']?.toString() ?? '0') ?? 0.0,
        departurePoint:
            jsonTour['punto_partida'] ?? jsonTour['departurePoint'] ?? '',
        departureTime:
            jsonTour['hora_partida'] ?? jsonTour['departureTime'] ?? '',
        arrival: jsonTour['llegada'] ?? jsonTour['arrival'] ?? '',
        pdfLink: jsonTour['link_pdf'] ?? jsonTour['pdfLink'] ?? '',
        inclusions: List<String>.from(jsonTour['inclusions'] ?? []),
        exclusions: List<String>.from(jsonTour['exclusions'] ?? []),
        itinerary: const [],
        sedeId: jsonTour['sede_id']?.toString(),
        isPromotion: jsonTour['es_promocion'] as bool? ?? false,
        isActive: jsonTour['is_active'] as bool? ?? true,
        isDraft: jsonTour['es_borrador'] as bool? ?? false,
        precioPorPareja: jsonTour['precio_por_pareja'] as bool? ?? false,
        cupos: int.tryParse(jsonTour['cupos']?.toString() ?? ''),
        cuposDisponibles: int.tryParse(
          jsonTour['cupos_disponibles']?.toString() ?? '',
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Cliente _fromJson(Map<String, dynamic> json) {
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
      estado: json['estado'] as bool? ?? true,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toJson(Cliente cliente) {
    return {
      if (cliente.id != null) 'id_cliente': cliente.id,
      'nombre': cliente.nombre,
      if (cliente.correo.isNotEmpty) 'correo': cliente.correo,
      'telefono': cliente.telefono,
      'tipo_documento': cliente.tipoDocumento,
      'documento': cliente.documento,
      if (cliente.fechaNacimiento != null)
        'fecha_nacimiento': cliente.fechaNacimiento!
            .toIso8601String()
            .split('T')
            .first,
      'estado': cliente.estado,
    };
  }
}
