import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/politica_reserva.dart';
import '../../domain/repositories/politica_reserva_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiPoliticaReservaRepository implements PoliticaReservaRepository {
  final http.Client client;

  ApiPoliticaReservaRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/politicas-reserva';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<List<PoliticaReserva>> getPoliticas() async {
    debugPrint('🌎 [ApiPoliticaReservaRepository] GET request to $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      debugPrint('✅ [ApiPoliticaReservaRepository] Response: ${response.body}');
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    debugPrint('❌ [ApiPoliticaReservaRepository] Error: ${response.statusCode} - ${response.body}');
    throw Exception('Failed to load policies: ${response.statusCode}');
  }

  @override
  Future<void> createPolitica(PoliticaReserva politica) async {
    final body = json.encode(_toJson(politica));
    debugPrint('📤 [ApiPoliticaReservaRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      debugPrint('❌ [ApiPoliticaReservaRepository] Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create policy: ${response.statusCode}');
    }
  }

  @override
  Future<void> updatePolitica(PoliticaReserva politica) async {
    final body = json.encode(_toJson(politica));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${politica.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update policy: ${response.statusCode}');
    }
  }

  @override
  Future<void> deletePolitica(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete policy: ${response.statusCode}');
    }
  }

  PoliticaReserva _fromJson(Map<String, dynamic> json) {
    // Attempt to find the ID in common field names used in this project
    final int id = int.tryParse(
          (json['id_politica_reserva'] ??
                  json['id_politica'] ??
                  json['id'] ??
                  '0')
              .toString(),
        ) ??
        0;

    return PoliticaReserva(
      id: id,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      tipoPolitica: json['tipo_politica'] ?? '',
      activo: json['activo'] ?? true,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }

  Map<String, dynamic> _toJson(PoliticaReserva politica) {
    return {
      'titulo': politica.titulo,
      'descripcion': politica.descripcion,
      'tipo_politica': politica.tipoPolitica,
      'activo': politica.activo,
    };
  }
}
