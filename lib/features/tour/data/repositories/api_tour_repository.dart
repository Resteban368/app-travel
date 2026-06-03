import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/network/api_exception.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_detalle.dart';
import '../../domain/entities/tour_precio.dart';
import '../../domain/entities/precio_grupal.dart';
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
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => _fromJson(item)).toList();
  }

  @override
  Future<List<Tour>> getToursHistoricos() async {
    final url = '$_baseUrl/historico';
    debugPrint('📤 [Historico] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);
    debugPrint(
      '📥 [Historico] status=${response.statusCode} body=${response.body}',
    );
    if (response.statusCode != 200) {
      final ex = ApiException.fromResponse(response);
      throw ApiException(
        message: '[${response.statusCode}] ${ex.message}\nURL: $url',
        statusCode: ex.statusCode,
      );
    }
    final decoded = json.decode(response.body);
    final List<dynamic> data = decoded is List
        ? decoded
        : (decoded['data'] ?? decoded['tours'] ?? decoded['items'] ?? []);
    return data.map((item) => _fromJson(item)).toList();
  }

  @override
  Future<Tour> getTourById(String id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    return _fromJson(json.decode(response.body));
  }

  @override
  Future<void> createTour(Tour tour) async {
    final payload = _toJson(tour);
    if (tour.modoPrecio == 'grupal') {
      payload['precios_grupales'] =
          tour.preciosGrupales.map((p) => p.toJson()).toList();
    } else {
      payload['precios'] = tour.precios.map((p) => p.toJson()).toList();
    }
    final body = json.encode(payload);
    debugPrint('📤 [ApiTourRepository] Creating tour: $body');
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> updateTour(Tour tour, {List<TourPrecio>? preciosPayload}) async {
    final payload = _toJson(tour);
    if (tour.modoPrecio == 'grupal') {
      payload['precios_grupales'] =
          tour.preciosGrupales.map((p) => p.toJson()).toList();
    } else if (preciosPayload != null) {
      payload['precios'] = preciosPayload.map((p) => p.toJson()).toList();
    }
    final body = json.encode(payload);
    final response = await client.patch(
      Uri.parse('$_baseUrl/${tour.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> deleteTour(String id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<TourDetalle> getTourDetalle(String id) async {
    final response = await client.get(
      Uri.parse('$_baseUrl/$id/detalle'),
      headers: _headers,
    );
    print('$_baseUrl/$id/detalle');
    print('Respuesta $_baseUrl/$id/detalle ${response.body}');
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    return TourDetalle.fromJson(json.decode(response.body));
  }

  @override
  Future<void> toggleActive(String id, bool isActive) async {
    final response = await client.patch(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: json.encode({'is_active': isActive}),
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> finalizarTour(String id) async {
    final url = '$_baseUrl/$id/finalizar';
    debugPrint('📤 [ApiTourRepository] PATCH $url');
    final response = await client.patch(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> duplicarTour(String id) async {
    final url = '$_baseUrl/$id/duplicar';
    debugPrint('📤 [ApiTourRepository] POST $url');
    final response = await client.post(Uri.parse(url), headers: _headers);
    debugPrint('📥 [ApiTourRepository] ${response.statusCode} $url → ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromResponse(response);
    }
  }

  Tour _fromJson(Map<String, dynamic> json) {
    return Tour(
      id: (json['id'] ?? '').toString(),
      idTour: int.tryParse(json['id_tour']?.toString() ?? '0') ?? 0,
      name: json['nombre_tour'] ?? '',
      agency: json['agencia'] ?? '',
      startDate: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'].toString())
          : null,
      endDate: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'].toString())
          : null,
      price: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
      departurePoint: json['punto_partida'] ?? '',
      departureTime: json['hora_partida'] ?? '',
      arrival: json['llegada'] ?? '',
      pdfLink: json['link_pdf'] ?? '',
      inclusions: (json['inclusions'] as List? ?? [])
          .whereType<String>()
          .toList(),
      exclusions: (json['exclusions'] as List? ?? [])
          .whereType<String>()
          .toList(),
      itinerary: (json['itinerary'] as List? ?? [])
          .map(
            (i) => ItineraryDay(
              dayNumber: i['dia_numero'] ?? 0,
              title: i['titulo'] ?? '',
              description: i['descripcion'] ?? '',
            ),
          )
          .toList(),
      imageUrl: json['url_imagen'],
      sedeId: json['sede_id']?.toString(),
      isPromotion: json['es_promocion'] ?? false,
      isActive: json['is_active'] ?? true,
      isDraft: json['es_borrador'] ?? false,
      precioPorPareja: json['precio_por_pareja'] ?? false,
      cupos: json['cupos'] != null
          ? int.tryParse(json['cupos'].toString())
          : null,
      cuposDisponibles: json['cupos_disponibles'] != null
          ? int.tryParse(json['cupos_disponibles'].toString())
          : null,
      precios: (json['precios'] as List? ?? [])
          .map((p) => TourPrecio.fromJson(p as Map<String, dynamic>))
          .toList(),
      busLayoutIds: (json['bus_layout_ids'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e != 0)
          .toList(),
      tipoTour: json['tipo_tour']?.toString(),
      modoPrecio: json['modo_precio']?.toString() ?? 'individual',
      preciosGrupales: (json['precios_grupales'] as List? ?? [])
          .map((p) => PrecioGrupal.fromJson(p as Map<String, dynamic>))
          .toList(),
      imagenes: (json['imagenes'] as List? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  Map<String, dynamic> _toJson(Tour tour) {
    final isGrupal = tour.modoPrecio == 'grupal';
    return {
      'id_tour': tour.idTour,
      'nombre_tour': tour.name,
      'agencia': tour.agency,
      'fecha_inicio': tour.startDate!.toIso8601String(),
      'fecha_fin': tour.endDate!.toIso8601String(),
      if (!isGrupal) 'precio': tour.price,
      'modo_precio': tour.modoPrecio ?? 'individual',
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
      'sede_id': tour.sedeId,
      'es_promocion': tour.isPromotion,
      'is_active': tour.isActive,
      'es_borrador': tour.isDraft,
      'url_imagen': tour.imageUrl,
      'precio_por_pareja': tour.precioPorPareja,
      if (tour.cupos != null) 'cupos': tour.cupos,
      'bus_layout_ids': tour.busLayoutIds,
      if (tour.tipoTour != null) 'tipo_tour': tour.tipoTour,
      'imagenes': tour.imagenes,
    };
  }
}
