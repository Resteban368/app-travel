import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/upload_result.dart';
import '../../domain/repositories/upload_repository.dart';

class ApiUploadRepository implements UploadRepository {
  final http.Client client;

  ApiUploadRepository({required this.client});

  @override
  Future<UploadResult> uploadFile({
    required String folderId,
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.kBaseUrl}/v1/uploads/drive?folderId=$folderId',
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

    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UploadResult(
        fileId: data['fileId'] as String? ?? '',
        url: data['url'] as String? ?? '',
      );
    }

    debugPrint('Upload error: ${response.statusCode} ${response.body}');
    throw Exception(
      'Error al subir archivo: ${response.statusCode} ${response.body}',
    );
  }
}
