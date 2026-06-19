import 'package:equatable/equatable.dart';

class NextcloudFolder extends Equatable {
  final String nombre;

  const NextcloudFolder({required this.nombre});

  factory NextcloudFolder.fromJson(Map<String, dynamic> json) =>
      // API v2 usa "ncPath"; v1 usaba "folder"
      NextcloudFolder(
        nombre: (json['ncPath'] ?? json['folder'])?.toString() ?? '',
      );

  @override
  List<Object?> get props => [nombre];
}
