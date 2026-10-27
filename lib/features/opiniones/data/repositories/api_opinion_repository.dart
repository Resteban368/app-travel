import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/opinion.dart';
import '../../domain/repositories/opinion_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiOpinionRepository implements OpinionRepository {
  final http.Client client;

  ApiOpinionRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/opiniones';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Opinion>> getOpiniones() async {
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Failed to load opiniones: ${response.statusCode}');
  }

  @override
  Future<void> setAprobada(int id, bool aprobada) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'aprobada': aprobada}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update opinion: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteOpinion(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete opinion: ${response.statusCode}');
    }
  }

  Opinion _fromJson(Map<String, dynamic> json) {
    return Opinion(
      id: json['id_opinion'] as int,
      nombre: json['nombre'] ?? '',
      plan: json['plan'],
      texto: json['texto'] ?? '',
      calificacion: json['estrellas'] ?? 5,
      aprobada: json['aprobada'] ?? false,
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }
}
