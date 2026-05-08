import 'package:equatable/equatable.dart';

enum TipoAsiento { normal, agente, conductor, vacio, bano }

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
