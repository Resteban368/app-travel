import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();
  @override
  List<Object?> get props => [];
}

class CargarGallery extends GalleryEvent {
  final String folder;
  const CargarGallery(this.folder);
  @override
  List<Object?> get props => [folder];
}

class SubirImagenGallery extends GalleryEvent {
  final String folder;
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  const SubirImagenGallery({
    required this.folder,
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
  @override
  List<Object?> get props => [folder, filename, mimeType];
}

class EliminarImagenGallery extends GalleryEvent {
  final String folder;
  final String filename;
  final String imageUrl;
  const EliminarImagenGallery({
    required this.folder,
    required this.filename,
    required this.imageUrl,
  });
  @override
  List<Object?> get props => [folder, filename, imageUrl];
}
