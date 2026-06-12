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
  Future<void> liberarAsiento({
    required int tourId,
    required int reservaId,
    required String numeroAsiento,
  }) async {
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

  @override
  Future<void> asignarAsiento({
    required int tourId,
    required int busLayoutId,
    required int reservaId,
    required List<String> asientos,
  }) async {
    final url = '${ApiConstants.kBaseUrl}/v1/tours/$tourId/asignar-asiento';
    debugPrint('🌎 [ApiBusManifiestoRepository] POST $url');
    final response = await client.post(
      Uri.parse(url),
      headers: _headers,
      body: json.encode({
        'bus_layout_id': busLayoutId,
        'reserva_id': reservaId,
        'asientos': asientos,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al asignar asiento: ${response.statusCode}');
    }
  }

  // ── Parsing ──────────────────────────────────────────────────────────────

  BusManifiesto _fromJson(Map<String, dynamic> data) {
    final tourJson = data['tour'] as Map<String, dynamic>;
    final busesJson = (data['buses'] as List<dynamic>?) ?? [];
    final sinAsientosJson = (data['reservas_sin_asientos'] as List<dynamic>?) ?? [];

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

    final buses = busesJson
        .map((b) => _parseBus(b as Map<String, dynamic>))
        .toList();
    final reservasSinAsientos = sinAsientosJson
        .map((r) => _parseReservaSinAsiento(r as Map<String, dynamic>))
        .toList();

    return BusManifiesto(
      tour: tour,
      buses: buses,
      reservasSinAsientos: reservasSinAsientos,
    );
  }

  BusManifiestoData _parseBus(Map<String, dynamic> json) {
    // ── 1. Build layout from configuracion (authoritative: integer columns) ──
    final cfgJson = json['configuracion'] as Map<String, dynamic>?;
    final cfgFilas = cfgJson?['filas'] as int? ?? 0;
    final cfgColumnas = cfgJson?['columnas'] as int? ?? 0;
    final cfgAsientosRaw = cfgJson?['asientos'] as List<dynamic>? ?? const [];

    final layoutPorPos = <(int, int), AsientoLayout>{};
    for (final a in cfgAsientosRaw) {
      final aMap = a as Map<String, dynamic>;
      final fila = (aMap['fila'] as num).toInt();
      final columna = (aMap['columna'] as num).toInt();
      final numero = aMap['numero']?.toString() ?? '';
      final tipo = _parseTipoAsiento(aMap['tipo']?.toString() ?? 'normal');
      layoutPorPos[(fila, columna)] = AsientoLayout(
        fila: fila, columna: columna, numero: numero, tipo: tipo,
      );
    }

    // Numero → position lookup so manifest seats find their correct column.
    final numPorNumero = <String, (int, int)>{
      for (final e in layoutPorPos.entries)
        if (e.value.numero.isNotEmpty) e.value.numero: e.key,
    };

    // ── 2. Parse asientos for reservation data + agente overrides ───────────
    final asientosJson = (json['asientos'] as List<dynamic>?) ?? [];
    final manifiestoAsientos = <AsientoManifiesto>[];

    for (final a in asientosJson) {
      final aj = a as Map<String, dynamic>;
      final numero = aj['numero'] as String;
      final tipoStr = aj['tipo'] as String? ?? 'normal';

      if (tipoStr != 'normal') {
        // Special seats come from configuracion; only add as fallback when
        // configuracion was absent.
        if (layoutPorPos.isEmpty) {
          final fila = (aj['fila'] as num).toInt();
          final columnaRaw = aj['columna'];
          final columna = columnaRaw is int
              ? columnaRaw
              : (columnaRaw as String).toUpperCase().codeUnitAt(0) -
                  'A'.codeUnitAt(0);
          layoutPorPos[(fila, columna)] = AsientoLayout(
            fila: fila,
            columna: columna,
            numero: numero,
            tipo: _parseTipoAsiento(tipoStr),
          );
        }
        continue;
      }

      // Resolve to correct integer column via the layout lookup.
      final pos = numPorNumero[numero];
      int fila;
      int columna;
      if (pos != null) {
        fila = pos.$1;
        columna = pos.$2;
      } else {
        fila = (aj['fila'] as num).toInt();
        final columnaRaw = aj['columna'];
        columna = columnaRaw is int
            ? columnaRaw
            : (columnaRaw as String).toUpperCase().codeUnitAt(0) -
                'A'.codeUnitAt(0);
      }

      // Apply agente type override in the layout map.
      if (aj['agente'] == true) {
        final cur = layoutPorPos[(fila, columna)];
        if (cur != null && cur.tipo == TipoAsiento.normal) {
          layoutPorPos[(fila, columna)] = AsientoLayout(
            fila: fila, columna: columna, numero: numero,
            tipo: TipoAsiento.agente,
          );
        }
      }

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
      manifiestoAsientos.add(AsientoManifiesto(
        numero: numero,
        fila: fila,
        columna: columna,
        reserva: reserva,
      ));
    }

    // ── 3. Derive dimensions ─────────────────────────────────────────────────
    final layoutList = layoutPorPos.values.toList();
    final maxFila = layoutList.isEmpty
        ? 0
        : layoutList.map((a) => a.fila).reduce((a, b) => a > b ? a : b);
    final maxColumna = layoutList.isEmpty
        ? 3
        : layoutList.map((a) => a.columna).reduce((a, b) => a > b ? a : b);

    final finalFilas = cfgFilas > 0 ? cfgFilas : maxFila;
    final finalColumnas = cfgColumnas > 0 ? cfgColumnas : maxColumna + 1;

    final speciales = layoutList
        .where((a) => a.tipo != TipoAsiento.normal && a.tipo != TipoAsiento.vacio)
        .map((a) => '${a.tipo.name}(${a.fila},${a.columna})')
        .toList();
    debugPrint('🚌 [parseBus] "${json['nombre']}": '
        'cfg=${cfgColumnas}cols×${cfgFilas}rows → final=${finalColumnas}cols | '
        'speciales=$speciales');

    return BusManifiestoData(
      busLayoutId: json['bus_layout_id'] as int,
      nombre: json['nombre'] as String? ?? '',
      totalAsientosCliente: json['total_asientos_cliente'] as int? ?? 0,
      asientosOcupados: json['asientos_ocupados'] as int? ?? 0,
      asientosDisponibles: json['asientos_disponibles'] as int? ?? 0,
      entrada: json['entrada'] as String?,
      configuracion: BusConfiguracion(
        filas: finalFilas,
        columnas: finalColumnas,
        asientos: layoutList,
      ),
      asientos: manifiestoAsientos,
    );
  }

  TipoAsiento _parseTipoAsiento(String tipo) {
    switch (tipo) {
      case 'agente':
        return TipoAsiento.agente;
      case 'conductor':
        return TipoAsiento.conductor;
      case 'vacio':
        return TipoAsiento.vacio;
      case 'baño':
      case 'bano':
        return TipoAsiento.bano;
      case 'entrada':
        return TipoAsiento.entrada;
      default:
        return TipoAsiento.normal;
    }
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
}
