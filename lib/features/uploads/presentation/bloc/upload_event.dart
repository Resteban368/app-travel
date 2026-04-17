import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();
  @override
  List<Object?> get props => [];
}

class UploadFile extends UploadEvent {
  final String folderId;
  final String filename;
  final Uint8List bytes;
  final String mimeType;

  const UploadFile({
    required this.folderId,
    required this.filename,
    required this.bytes,
    required this.mimeType,
  });

  @override
  List<Object?> get props => [folderId, filename, mimeType];
}

class ResetUpload extends UploadEvent {
  const ResetUpload();
}
