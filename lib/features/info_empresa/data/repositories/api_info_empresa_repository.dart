import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/info_empresa.dart';
import '../../domain/repositories/info_empresa_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiInfoEmpresaRepository implements InfoEmpresaRepository {
  final http.Client client;

  ApiInfoEmpresaRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/info-empresa';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<List<InfoEmpresa>> getInfo() async {
    debugPrint('🌎 [ApiInfoEmpresaRepository] GET request to $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      debugPrint('✅ [ApiInfoEmpresaRepository] Response: ${response.body}');
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    debugPrint('❌ [ApiInfoEmpresaRepository] Error: ${response.statusCode}');
    throw Exception('Failed to load company info: ${response.statusCode}');
  }

  @override
  Future<void> createInfo(InfoEmpresa info) async {
    final body = json.encode(_toJson(info));
    debugPrint('📤 [ApiInfoEmpresaRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      debugPrint('❌ [ApiInfoEmpresaRepository] Error: ${response.statusCode} — ${response.body}');
      throw Exception('Failed to create info: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateInfo(InfoEmpresa info) async {
    final body = json.encode(_toJson(info));
    debugPrint('📤 [ApiInfoEmpresaRepository] Updating ID ${info.id}: $body');
    final response = await client.patch(
      Uri.parse('$_baseUrl/${info.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      debugPrint('❌ [ApiInfoEmpresaRepository] Error: ${response.statusCode}');
      throw Exception('Failed to update info: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteInfo(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete info: ${response.statusCode}');
    }
  }

  @override
  Future<void> syncVectors() async {
    debugPrint('🚀 [ApiInfoEmpresaRepository] POST sync-vectors to $_baseUrl/sync-vectors');
    final response = await client.post(
      Uri.parse('$_baseUrl/sync-vectors'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('❌ [ApiInfoEmpresaRepository] Sync Error: ${response.statusCode}');
      throw Exception('Failed to sync vectors: ${response.statusCode}');
    }
  }

  InfoEmpresa _fromJson(Map<String, dynamic> json) {
    final int id = int.tryParse(
          (json['id_info_empresa'] ?? json['id'] ?? '0').toString(),
        ) ??
        0;

    return InfoEmpresa(
      id: id,
      nombre: json['nombre'] ?? '',
      direccion: json['direccion_sede_principal'] ?? json['direccion'] ?? '',
      mision: json['mision'] ?? '',
      vision: json['vision'] ?? '',
      detalles: json['detalles_empresa'] ?? json['detalles'] ?? '',
      horarioPresencial: json['horario_presencial'] ?? '',
      horarioVirtual: json['horario_virtual'] ?? '',
      redesSociales: (json['redes_sociales'] as List? ?? [])
          .map((r) => RedSocial.fromJson(r))
          .toList(),
      nombreGerente: json['nombre_gerente'] ?? '',
      telefono: json['telefono'] ?? '',
      correo: json['correo'] ?? '',
      sitioWeb: json['pagina_web'] ?? json['sitio_web'] ?? '',
    );
  }

  Map<String, dynamic> _toJson(InfoEmpresa info) {
    final map = <String, dynamic>{
      'nombre': info.nombre,
      'direccion_sede_principal': info.direccion,
      'mision': info.mision,
      'vision': info.vision,
      'detalles_empresa': info.detalles,
      'horario_presencial': info.horarioPresencial,
      'horario_virtual': info.horarioVirtual,
      'redes_sociales': info.redesSociales.map((r) => r.toJson()).toList(),
      'nombre_gerente': info.nombreGerente,
      'telefono': info.telefono,
      'correo': info.correo,
    };
    if (info.sitioWeb.isNotEmpty) map['pagina_web'] = info.sitioWeb;
    return map;
  }
}
