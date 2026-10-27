import 'package:equatable/equatable.dart';

class Opinion extends Equatable {
  final int id;
  final String nombre;
  final String? plan;
  final String texto;
  final int calificacion;
  final bool aprobada;
  final DateTime? createdAt;

  const Opinion({
    required this.id,
    required this.nombre,
    this.plan,
    required this.texto,
    this.calificacion = 5,
    this.aprobada = false,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    nombre,
    plan,
    texto,
    calificacion,
    aprobada,
    createdAt,
  ];
}
