import 'package:equatable/equatable.dart';

class AuditoriaGeneral extends Equatable {
  final int id;
  final int? usuarioId;
  final String usuarioNombre;
  final String modulo;
  final String operacion;
  final String documentoId;
  final Map<String, dynamic> detalle;
  final DateTime fecha;

  const AuditoriaGeneral({
    required this.id,
    this.usuarioId,
    required this.usuarioNombre,
    required this.modulo,
    required this.operacion,
    required this.documentoId,
    required this.detalle,
    required this.fecha,
  });

  factory AuditoriaGeneral.fromJson(Map<String, dynamic> json) {
    return AuditoriaGeneral(
      id: json['id'] as int,
      usuarioId: json['usuario_id'] as int?,
      usuarioNombre: json['usuario_nombre'] ?? 'Sistema',
      modulo: json['modulo'] ?? '',
      operacion: json['operacion'] ?? '',
      documentoId: json['documento_id']?.toString() ?? '',
      detalle: json['detalle'] as Map<String, dynamic>? ?? {},
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        usuarioId,
        usuarioNombre,
        modulo,
        operacion,
        documentoId,
        detalle,
        fecha,
      ];
}
