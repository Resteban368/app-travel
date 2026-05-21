import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/proveedor.dart';
import '../../domain/repositories/proveedor_repository.dart';

class ApiProveedorRepository implements ProveedorRepository {
  final http.Client client;

  ApiProveedorRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/proveedores';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Proveedor>> getProveedores({String? search}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'page': '1',
        'limit': '20',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    debugPrint('🌎 [ApiProveedorRepository] GET $uri');
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data = decoded is Map
          ? (decoded['data'] ?? decoded['items'] ?? [])
          : decoded;
      return data
          .map((item) => _fromJson(item as Map<String, dynamic>))
          .toList();
    }
    debugPrint(
      '❌ [ApiProveedorRepository] Error: ${response.statusCode} — ${response.body}',
    );
    throw Exception('Error al cargar proveedores: ${response.statusCode}');
  }

  @override
  Future<Proveedor> createProveedor(Proveedor proveedor) async {
    final body = json.encode(_toJson(proveedor));
    debugPrint('📤 [ApiProveedorRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return _fromJson(data as Map<String, dynamic>);
    }
    debugPrint(
      '❌ [ApiProveedorRepository] Error: ${response.statusCode} — ${response.body}',
    );
    throw Exception('Error al crear proveedor: ${response.statusCode}');
  }

  @override
  Future<Proveedor> updateProveedor(Proveedor proveedor) async {
    final body = json.encode(_toJson(proveedor));
    debugPrint(
      '📤 [ApiProveedorRepository] Updating ID ${proveedor.id}: $body',
    );
    final response = await client.patch(
      Uri.parse('$_baseUrl/${proveedor.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return _fromJson(data as Map<String, dynamic>);
    }
    debugPrint(
      '❌ [ApiProveedorRepository] Error: ${response.statusCode} — ${response.body}',
    );
    throw Exception('Error al actualizar proveedor: ${response.statusCode}');
  }

  @override
  Future<void> deleteProveedor(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      debugPrint(
        '❌ [ApiProveedorRepository] Delete error: ${response.statusCode} — ${response.body}',
      );
      throw Exception('Error al eliminar proveedor: ${response.statusCode}');
    }
  }

  Proveedor _fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int?,
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'otro',
      nit: json['nit']?.toString(),
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      banco: json['banco']?.toString(),
      numeroCuenta: json['numero_cuenta']?.toString(),
      notas: json['notas']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toJson(Proveedor proveedor) {
    return {
      'nombre': proveedor.nombre,
      'tipo': proveedor.tipo,
      if (proveedor.nit != null && proveedor.nit!.isNotEmpty)
        'nit': proveedor.nit,
      if (proveedor.telefono != null && proveedor.telefono!.isNotEmpty)
        'telefono': proveedor.telefono,
      if (proveedor.email != null && proveedor.email!.isNotEmpty)
        'email': proveedor.email,
      if (proveedor.banco != null && proveedor.banco!.isNotEmpty)
        'banco': proveedor.banco,
      if (proveedor.numeroCuenta != null && proveedor.numeroCuenta!.isNotEmpty)
        'numero_cuenta': proveedor.numeroCuenta,
      if (proveedor.notas != null && proveedor.notas!.isNotEmpty)
        'notas': proveedor.notas,
      'is_active': proveedor.isActive,
    };
  }
}
