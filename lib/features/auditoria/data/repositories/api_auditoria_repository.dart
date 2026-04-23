import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/sesion_usuario.dart';
import '../../domain/entities/auditoria_general.dart';
import '../../domain/repositories/auditoria_repository.dart';

class ApiAuditoriaRepository implements AuditoriaRepository {
  final http.Client client;

  const ApiAuditoriaRepository({required this.client});

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  @override
  Future<List<SesionUsuario>> getSesiones({DateTime? fecha}) async {
    final base = '${ApiConstants.kBaseUrl}/v1/auth/sesiones';
    final uri = fecha != null
        ? Uri.parse(base).replace(
            queryParameters: {
              'fecha':
                  '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
            },
          )
        : Uri.parse(base);

    debugPrint('🌎 [ApiAuditoriaRepository] GET $uri');
    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data;
      
      if (decoded is Map<String, dynamic>) {
        data = decoded['data'] as List? ?? (decoded.values.firstWhere((v) => v is List, orElse: () => []) as List);
      } else if (decoded is List) {
        data = decoded;
      } else {
        data = [];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(SesionUsuario.fromJson)
          .toList();
    }
    throw Exception('Error al cargar sesiones: ${response.statusCode}');
  }

  @override
  Future<List<AuditoriaGeneral>> getAuditoriaGeneral() async {
    final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/auditoria-general');

    debugPrint('🌎 [ApiAuditoriaRepository] GET $uri');
    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> data = body['data'] as List? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(AuditoriaGeneral.fromJson)
          .toList();
    }
    throw Exception(
        'Error al cargar auditoría general: ${response.statusCode}');
  }
}
