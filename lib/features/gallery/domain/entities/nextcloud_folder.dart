import 'package:equatable/equatable.dart';

class NextcloudFolder extends Equatable {
  final String nombre;

  const NextcloudFolder({required this.nombre});

  factory NextcloudFolder.fromJson(Map<String, dynamic> json) =>
      NextcloudFolder(nombre: json['folder']?.toString() ?? '');

  @override
  List<Object?> get props => [nombre];
}
