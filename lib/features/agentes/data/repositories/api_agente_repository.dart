import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/agente.dart';
import '../../domain/repositories/agente_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiAgenteRepository implements AgenteRepository {
  final http.Client client;

  ApiAgenteRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/agentes';

  // Mapa estático: clave del módulo → id en la BD
  static const Map<String, int> _moduloIds = {
    'dashboard': 14,
    'tours': 15,
    'sedes': 13,
    'paymentMethods': 16,
    'catalogues': 17,
    'faqs': 18,
    'services': 19,
    'politicasReserva': 20,
    'infoEmpresa': 21,
    'pagosRealizados': 22,
    'agentes': 23,
    'reservas': 24,
    'cotizacion': 12,
    'clientes': 25,
  };

  /// Convierte Map<moduloKey, nivel> → lista de objetos que espera el API
  List<Map<String, dynamic>> _permisosToApi(Map<String, String> permisos) {
    return permisos.entries
        .where((e) => _moduloIds.containsKey(e.key))
        .map((e) => {'modulo_id': _moduloIds[e.key], 'tipo_permiso': e.value})
        .toList();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Agente>> getAgentes() async {
    debugPrint('🌎 [ApiAgenteRepository] GET request to $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Error al cargar agentes: ${response.statusCode}');
  }

  @override
  Future<Agente> getAgenteById(int id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
    throw Exception(
      'Error al cargar detalle del agente: ${response.statusCode}',
    );
  }

  @override
  Future<void> createAgente(Agente agente) async {
    final body = json.encode({
      'nombre': agente.nombre,
      'email': agente.correo,
      'password': agente.password,
      'permisos': _permisosToApi(agente.permisos),
    });
    debugPrint('📤 [ApiAgenteRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear agente: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateAgente(Agente agente) async {
    final body = json.encode({
      'nombre': agente.nombre,
      'email': agente.correo,
      if (agente.password != null && agente.password!.isNotEmpty)
        'password': agente.password,
      'permisos': _permisosToApi(agente.permisos),
      'is_active': agente.isActive,
    });
    final response = await client.patch(
      Uri.parse('$_baseUrl/${agente.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar agente: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteAgente(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar agente: ${response.statusCode}');
    }
  }

  Agente _fromJson(Map<String, dynamic> json) {
    final permisosRaw = (json['permisos'] as Map<String, dynamic>?) ?? {};
    return Agente(
      id: int.tryParse(json['id_usuario']?.toString() ?? '0') ?? 0,
      nombre: json['nombre'] ?? '',
      correo: json['email'] ?? '',
      permisos: permisosRaw.map((k, v) => MapEntry(k, v.toString())),
      isActive: json['is_active'] ?? true,
    );
  }
}
