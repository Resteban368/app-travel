import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/repositories/hotel_repository.dart';

class ApiHotelRepository implements HotelRepository {
  final http.Client client;

  ApiHotelRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/hoteles';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<List<Hotel>> getHoteles() async {
    debugPrint('🌎 [ApiHotelRepository] GET $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> data = decoded is Map ? (decoded['data'] ?? []) : decoded;
      return data.map((item) => _fromJson(item as Map<String, dynamic>)).toList();
    }
    debugPrint('❌ [ApiHotelRepository] Error: ${response.statusCode} — ${response.body}');
    throw Exception('Error al cargar hoteles: ${response.statusCode}');
  }

  @override
  Future<void> createHotel(Hotel hotel) async {
    final body = json.encode(_toJson(hotel));
    debugPrint('📤 [ApiHotelRepository] Creating: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      debugPrint('❌ [ApiHotelRepository] Error: ${response.statusCode} — ${response.body}');
      throw Exception('Error al crear hotel: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateHotel(Hotel hotel) async {
    final body = json.encode(_toJson(hotel));
    debugPrint('📤 [ApiHotelRepository] Updating ID ${hotel.id}: $body');
    final response = await client.patch(
      Uri.parse('$_baseUrl/${hotel.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      debugPrint('❌ [ApiHotelRepository] Error: ${response.statusCode} — ${response.body}');
      throw Exception('Error al actualizar hotel: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteHotel(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      debugPrint('❌ [ApiHotelRepository] Delete error: ${response.statusCode} — ${response.body}');
      throw Exception('Error al eliminar hotel: ${response.statusCode}');
    }
  }

  Hotel _fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as int?,
      nombre: json['nombre'] ?? '',
      ciudad: json['ciudad'] ?? '',
      telefono: json['telefono']?.toString() ?? '',
      direccion: json['direccion'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toJson(Hotel hotel) {
    return {
      'nombre': hotel.nombre,
      'ciudad': hotel.ciudad,
      if (hotel.telefono.isNotEmpty) 'telefono': hotel.telefono,
      if (hotel.direccion.isNotEmpty) 'direccion': hotel.direccion,
      'is_active': hotel.isActive,
    };
  }
}
