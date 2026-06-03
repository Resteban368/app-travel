import 'package:equatable/equatable.dart';

class PrecioGrupal extends Equatable {
  final int? id;
  final int minPersonas;
  final int maxPersonas;
  final double precio;
  final String? descripcion;

  const PrecioGrupal({
    this.id,
    required this.minPersonas,
    required this.maxPersonas,
    required this.precio,
    this.descripcion,
  });

  factory PrecioGrupal.fromJson(Map<String, dynamic> json) => PrecioGrupal(
    id: json['id'] as int?,
    minPersonas: int.tryParse(json['min_personas']?.toString() ?? '0') ?? 0,
    maxPersonas: int.tryParse(json['max_personas']?.toString() ?? '0') ?? 0,
    precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
    descripcion: json['descripcion'] as String?,
  );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'min_personas': minPersonas,
      'max_personas': maxPersonas,
      'precio': precio,
    };
    if (id != null) m['id'] = id;
    if (descripcion != null && descripcion!.isNotEmpty) {
      m['descripcion'] = descripcion;
    }
    return m;
  }

  PrecioGrupal copyWith({
    int? id,
    int? minPersonas,
    int? maxPersonas,
    double? precio,
    String? descripcion,
  }) => PrecioGrupal(
    id: id ?? this.id,
    minPersonas: minPersonas ?? this.minPersonas,
    maxPersonas: maxPersonas ?? this.maxPersonas,
    precio: precio ?? this.precio,
    descripcion: descripcion ?? this.descripcion,
  );

  @override
  List<Object?> get props => [id, minPersonas, maxPersonas, precio, descripcion];
}
