import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

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
  Future<void> createCliente(Cliente cliente) async {
    final body = json.encode(_toJson(cliente));
    debugPrint('📤 [ApiClienteRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print(
        'Error al crear cliente: ${response.statusCode} - ${response.body}',
      );
      throw Exception(
        'Error al crear cliente: ${response.statusCode} - ${response.body}',
      );
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
      notas: json['notas'] ?? '',
    );
  }

  Map<String, dynamic> _toJson(Cliente cliente) {
    return {
      if (cliente.id != null) 'id_cliente': cliente.id,
      'nombre': cliente.nombre,
      'correo': cliente.correo,
      'telefono': cliente.telefono,
      'tipo_documento': cliente.tipoDocumento,
      'documento': cliente.documento,
      if (cliente.fechaNacimiento != null)
        'fecha_nacimiento': cliente.fechaNacimiento!
            .toIso8601String()
            .split('T')
            .first,
      'notas': cliente.notas,
    };
  }
}
