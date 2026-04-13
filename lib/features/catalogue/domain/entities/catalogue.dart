import 'package:equatable/equatable.dart';

class Catalogue extends Equatable {
  final int idCatalogue;
  final int idSede;
  final String nombreCatalogue;
  final String urlArchivo;
  final bool activo;
  final DateTime fechaCreacion;

  const Catalogue({
    required this.idCatalogue,
    required this.idSede,
    required this.nombreCatalogue,
    required this.urlArchivo,
    required this.activo,
    required this.fechaCreacion,
  });

  Catalogue copyWith({
    int? idCatalogue,
    int? idSede,
    String? nombreCatalogue,
    String? urlArchivo,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Catalogue(
      idCatalogue: idCatalogue ?? this.idCatalogue,
      idSede: idSede ?? this.idSede,
      nombreCatalogue: nombreCatalogue ?? this.nombreCatalogue,
      urlArchivo: urlArchivo ?? this.urlArchivo,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  List<Object?> get props => [
    idCatalogue,
    idSede,
    nombreCatalogue,
    urlArchivo,
    activo,
    fechaCreacion,
  ];
}
