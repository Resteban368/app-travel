import 'package:equatable/equatable.dart';

class UploadResult extends Equatable {
  final String fileId;
  final String url;

  const UploadResult({required this.fileId, required this.url});

  @override
  List<Object?> get props => [fileId, url];
}
