import 'dart:typed_data';
import '../entities/upload_result.dart';

abstract class UploadRepository {
  /// Uploads [bytes] as [filename] to the given Drive [folderId].
  Future<UploadResult> uploadFile({
    required String folderId,
    required String filename,
    required Uint8List bytes,
    required String mimeType,
  });
}
