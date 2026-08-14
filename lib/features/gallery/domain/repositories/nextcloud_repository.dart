import 'dart:typed_data';
import '../entities/nextcloud_browse_result.dart';
import '../entities/nextcloud_folder.dart';
import '../entities/nextcloud_image.dart';
import '../entities/nextcloud_upload_batch.dart';

abstract class NextcloudRepository {
  /// Devuelve subcarpetas + imágenes en un solo request.
  /// [folder] null = raíz del usuario.
  Future<NextcloudBrowseResult> browse(String? folder);

  Future<NextcloudFolder> crearCarpeta(String nombre);

  Future<NextcloudImage> subirImagen({
    String? folder,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });

  /// Sube varias imágenes de una vez. Nunca lanza por fallos parciales:
  /// el reporte dice cuáles subieron y cuáles no.
  Future<NextcloudUploadBatch> subirImagenes({
    required String folder,
    required List<ArchivoSubida> archivos,
  });

  Future<void> eliminarImagen(String imageUrl);

  /// Elimina una carpeta y todo su contenido. Devuelve el número de imágenes eliminadas.
  Future<int> eliminarCarpeta(String folder);
}
