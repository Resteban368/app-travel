import 'package:equatable/equatable.dart';
import '../../../bus_layouts/domain/entities/bus_layout.dart';

class SalidaBus {
  final int busLayoutId;
  final String nombre;
  final int totalAsientosCliente;
  final int asientosOcupados;
  final int asientosDisponibles;
  final List<String> asientosAgentes;

  const SalidaBus({
    required this.busLayoutId,
    required this.nombre,
    required this.totalAsientosCliente,
    required this.asientosOcupados,
    required this.asientosDisponibles,
    this.asientosAgentes = const [],
  });

  factory SalidaBus.fromJson(Map<String, dynamic> json) => SalidaBus(
    busLayoutId: int.tryParse(json['bus_layout_id']?.toString() ?? '0') ?? 0,
    nombre: json['nombre']?.toString() ?? '',
    totalAsientosCliente: int.tryParse(json['total_asientos_cliente']?.toString() ?? '0') ?? 0,
    asientosOcupados: int.tryParse(json['asientos_ocupados']?.toString() ?? '0') ?? 0,
    asientosDisponibles: int.tryParse(json['asientos_disponibles']?.toString() ?? '0') ?? 0,
    asientosAgentes: (json['asientos_agentes'] as List? ?? []).map((e) => e.toString()).toList(),
  );

  SalidaBus copyWith({List<String>? asientosAgentes}) => SalidaBus(
    busLayoutId: busLayoutId,
    nombre: nombre,
    totalAsientosCliente: totalAsientosCliente,
    asientosOcupados: asientosOcupados,
    asientosDisponibles: asientosDisponibles,
    asientosAgentes: asientosAgentes ?? this.asientosAgentes,
  );
}

class TourSalida extends Equatable {
  final int id;
  final String fechaInicio;
  final String fechaFin;
  final int? cupos;
  final int? cuposDisponibles;
  final String? label;
  final bool isActive;
  final List<int> busLayoutIds;
  final List<SalidaBus> buses;
  final List<BusLayout> busLayouts;

  const TourSalida({
    required this.id,
    required this.fechaInicio,
    required this.fechaFin,
    this.cupos,
    this.cuposDisponibles,
    this.label,
    this.isActive = true,
    this.busLayoutIds = const [],
    this.buses = const [],
    this.busLayouts = const [],
  });

  factory TourSalida.fromJson(Map<String, dynamic> json) {
    final rawBusLayouts = (json['busLayouts'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    // Derive busLayoutIds from explicit list or from busLayouts objects
    final rawIds = json['bus_layout_ids'] as List?;
    final busLayoutIds = rawIds != null
        ? rawIds
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((id) => id > 0)
            .toList()
        : rawBusLayouts
            .map((b) => int.tryParse(b['id']?.toString() ?? '0') ?? 0)
            .where((id) => id > 0)
            .toList();

    return TourSalida(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      cupos: json['cupos'] != null ? int.tryParse(json['cupos'].toString()) : null,
      cuposDisponibles: json['cupos_disponibles'] != null
          ? int.tryParse(json['cupos_disponibles'].toString())
          : null,
      label: json['label']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      busLayoutIds: busLayoutIds,
      buses: (json['buses'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SalidaBus.fromJson)
          .toList(),
      busLayouts: rawBusLayouts.map(_parseBusLayout).toList(),
    );
  }

  static BusLayout _parseBusLayout(Map<String, dynamic> json) {
    BusConfiguracion? cfg;
    final cfgJson = json['configuracion'] as Map<String, dynamic>?;
    if (cfgJson != null) {
      final asientos = (cfgJson['asientos'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((a) => AsientoLayout(
                fila: (a['fila'] as num).toInt(),
                columna: (a['columna'] as num).toInt(),
                numero: a['numero']?.toString() ?? '',
                tipo: _parseTipo(a['tipo']?.toString() ?? 'normal'),
              ))
          .toList();
      cfg = BusConfiguracion(
        filas: (cfgJson['filas'] as num?)?.toInt() ?? 0,
        columnas: (cfgJson['columnas'] as num?)?.toInt() ?? 0,
        asientos: asientos,
      );
    }
    return BusLayout(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      totalAsientosCliente: (json['total_asientos_cliente'] as num?)?.toInt() ?? 0,
      activo: json['activo'] as bool? ?? true,
      configuracion: cfg,
    );
  }

  static TipoAsiento _parseTipo(String tipo) {
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

  Map<String, dynamic> toJson() => {
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    if (cupos != null) 'cupos': cupos,
    if (label != null && label!.isNotEmpty) 'label': label,
    if (busLayoutIds.isNotEmpty) 'bus_layout_ids': busLayoutIds,
  };

  TourSalida copyWith({
    int? id,
    String? fechaInicio,
    String? fechaFin,
    int? cupos,
    int? cuposDisponibles,
    String? label,
    bool? isActive,
    List<int>? busLayoutIds,
    List<SalidaBus>? buses,
    List<BusLayout>? busLayouts,
  }) => TourSalida(
    id: id ?? this.id,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    cupos: cupos ?? this.cupos,
    cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
    label: label ?? this.label,
    isActive: isActive ?? this.isActive,
    busLayoutIds: busLayoutIds ?? this.busLayoutIds,
    buses: buses ?? this.buses,
    busLayouts: busLayouts ?? this.busLayouts,
  );

  @override
  List<Object?> get props => [
    id, fechaInicio, fechaFin, cupos, cuposDisponibles,
    label, isActive, busLayoutIds, buses, busLayouts,
  ];
}
