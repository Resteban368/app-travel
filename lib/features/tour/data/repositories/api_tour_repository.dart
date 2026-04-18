import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_detalle.dart';
import '../../domain/repositories/tour_repository.dart';

class ApiTourRepository implements TourRepository {
  final http.Client client;

  ApiTourRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/tours';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Tour>> getTours() async {
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Failed to load tours: ${response.statusCode}');
  }

  @override
  Future<Tour> getTourById(String id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return _fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load tour: ${response.statusCode}');
  }

  @override
  Future<void> createTour(Tour tour) async {
    final body = json.encode(_toJson(tour));
    debugPrint('📤 [ApiTourRepository] Creating tour: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create tour: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateTour(Tour tour) async {
    final body = json.encode(_toJson(tour));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${tour.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update tour: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteTour(String id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete tour: ${response.statusCode}');
    }
  }

  @override
  Future<TourDetalle> getTourDetalle(String id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id/detalle'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return TourDetalle.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load tour detalle: ${response.statusCode}');
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'is_active': isActive}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle tour active: ${response.statusCode}');
    }
  }

  Tour _fromJson(Map<String, dynamic> json) {
    return Tour(
      id: (json['id'] ?? '').toString(),
      idTour: int.tryParse(json['id_tour']?.toString() ?? '0') ?? 0,
      name: json['nombre_tour'] ?? '',
      agency: json['agencia'] ?? '',
      startDate: DateTime.parse(json['fecha_inicio']),
      endDate: DateTime.parse(json['fecha_fin']),
      price: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      departurePoint: json['punto_partida'] ?? '',
      departureTime: json['hora_partida'] ?? '',
      arrival: json['llegada'] ?? '',
      pdfLink: json['link_pdf'] ?? '',
      inclusions: List<String>.from(json['inclusions'] ?? []),
      exclusions: List<String>.from(json['exclusions'] ?? []),
      itinerary: (json['itinerary'] as List? ?? [])
          .map(
            (i) => ItineraryDay(
              dayNumber: i['dia_numero'] ?? 0,
              title: i['titulo'] ?? '',
              description: i['descripcion'] ?? '',
            ),
          )
          .toList(),
      imageUrl: json['url_imagen'] ?? '',
      sedeId: json['sede_id']?.toString(),
      isPromotion: json['es_promocion'] ?? false,
      isActive: json['is_active'] ?? true,
      isDraft: json['es_borrador'] ?? false,
      precioPorPareja: json['precio_por_pareja'] ?? false,
      cupos: json['cupos'] != null ? int.tryParse(json['cupos'].toString()) : null,
      cuposDisponibles: json['cupos_disponibles'] != null
          ? int.tryParse(json['cupos_disponibles'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toJson(Tour tour) {
    return {
      'id_tour': tour.idTour,
      'nombre_tour': tour.name,
      'agencia': tour.agency,
      'fecha_inicio': tour.startDate.toIso8601String(),
      'fecha_fin': tour.endDate.toIso8601String(),
      'precio': tour.price,
      'punto_partida': tour.departurePoint,
      'hora_partida': tour.departureTime,
      'llegada': tour.arrival,
      'link_pdf': tour.pdfLink,
      'inclusions': tour.inclusions,
      'exclusions': tour.exclusions,
      'itinerary': tour.itinerary
          .map(
            (i) => {
              'dia_numero': i.dayNumber,
              'titulo': i.title,
              'descripcion': i.description,
            },
          )
          .toList(),
      'url_imagen': tour.imageUrl,
      'sede_id': tour.sedeId,
      'es_promocion': tour.isPromotion,
      'is_active': tour.isActive,
      'es_borrador': tour.isDraft,
      'precio_por_pareja': tour.precioPorPareja,
      if (tour.cupos != null) 'cupos': tour.cupos,
    };
  }
}
