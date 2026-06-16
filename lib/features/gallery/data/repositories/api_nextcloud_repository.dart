import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/nextcloud_browse_result.dart';
import '../../domain/entities/nextcloud_folder.dart';
import '../../domain/entities/nextcloud_image.dart';
import '../../domain/repositories/nextcloud_repository.dart';

class ApiNextcloudRepository implements NextcloudRepository {
  final http.Client _client;

  ApiNextcloudRepository({required http.Client client}) : _client = client;

  String _absolute(String url) {
    final abs = url.startsWith('http') ? url : '${ApiConstants.kBaseUrl}$url';
    return abs.replaceFirst('http://', 'https://');
  }

  @override
  Future<NextcloudBrowseResult> browse(String? folder) async {
    final path = (folder != null && folder.isNotEmpty)
        ? '/v1/nextcloud/browse/$folder'
        : '/v1/nextcloud/browse';
    final uri = Uri.parse('${ApiConstants.kBaseUrl}$path');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al navegar carpeta: ${response.statusCode}');
    }
    return NextcloudBrowseResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      normalizeUrl: _absolute,
    );
  }

  @override
  Future<NextcloudFolder> crearCarpeta(String nombre) async {
    final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/nextcloud/folder');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear carpeta: ${response.statusCode}');
    }
    return NextcloudFolder.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<NextcloudImage> subirImagen({
    String? folder,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final base = '${ApiConstants.kBaseUrl}/v1/nextcloud/image';
    final uri = (folder != null && folder.isNotEmpty)
        ? Uri.parse('$base?folder=$folder')
        : Uri.parse(base);

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
    final img = NextcloudImage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    final url = _absolute(img.url);
    return url == img.url
        ? img
        : NextcloudImage(
            filename: img.filename,
            folder: img.folder,
            url: url,
            href: img.href,
          );
  }

  @override
  Future<void> eliminarImagen(String imageUrl) async {
    final uri = Uri.parse(_absolute(imageUrl));
    final response = await _client.delete(uri);
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar imagen: ${response.statusCode}');
    }
  }

  @override
  Future<int> eliminarCarpeta(String folder) async {
    final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/nextcloud/folder/$folder');
    final response = await _client.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar carpeta: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['imagenes_eliminadas'] as num?)?.toInt() ?? 0;
  }
}
