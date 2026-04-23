import 'package:equatable/equatable.dart';

class SesionUsuario extends Equatable {
  final int id;
  final int usuarioId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final int? duracionSegundos;
  final String ip;
  final String userAgent;
  final String? usuarioNombre;
  final String? usuarioEmail;

  const SesionUsuario({
    required this.id,
    required this.usuarioId,
    required this.fechaInicio,
    this.fechaFin,
    this.duracionSegundos,
    required this.ip,
    required this.userAgent,
    this.usuarioNombre,
    this.usuarioEmail,
  });

  bool get isActive => fechaFin == null;

  String get duracionFormateada {
    final secs = duracionSegundos;
    if (secs == null) return 'Activa';
    if (secs < 60) return '${secs}s';
    if (secs < 3600) return '${(secs / 60).floor()}m ${secs % 60}s';
    final h = (secs / 3600).floor();
    final m = ((secs % 3600) / 60).floor();
    return '${h}h ${m}m';
  }

  factory SesionUsuario.fromJson(Map<String, dynamic> json) {
    final userMap = json['usuario'] as Map<String, dynamic>?;
    return SesionUsuario(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'] ?? userMap?['id'] ?? 0,
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      duracionSegundos: json['duracion_segundos'],
      ip: json['ip'] ?? '',
      userAgent: json['user_agent'] ?? '',
      usuarioNombre: userMap?['nombre'],
      usuarioEmail: userMap?['email'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    usuarioId,
    fechaInicio,
    fechaFin,
    duracionSegundos,
    ip,
    userAgent,
    usuarioNombre,
    usuarioEmail,
  ];
}
