import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';

class ApiServiceRepository implements ServiceRepository {
  final http.Client client;

  ApiServiceRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/servicios';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Service>> getServices() async {
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Failed to load services: ${response.statusCode}');
  }

  @override
  Future<void> createService(Service service) async {
    final body = json.encode(_toJson(service));
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create service: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateService(Service service) async {
    final body = json.encode(_toJson(service));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${service.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update service: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteService(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete service: ${response.statusCode}');
    }
  }

  Service _fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id_servicio'] as int,
      name: json['nombre_servicio'] ?? '',
      cost: json['costo'] != null
          ? double.tryParse(json['costo'].toString())
          : null,
      description: json['descripcion'] ?? '',
      idSede: json['id_sede'] as int,
      isActive: json['activo'] ?? true,
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }

  Map<String, dynamic> _toJson(Service service) {
    return {
      'nombre_servicio': service.name,
      'costo': service.cost,
      'descripcion': service.description,
      'id_sede': service.idSede,
      'activo': service.isActive,
    };
  }
}
