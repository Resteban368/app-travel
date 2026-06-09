import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/nextcloud_image.dart';
import '../../domain/repositories/nextcloud_repository.dart';

class ApiNextcloudRepository implements NextcloudRepository {
  final http.Client _client;

  ApiNextcloudRepository({required http.Client client}) : _client = client;

  /// Devuelve la URL absoluta: si la API entrega un path relativo, antepone la base.
  String _absolute(String url) =>
      url.startsWith('http') ? url : '${ApiConstants.kBaseUrl}$url';

  NextcloudImage _normalize(NextcloudImage img) {
    final absUrl = _absolute(img.url);
    if (absUrl == img.url) return img;
    return NextcloudImage(
      filename: img.filename,
      folder: img.folder,
      url: absUrl,
      href: img.href,
    );
  }

  @override
  Future<List<NextcloudImage>> getImagenes(String folder) async {
    final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/nextcloud/images/$folder');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener imágenes ($folder): ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(NextcloudImage.fromJson)
        .map(_normalize)
        .toList();
  }

  @override
  Future<NextcloudImage> subirImagen({
    required String folder,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.kBaseUrl}/v1/nextcloud/image?folder=$folder',
    );
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception('Error al subir imagen: ${response.statusCode}');
    }
    return _normalize(NextcloudImage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    ));
  }

  @override
  Future<void> eliminarImagen(String imageUrl) async {
    final uri = Uri.parse(_absolute(imageUrl));
    final response = await _client.delete(uri);
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar imagen: ${response.statusCode}');
    }
  }
}
