import 'package:equatable/equatable.dart';

class Aerolinea extends Equatable {
  final int id;
  final String nombre;
  final String codigoIata;
  final String? logoUrl;
  final String? pais;
  final bool isActive;

  const Aerolinea({
    required this.id,
    required this.nombre,
    required this.codigoIata,
    this.logoUrl,
    this.pais,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, nombre, codigoIata, logoUrl, pais, isActive];
}
