import 'package:equatable/equatable.dart';

/// Represents a branch/office of the agency.
class Sede extends Equatable {
  final String id;
  final String nombreSede;
  final String telefono;
  final String direccion;
  final String linkMap;
  final bool isActive;

  const Sede({
    required this.id,
    required this.nombreSede,
    required this.telefono,
    required this.direccion,
    required this.linkMap,
    this.isActive = true,
  });

  Sede copyWith({
    String? id,
    String? nombreSede,
    String? telefono,
    String? direccion,
    String? linkMap,
    bool? isActive,
  }) {
    return Sede(
      id: id ?? this.id,
      nombreSede: nombreSede ?? this.nombreSede,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      linkMap: linkMap ?? this.linkMap,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombreSede,
    telefono,
    direccion,
    linkMap,
    isActive,
  ];
}
