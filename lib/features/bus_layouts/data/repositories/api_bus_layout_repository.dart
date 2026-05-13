import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/network/api_exception.dart';
import '../../domain/entities/bus_layout.dart';
import '../../domain/repositories/bus_layout_repository.dart';

class ApiBusLayoutRepository implements BusLayoutRepository {
  final http.Client client;

  ApiBusLayoutRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/bus-layouts';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<BusLayout>> getBusLayouts() async {
    debugPrint('🌎 [ApiBusLayoutRepository] GET $_baseUrl');
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = json.decode(response.body);
    final List<dynamic> data = decoded is Map
        ? (decoded['data'] ?? [])
        : decoded;
    return data
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BusLayout> getBusLayout(int id) async {
    debugPrint('🌎 [ApiBusLayoutRepository] GET $_baseUrl/$id');
    final response = await client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final decoded = json.decode(response.body);
    return _fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<void> createBusLayout(BusLayout layout) async {
    final body = json.encode(_toJson(layout));
    debugPrint('📤 [ApiBusLayoutRepository] Creating: $body');
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
  Future<void> updateBusLayout(BusLayout layout) async {
    final body = json.encode(_toJson(layout));
    debugPrint('📤 [ApiBusLayoutRepository] Updating ID ${layout.id}: $body');
    final response = await client.patch(
      Uri.parse('$_baseUrl/${layout.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> deleteBusLayout(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response);
    }
  }

  BusLayout _fromJson(Map<String, dynamic> json) {
    BusConfiguracion? configuracion;
    if (json['configuracion'] != null) {
      final cfg = json['configuracion'] as Map<String, dynamic>;
      final asientosRaw = cfg['asientos'] as List<dynamic>? ?? [];
      final asientos = asientosRaw.map((a) {
        final aMap = a as Map<String, dynamic>;
        final tipoStr = aMap['tipo']?.toString() ?? 'normal';
        final tipo = _parseTipoAsiento(tipoStr);
        return AsientoLayout(
          fila: aMap['fila'] as int? ?? 0,
          columna: aMap['columna'] as int? ?? 0,
          numero: aMap['numero']?.toString() ?? '',
          tipo: tipo,
        );
      }).toList();
      configuracion = BusConfiguracion(
        filas: cfg['filas'] as int? ?? 0,
        columnas: cfg['columnas'] as int? ?? 0,
        asientos: asientos,
      );
    }

    return BusLayout(
      id: json['id'] as int?,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      totalAsientosCliente: json['total_asientos_cliente'] as int? ?? 0,
      activo: json['activo'] ?? true,
      configuracion: configuracion,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> _toJson(BusLayout layout) {
    final result = <String, dynamic>{
      'nombre': layout.nombre,
      if (layout.descripcion.isNotEmpty) 'descripcion': layout.descripcion,
    };

    if (layout.configuracion != null) {
      final cfg = layout.configuracion!;
      result['configuracion'] = {
        'filas': cfg.filas,
        'columnas': cfg.columnas,
        'asientos': cfg.asientos
            .where((a) => a.numero.isNotEmpty)
            .map((a) => {
              'fila': a.fila,
              'columna': a.columna,
              'numero': a.numero,
              'tipo': _tipoAsientoToString(a.tipo),
            }).toList(),
      };
    }

    return result;
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

  String _tipoAsientoToString(TipoAsiento tipo) {
    switch (tipo) {
      case TipoAsiento.agente:
        return 'agente';
      case TipoAsiento.conductor:
        return 'conductor';
      case TipoAsiento.vacio:
        return 'vacio';
      case TipoAsiento.bano:
        return 'baño';
      case TipoAsiento.normal:
        return 'normal';
      case TipoAsiento.entrada:
        return 'entrada';
    }
  }
}
