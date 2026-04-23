import 'package:equatable/equatable.dart';

class RedSocial extends Equatable {
  final String nombre;
  final String link;

  const RedSocial({required this.nombre, required this.link});

  @override
  List<Object?> get props => [nombre, link];

  Map<String, dynamic> toJson() => {'red': nombre, 'url': link};

  factory RedSocial.fromJson(Map<String, dynamic> json) {
    return RedSocial(
      nombre: json['red'] ?? json['nombre'] ?? '',
      link: json['url'] ?? json['link'] ?? '',
    );
  }
}

class InfoEmpresa extends Equatable {
  final int id;
  final String nombre;
  final String direccion;
  final String mision;
  final String vision;
  final String detalles;
  final String horarioPresencial;
  final String horarioVirtual;
  final List<RedSocial> redesSociales;
  final String nombreGerente;
  final String telefono;
  final String correo;
  final String sitioWeb;

  const InfoEmpresa({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.mision,
    required this.vision,
    required this.detalles,
    required this.horarioPresencial,
    required this.horarioVirtual,
    required this.redesSociales,
    required this.nombreGerente,
    required this.telefono,
    required this.correo,
    required this.sitioWeb,
  });

  InfoEmpresa copyWith({
    int? id,
    String? nombre,
    String? direccion,
    String? mision,
    String? vision,
    String? detalles,
    String? horarioPresencial,
    String? horarioVirtual,
    List<RedSocial>? redesSociales,
    String? nombreGerente,
    String? telefono,
    String? correo,
    String? sitioWeb,
  }) {
    return InfoEmpresa(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      mision: mision ?? this.mision,
      vision: vision ?? this.vision,
      detalles: detalles ?? this.detalles,
      horarioPresencial: horarioPresencial ?? this.horarioPresencial,
      horarioVirtual: horarioVirtual ?? this.horarioVirtual,
      redesSociales: redesSociales ?? this.redesSociales,
      nombreGerente: nombreGerente ?? this.nombreGerente,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      sitioWeb: sitioWeb ?? this.sitioWeb,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        direccion,
        mision,
        vision,
        detalles,
        horarioPresencial,
        horarioVirtual,
        redesSociales,
        nombreGerente,
        telefono,
        correo,
        sitioWeb,
      ];
}
