import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/bus_manifiesto.dart';
import '../../domain/entities/bus_layout.dart';
import '../../domain/repositories/bus_manifiesto_repository.dart';

class ApiBusManifiestoRepository implements BusManifiestoRepository {
  final http.Client client;
  ApiBusManifiestoRepository({required this.client});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<BusManifiesto> getBusManifiesto(int tourId) async {
    final url = '${ApiConstants.kBaseUrl}/v1/tours/$tourId/buses-manifiesto';
    debugPrint('🌎 [ApiBusManifiestoRepository] GET $url');
    final response = await client.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return _fromJson(body);
    }
    throw Exception('Error al cargar manifiesto: ${response.statusCode}');
  }

  @override
  Future<void> autoAsignarAsientos(int tourId) async {
    final url = '${ApiConstants.kBaseUrl}/v1/tours/$tourId/auto-asignar-asientos';
    debugPrint('🌎 [ApiBusManifiestoRepository] POST $url');
    final response = await client.post(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al auto-asignar asientos: ${response.statusCode}');
    }
  }

  @override
  Future<void> liberarAsiento({required int tourId, required int reservaId, required String numeroAsiento}) async {
    final url = '${ApiConstants.kBaseUrl}/v1/tours/$tourId/liberar-asiento';
    final response = await client.post(
      Uri.parse(url),
      headers: _headers,
      body: json.encode({'reserva_id': reservaId, 'numero_asiento': numeroAsiento}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al liberar asiento: ${response.statusCode}');
    }
  }

  @override
  Future<void> moverAsiento({
    required int tourId,
    required int busLayoutId,
    required int reservaIdOrigen,
    required String asientoOrigen,
    required String asientoDestino,
  }) async {
    final url = '${ApiConstants.kBaseUrl}/v1/tours/$tourId/mover-asiento';
    final response = await client.post(
      Uri.parse(url),
      headers: _headers,
      body: json.encode({
        'bus_layout_id': busLayoutId,
        'reserva_id_origen': reservaIdOrigen,
        'asiento_origen': asientoOrigen,
        'asiento_destino': asientoDestino,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al mover asiento: ${response.statusCode}');
    }
  }

  BusManifiesto _fromJson(Map<String, dynamic> json) {
    final tourJson = json['tour'] as Map<String, dynamic>;
    final busesJson = (json['buses'] as List<dynamic>?) ?? [];
    final sinAsientosJson = (json['reservas_sin_asientos'] as List<dynamic>?) ?? [];

    final tour = TourInfoManifiesto(
      id: tourJson['id'] as int,
      nombreTour: tourJson['nombre_tour'] as String? ?? '',
      fechaInicio: tourJson['fecha_inicio'] != null
          ? DateTime.tryParse(tourJson['fecha_inicio'].toString())
          : null,
      fechaFin: tourJson['fecha_fin'] != null
          ? DateTime.tryParse(tourJson['fecha_fin'].toString())
          : null,
      horaPartida: tourJson['hora_partida'] as String?,
      llegada: tourJson['llegada'] as String?,
      puntoPartida: tourJson['punto_partida'] as String?,
      cupos: tourJson['cupos'] as int?,
      esPromocion: tourJson['es_promocion'] == true,
      linkPdf: tourJson['link_pdf'] as String?,
    );

    final buses = busesJson.map((b) => _parseBus(b as Map<String, dynamic>)).toList();
    final reservasSinAsientos =
        sinAsientosJson.map((r) => _parseReservaSinAsiento(r as Map<String, dynamic>)).toList();

    return BusManifiesto(tour: tour, buses: buses, reservasSinAsientos: reservasSinAsientos);
  }

  BusManifiestoData _parseBus(Map<String, dynamic> json) {
    final cfgJson = json['configuracion'] as Map<String, dynamic>? ?? {};
    final asientosJsonCfg = (cfgJson['asientos'] as List<dynamic>?) ?? [];

    final configuracion = BusConfiguracion(
      filas: cfgJson['filas'] as int? ?? 0,
      columnas: cfgJson['columnas'] as int? ?? 4,
      asientos: asientosJsonCfg.map((a) {
        final aj = a as Map<String, dynamic>;
        return AsientoLayout(
          fila: aj['fila'] as int,
          columna: aj['columna'] as int,
          numero: aj['numero'] as String,
          tipo: _parseTipo(aj['tipo'] as String? ?? 'normal'),
        );
      }).toList(),
    );

    final asientosJson = (json['asientos'] as List<dynamic>?) ?? [];
    final asientos = asientosJson.map((a) {
      final aj = a as Map<String, dynamic>;
      ReservaManifiesto? reserva;
      if (aj['reserva'] != null) {
        final rj = aj['reserva'] as Map<String, dynamic>;
        reserva = ReservaManifiesto(
          id: rj['id'] as int,
          idReserva: rj['id_reserva'] as String,
          estado: rj['estado'] as String? ?? 'pendiente',
          responsable: rj['responsable'] != null
              ? _parsaPersona(rj['responsable'] as Map<String, dynamic>)
              : null,
          integrantes: ((rj['integrantes'] as List<dynamic>?) ?? [])
              .map((i) => _parsaPersona(i as Map<String, dynamic>))
              .toList(),
        );
      }
      return AsientoManifiesto(
        numero: aj['numero'] as String,
        fila: aj['fila'] as int,
        columna: aj['columna'] as int,
        reserva: reserva,
      );
    }).toList();

    return BusManifiestoData(
      busLayoutId: json['bus_layout_id'] as int,
      nombre: json['nombre'] as String? ?? '',
      totalAsientosCliente: json['total_asientos_cliente'] as int? ?? 0,
      asientosOcupados: json['asientos_ocupados'] as int? ?? 0,
      asientosDisponibles: json['asientos_disponibles'] as int? ?? 0,
      entrada: json['entrada'] as String?,
      configuracion: configuracion,
      asientos: asientos,
    );
  }

  ReservaManifiesto _parseReservaSinAsiento(Map<String, dynamic> json) {
    return ReservaManifiesto(
      id: json['id'] as int,
      idReserva: json['id_reserva'] as String,
      estado: json['estado'] as String? ?? 'pendiente',
      busLayoutId: json['bus_layout_id'] as int?,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      responsable: json['responsable'] != null
          ? _parsaPersona(json['responsable'] as Map<String, dynamic>)
          : null,
      integrantes: ((json['integrantes'] as List<dynamic>?) ?? [])
          .map((i) => _parsaPersona(i as Map<String, dynamic>))
          .toList(),
    );
  }

  PersonaManifiesto _parsaPersona(Map<String, dynamic> json) {
    return PersonaManifiesto(
      nombre: json['nombre'] as String? ?? '',
      tipoDocumento: json['tipo_documento'] as String?,
      documento: json['documento'] as String?,
      telefono: json['telefono'] as String?,
      ocupaAsiento: json['ocupa_asiento'] != false,
    );
  }

  TipoAsiento _parseTipo(String tipo) {
    switch (tipo) {
      case 'agente': return TipoAsiento.agente;
      case 'conductor': return TipoAsiento.conductor;
      case 'vacio': return TipoAsiento.vacio;
      case 'baño':
      case 'bano': return TipoAsiento.bano;
      case 'entrada': return TipoAsiento.entrada;
      default: return TipoAsiento.normal;
    }
  }
}
