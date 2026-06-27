import 'package:equatable/equatable.dart';

class TourSalida extends Equatable {
  final int id;
  final String fechaInicio;
  final String fechaFin;
  final int? cupos;
  final int? cuposDisponibles;
  final String? label;
  final bool isActive;

  const TourSalida({
    required this.id,
    required this.fechaInicio,
    required this.fechaFin,
    this.cupos,
    this.cuposDisponibles,
    this.label,
    this.isActive = true,
  });

  factory TourSalida.fromJson(Map<String, dynamic> json) {
    return TourSalida(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      cupos: json['cupos'] != null
          ? int.tryParse(json['cupos'].toString())
          : null,
      cuposDisponibles: json['cupos_disponibles'] != null
          ? int.tryParse(json['cupos_disponibles'].toString())
          : null,
      label: json['label']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    if (cupos != null) 'cupos': cupos,
    if (label != null && label!.isNotEmpty) 'label': label,
  };

  @override
  List<Object?> get props =>
      [id, fechaInicio, fechaFin, cupos, cuposDisponibles, label, isActive];
}
