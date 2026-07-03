import 'package:equatable/equatable.dart';

enum TipoAsiento { normal, agente, conductor, vacio, bano, entrada }

class BusTourHistorialItem {
  final int tourId;
  final String nombreTour;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final int totalReservas;
  final int totalPasajeros;
  final int asientosOcupados;
  final int asientosDisponibles;
  final int porcentajeOcupacion;

  const BusTourHistorialItem({
    required this.tourId,
    required this.nombreTour,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.totalReservas,
    required this.totalPasajeros,
    required this.asientosOcupados,
    required this.asientosDisponibles,
    required this.porcentajeOcupacion,
  });
}

class AsientoLayout extends Equatable {
  final int fila;
  final int columna;
  final String numero;
  final TipoAsiento tipo;

  const AsientoLayout({
    required this.fila,
    required this.columna,
    required this.numero,
    required this.tipo,
  });

  @override
  List<Object?> get props => [fila, columna, numero, tipo];
}

class BusConfiguracion extends Equatable {
  final int filas;
  final int columnas;
  final List<AsientoLayout> asientos;

  const BusConfiguracion({
    required this.filas,
    required this.columnas,
    required this.asientos,
  });

  /// Columna real del pasillo, inferida de los asientos.
  ///
  /// No hay un campo explícito de posición del pasillo en el layout, y no
  /// siempre está en `columnas ~/ 2` (layouts asimétricos como 3+1). Se
  /// infiere en dos pasos:
  /// 1. La columna del pasillo suele no tener NINGUNA celda en los datos
  ///    (ni siquiera `vacio`) — es un hueco en los índices de columna. Si
  ///    hay exactamente una columna así, es el pasillo.
  /// 2. Si no, se busca una columna que sea `TipoAsiento.vacio` en todas
  ///    sus filas de pasajeros (fila > 0) — el patrón usado al generar un
  ///    layout nuevo, donde el pasillo sí se guarda explícitamente.
  /// Si ninguna señal es concluyente, se cae a `columnas ~/ 2` como último
  /// recurso.
  int get pasilloColumn {
    if (columnas <= 0) return 0;

    final celdasPorColumna = <int, List<AsientoLayout>>{};
    for (final a in asientos) {
      (celdasPorColumna[a.columna] ??= []).add(a);
    }

    final columnasAusentes = [
      for (int c = 0; c < columnas; c++)
        if (!celdasPorColumna.containsKey(c)) c,
    ];
    if (columnasAusentes.length == 1) return columnasAusentes.first;

    final siempreVacio = <int>[];
    for (int c = 0; c < columnas; c++) {
      final celdas =
          celdasPorColumna[c]?.where((a) => a.fila > 0).toList() ?? const [];
      if (celdas.isNotEmpty && celdas.every((a) => a.tipo == TipoAsiento.vacio)) {
        siempreVacio.add(c);
      }
    }
    if (siempreVacio.length == 1) return siempreVacio.first;
    if (siempreVacio.isNotEmpty) {
      final centro = columnas / 2;
      return siempreVacio.reduce(
        (a, b) => (a - centro).abs() <= (b - centro).abs() ? a : b,
      );
    }

    return columnas ~/ 2;
  }

  @override
  List<Object?> get props => [filas, columnas, asientos];
}

class BusLayout extends Equatable {
  final int? id;
  final String nombre;
  final String descripcion;
  final int totalAsientosCliente;
  final bool activo;
  final BusConfiguracion? configuracion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusLayout({
    this.id,
    required this.nombre,
    required this.descripcion,
    this.totalAsientosCliente = 0,
    this.activo = true,
    this.configuracion,
    this.createdAt,
    this.updatedAt,
  });

  BusLayout copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    int? totalAsientosCliente,
    bool? activo,
    BusConfiguracion? configuracion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusLayout(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      totalAsientosCliente: totalAsientosCliente ?? this.totalAsientosCliente,
      activo: activo ?? this.activo,
      configuracion: configuracion ?? this.configuracion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    descripcion,
    totalAsientosCliente,
    activo,
    configuracion,
    createdAt,
    updatedAt,
  ];
}
