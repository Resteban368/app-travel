import 'dart:typed_data';
import '../entities/nextcloud_browse_result.dart';
import '../entities/nextcloud_folder.dart';
import '../entities/nextcloud_image.dart';

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

  Future<void> eliminarImagen(String imageUrl);

  /// Elimina una carpeta y todo su contenido. Devuelve el número de imágenes eliminadas.
  Future<int> eliminarCarpeta(String folder);
}
