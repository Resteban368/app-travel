import 'package:equatable/equatable.dart';
import 'nextcloud_folder.dart';
import 'nextcloud_image.dart';

class NextcloudBrowseResult extends Equatable {
  /// null = raíz del usuario
  final String? folder;
  final List<NextcloudFolder> subfolders;
  final List<NextcloudImage> images;

  const NextcloudBrowseResult({
    this.folder,
    required this.subfolders,
    required this.images,
  });

  factory NextcloudBrowseResult.fromJson(
    Map<String, dynamic> json, {
    required String Function(String) normalizeUrl,
  }) {
    // API v2 usa "path"; v1 usaba "folder"
    final rawFolder = (json['path'] ?? json['folder'])?.toString();
    final parent = (rawFolder == null || rawFolder.isEmpty) ? null : rawFolder;

    final subfolders = _parseFolders(
      json['subfolders'] ?? json['folders'] ?? json['subdirectories'],
      parent,
    );

    final images = _parseImages(json['images'], normalizeUrl);

    return NextcloudBrowseResult(
      folder: parent,
      subfolders: subfolders,
      images: images,
    );
  }

  @override
  List<Object?> get props => [folder, subfolders, images];
}

/// Parsea la lista de subcarpetas aceptando objetos {ncPath|folder} o strings.
/// Normaliza rutas relativas a absolutas usando [parent].
List<NextcloudFolder> _parseFolders(dynamic raw, String? parent) {
  if (raw == null || raw is! List) return const [];
  return raw
      .map<NextcloudFolder?>((item) {
        String nombre;
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          nombre = (m['ncPath'] ??
                      m['folder'] ??
                      m['path'] ??
                      m['name'] ??
                      m['nombre'] ??
                      m['folderName'] ??
                      m['dirName'])
                  ?.toString() ??
              '';
        } else if (item is String) {
          nombre = item;
        } else {
          return null;
        }
        if (nombre.isEmpty) return null;
        // Si la ruta es relativa (no contiene '/'), la hace absoluta con parent
        if (parent != null && !nombre.contains('/')) {
          nombre = '$parent/$nombre';
        }
        return NextcloudFolder(nombre: nombre);
      })
      .whereType<NextcloudFolder>()
      .toList();
}

/// Parsea la lista de imágenes aceptando objetos con url.
List<NextcloudImage> _parseImages(
  dynamic raw,
  String Function(String) normalizeUrl,
) {
  if (raw == null || raw is! List) return const [];
  return raw
      .map<NextcloudImage?>((item) {
        if (item is! Map) return null;
        final m = Map<String, dynamic>.from(item);
        final img = NextcloudImage.fromJson(m);
        if (img.url.isEmpty) return null;
        final url = normalizeUrl(img.url);
        return url == img.url
            ? img
            : NextcloudImage(
                filename: img.filename,
                folder: img.folder,
                url: url,
                href: img.href,
              );
      })
      .whereType<NextcloudImage>()
      .toList();
}
