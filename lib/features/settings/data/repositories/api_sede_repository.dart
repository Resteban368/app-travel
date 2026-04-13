import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/sede.dart';
import '../../domain/repositories/sede_repository.dart';

/// API implementation that fetches sedes from the remote API.
class ApiSedeRepository implements SedeRepository {
  final http.Client client;

  ApiSedeRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/sedes';

  @override
  Future<List<Sede>> getSedes() async {
    debugPrint('🌎 [ApiSedeRepository] Fetching sedes from $_baseUrl...');
    final response = await client.get(Uri.parse(_baseUrl));
    if (response.statusCode != 200) {
      debugPrint('❌ [ApiSedeRepository] Error: ${response.statusCode}');
      throw Exception('Error al cargar sedes: ${response.statusCode}');
    }
    debugPrint('✅ [ApiSedeRepository] Response body: ${response.body}');
    final List<dynamic> jsonList = json.decode(response.body);
    final list = jsonList.map((json) => _fromJson(json)).toList();
    debugPrint(
      '✅ [ApiSedeRepository] Parsed ${list.length} sedes successfully.',
    );
    return list;
  }

  @override
  Future<void> createSede(Sede sede) async {
    final body = json.encode(_toJson(sede));
    debugPrint('🌎 [ApiSedeRepository] POST request to $_baseUrl');
    debugPrint('📦 [ApiSedeRepository] Request body: $body');

    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ [ApiSedeRepository] Sede created successfully.');
    } else {
      debugPrint('❌ [ApiSedeRepository] Error code: ${response.statusCode}');
      debugPrint('📄 [ApiSedeRepository] Response body: ${response.body}');
      throw Exception('Error al crear sede: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateSede(Sede sede) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/${sede.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: json.encode(_toJson(sede)),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al actualizar sede: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteSede(String id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar sede: ${response.statusCode}');
    }
  }

  /// Maps API JSON to Sede entity.
  Sede _fromJson(Map<String, dynamic> json) {
    // some endpoints use idSede and others id_sede
    final idValue = json['id_sede'] ?? json['idSede'] ?? '0';
    return Sede(
      id: idValue.toString(),
      nombreSede: json['nombre_sede'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      linkMap: json['link_map'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  /// Maps Sede entity to API JSON format.
  Map<String, dynamic> _toJson(Sede sede) {
    return {
      'nombre_sede': sede.nombreSede,
      'direccion': sede.direccion,
      'telefono': sede.telefono,
      'link_map': sede.linkMap,
      'is_active': sede.isActive,
    };
  }
}
