import 'package:equatable/equatable.dart';

class TourPrecio extends Equatable {
  final int? id;
  final String descripcion;
  final int? edadMin;
  final int? edadMax;
  final String? puntoPartida;
  final double precio;
  final bool activo;

  const TourPrecio({
    this.id,
    required this.descripcion,
    this.edadMin,
    this.edadMax,
    this.puntoPartida,
    required this.precio,
    this.activo = true,
  });

  factory TourPrecio.fromJson(Map<String, dynamic> json) => TourPrecio(
    id: json['id'] as int?,
    descripcion: json['descripcion'] as String? ?? '',
    edadMin: json['edad_min'] as int?,
    edadMax: json['edad_max'] as int?,
    puntoPartida: json['punto_partida'] as String?,
    precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
    activo: json['activo'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'descripcion': descripcion,
      'precio': precio,
      'activo': activo,
    };
    if (id != null) m['id'] = id;
    if (edadMin != null) m['edad_min'] = edadMin;
    if (edadMax != null) m['edad_max'] = edadMax;
    if (puntoPartida != null && puntoPartida!.isNotEmpty) {
      m['punto_partida'] = puntoPartida;
    }
    return m;
  }

  TourPrecio copyWith({
    int? id,
    String? descripcion,
    int? edadMin,
    int? edadMax,
    String? puntoPartida,
    double? precio,
    bool? activo,
  }) => TourPrecio(
    id: id ?? this.id,
    descripcion: descripcion ?? this.descripcion,
    edadMin: edadMin ?? this.edadMin,
    edadMax: edadMax ?? this.edadMax,
    puntoPartida: puntoPartida ?? this.puntoPartida,
    precio: precio ?? this.precio,
    activo: activo ?? this.activo,
  );

  @override
  List<Object?> get props => [
    id, descripcion, edadMin, edadMax, puntoPartida, precio, activo,
  ];
}
