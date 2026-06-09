import 'package:equatable/equatable.dart';

class Notificacion extends Equatable {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final int? usuarioId;
  final int? creadoBy;
  final bool leida;
  final DateTime createdAt;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.usuarioId,
    this.creadoBy,
    required this.leida,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    titulo: json['titulo'] as String? ?? '',
    mensaje: json['mensaje'] as String? ?? '',
    tipo: json['tipo'] as String? ?? 'general',
    usuarioId: json['usuario_id'] != null
        ? int.tryParse(json['usuario_id'].toString())
        : null,
    creadoBy: json['creado_by'] != null
        ? int.tryParse(json['creado_by'].toString())
        : null,
    leida: json['leida'] as bool? ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );

  Notificacion copyWith({bool? leida}) => Notificacion(
    id: id,
    titulo: titulo,
    mensaje: mensaje,
    tipo: tipo,
    usuarioId: usuarioId,
    creadoBy: creadoBy,
    leida: leida ?? this.leida,
    createdAt: createdAt,
  );

  bool get esGeneral => usuarioId == null;

  @override
  List<Object?> get props => [
    id, titulo, mensaje, tipo, usuarioId, creadoBy, leida, createdAt,
  ];
}

class NotificacionListado {
  final List<Notificacion> items;
  final int total;
  final int totalNoLeidas;
  final int pagina;
  final int limite;
  final int totalPaginas;

  const NotificacionListado({
    required this.items,
    required this.total,
    required this.totalNoLeidas,
    required this.pagina,
    required this.limite,
    required this.totalPaginas,
  });
}
