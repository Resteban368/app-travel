import 'package:equatable/equatable.dart';

class Habitacion extends Equatable {
  final String tipoCama;
  final int cantidad;
  final double precio;
  final List<String> imagenes;
  final List<String> servicios;
  final String? observaciones;

  const Habitacion({
    required this.tipoCama,
    required this.cantidad,
    required this.precio,
    this.imagenes = const [],
    this.servicios = const [],
    this.observaciones,
  });

  Habitacion copyWith({
    String? tipoCama,
    int? cantidad,
    double? precio,
    List<String>? imagenes,
    List<String>? servicios,
    String? observaciones,
  }) => Habitacion(
    tipoCama: tipoCama ?? this.tipoCama,
    cantidad: cantidad ?? this.cantidad,
    precio: precio ?? this.precio,
    imagenes: imagenes ?? this.imagenes,
    servicios: servicios ?? this.servicios,
    observaciones: observaciones ?? this.observaciones,
  );

  factory Habitacion.fromJson(Map<String, dynamic> json) => Habitacion(
    tipoCama: json['tipo_cama']?.toString() ?? '',
    cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
    precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0.0,
    imagenes: (json['imagenes'] as List? ?? []).whereType<String>().toList(),
    servicios: (json['servicios'] as List? ?? []).whereType<String>().toList(),
    observaciones: json['observaciones']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'tipo_cama': tipoCama,
    'cantidad': cantidad,
    'precio': precio,
    if (imagenes.isNotEmpty) 'imagenes': imagenes,
    if (servicios.isNotEmpty) 'servicios': servicios,
    if (observaciones != null && observaciones!.isNotEmpty)
      'observaciones': observaciones,
  };

  @override
  List<Object?> get props => [tipoCama, cantidad, precio, imagenes, servicios, observaciones];
}

class Hotel extends Equatable {
  final int? id;
  final String nombre;
  final String ciudad;
  final String telefono;
  final String direccion;
  final bool isActive;
  final DateTime? createdAt;
  final List<String> imagenes;
  final List<Habitacion> habitaciones;

  const Hotel({
    this.id,
    required this.nombre,
    required this.ciudad,
    required this.telefono,
    required this.direccion,
    this.isActive = true,
    this.createdAt,
    this.imagenes = const [],
    this.habitaciones = const [],
  });

  Hotel copyWith({
    int? id,
    String? nombre,
    String? ciudad,
    String? telefono,
    String? direccion,
    bool? isActive,
    DateTime? createdAt,
    List<String>? imagenes,
    List<Habitacion>? habitaciones,
  }) {
    return Hotel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ciudad: ciudad ?? this.ciudad,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      imagenes: imagenes ?? this.imagenes,
      habitaciones: habitaciones ?? this.habitaciones,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    ciudad,
    telefono,
    direccion,
    isActive,
    createdAt,
    imagenes,
    habitaciones,
  ];
}
