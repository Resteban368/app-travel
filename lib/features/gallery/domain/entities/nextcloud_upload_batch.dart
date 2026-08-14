import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'nextcloud_image.dart';

/// Un archivo listo para enviar en el multipart.
class ArchivoSubida {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  const ArchivoSubida({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

class UploadFallido extends Equatable {
  final String archivo;
  final String motivo;
  const UploadFallido({required this.archivo, required this.motivo});

  factory UploadFallido.fromJson(Map<String, dynamic> json) => UploadFallido(
        archivo: json['archivo']?.toString() ?? 'archivo',
        motivo: json['motivo']?.toString() ?? 'Error desconocido',
      );

  @override
  List<Object?> get props => [archivo, motivo];
}

/// Reporte que devuelve la API: unas pueden subir y otras fallar.
class NextcloudUploadBatch extends Equatable {
  final int total;
  final int exitosas;
  final int fallidas;
  final List<NextcloudImage> subidas;
  final List<UploadFallido> errores;

  const NextcloudUploadBatch({
    required this.total,
    required this.exitosas,
    required this.fallidas,
    required this.subidas,
    required this.errores,
  });

  bool get todoOk => fallidas == 0 && exitosas > 0;
  bool get parcial => exitosas > 0 && fallidas > 0;
  bool get todoFallo => exitosas == 0;

  factory NextcloudUploadBatch.fromJson(
    Map<String, dynamic> json, {
    required String Function(String) normalizeUrl,
  }) {
    final subidas = (json['subidas'] as List<dynamic>? ?? [])
        .map((e) => NextcloudImage.fromJson(e as Map<String, dynamic>))
        .map((img) => NextcloudImage(
              filename: img.filename,
              folder: img.folder,
              url: normalizeUrl(img.url),
              href: img.href,
            ))
        .toList();

    return NextcloudUploadBatch(
      total: (json['total'] as num?)?.toInt() ?? 0,
      exitosas: (json['exitosas'] as num?)?.toInt() ?? 0,
      fallidas: (json['fallidas'] as num?)?.toInt() ?? 0,
      subidas: subidas,
      errores: (json['errores'] as List<dynamic>? ?? [])
          .map((e) => UploadFallido.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [total, exitosas, fallidas, subidas, errores];
}
