import 'dart:typed_data';
import '../entities/nextcloud_image.dart';

abstract class NextcloudRepository {
  Future<List<NextcloudImage>> getImagenes(String folder);
  Future<NextcloudImage> subirImagen({
    required String folder,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });
  /// Elimina la imagen cuya URL completa es [imageUrl].
  /// Se usa la URL tal como la devuelve la API (con o sin ownerKey).
  Future<void> eliminarImagen(String imageUrl);
}
