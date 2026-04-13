import 'package:equatable/equatable.dart';

class PoliticaReserva extends Equatable {
  final int id;
  final String titulo;
  final String descripcion;
  final String tipoPolitica;
  final bool activo;
  final DateTime? fechaCreacion;

  const PoliticaReserva({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipoPolitica,
    this.activo = true,
    this.fechaCreacion,
  });

  PoliticaReserva copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? tipoPolitica,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return PoliticaReserva(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipoPolitica: tipoPolitica ?? this.tipoPolitica,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        titulo,
        descripcion,
        tipoPolitica,
        activo,
        fechaCreacion,
      ];
}
