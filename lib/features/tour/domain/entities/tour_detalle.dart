// Models for the GET /v1/tours/{id}/detalle response.

class ResponsableDetalle {
  final int id;
  final String nombre;
  final String? telefono;
  final String? correo;
  final String tipoDocumento;
  final String documento;

  const ResponsableDetalle({
    required this.id,
    required this.nombre,
    this.telefono,
    this.correo,
    required this.tipoDocumento,
    required this.documento,
  });

  factory ResponsableDetalle.fromJson(Map<String, dynamic> json) =>
      ResponsableDetalle(
        id: json['id'] ?? 0,
        nombre: json['nombre'] ?? '',
        telefono: json['telefono']?.toString(),
        correo: json['correo']?.toString(),
        tipoDocumento: json['tipo_documento'] ?? '',
        documento: json['documento'] ?? '',
      );
}

class IntegranteDetalle {
  final int id;
  final String nombre;
  final String? telefono;
  final String? fechaNacimiento;
  final String tipoDocumento;
  final String documento;

  const IntegranteDetalle({
    required this.id,
    required this.nombre,
    this.telefono,
    this.fechaNacimiento,
    required this.tipoDocumento,
    required this.documento,
  });

  factory IntegranteDetalle.fromJson(Map<String, dynamic> json) =>
      IntegranteDetalle(
        id: json['id'] ?? 0,
        nombre: json['nombre'] ?? '',
        telefono: json['telefono']?.toString(),
        fechaNacimiento: json['fecha_nacimiento']?.toString(),
        tipoDocumento: json['tipo_documento'] ?? '',
        documento: json['documento'] ?? '',
      );
}

class ReservaDetalle {
  final int id;
  final String idReserva;
  final String estado;
  final String? notas;
  final DateTime fechaCreacion;
  final bool ocupaCupo;
  final double valorTotal;
  final double valorCancelado;
  final double saldoPendiente;
  final int totalPersonas;
  final ResponsableDetalle responsable;
  final List<IntegranteDetalle> integrantes;

  const ReservaDetalle({
    required this.id,
    required this.idReserva,
    required this.estado,
    this.notas,
    required this.fechaCreacion,
    required this.ocupaCupo,
    required this.valorTotal,
    required this.valorCancelado,
    required this.saldoPendiente,
    required this.totalPersonas,
    required this.responsable,
    required this.integrantes,
  });

  factory ReservaDetalle.fromJson(Map<String, dynamic> json) => ReservaDetalle(
    id: json['id'] ?? 0,
    idReserva: json['id_reserva'] ?? '',
    estado: json['estado'] ?? '',
    notas: json['notas']?.toString(),
    fechaCreacion: DateTime.tryParse(json['fecha_creacion'] ?? '') ??
        DateTime.now(),
    ocupaCupo: json['ocupa_cupo'] ?? false,
    valorTotal:
        double.tryParse(json['valor_total']?.toString() ?? '0') ?? 0,
    valorCancelado:
        double.tryParse(json['valor_cancelado']?.toString() ?? '0') ?? 0,
    saldoPendiente:
        double.tryParse(json['saldo_pendiente']?.toString() ?? '0') ?? 0,
    totalPersonas: json['total_personas'] ?? 0,
    responsable: ResponsableDetalle.fromJson(json['responsable'] ?? {}),
    integrantes: (json['integrantes'] as List? ?? [])
        .map((i) => IntegranteDetalle.fromJson(i))
        .toList(),
  );
}

class TourDetalle {
  final List<ReservaDetalle> reservas;
  final int totalPasajeros;

  const TourDetalle({
    required this.reservas,
    required this.totalPasajeros,
  });

  factory TourDetalle.fromJson(Map<String, dynamic> json) => TourDetalle(
    reservas: (json['reservas'] as List? ?? [])
        .map((r) => ReservaDetalle.fromJson(r))
        .toList(),
    totalPasajeros: json['total_pasajeros'] ?? 0,
  );
}
