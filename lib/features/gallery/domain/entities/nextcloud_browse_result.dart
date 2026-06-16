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
    final rawFolder = json['folder']?.toString();
    final parent = (rawFolder == null || rawFolder.isEmpty) ? null : rawFolder;

    final allSubfolders = (json['subfolders'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(NextcloudFolder.fromJson)
        .toList();

    // El backend puede devolver la lista plana global; filtramos a hijos directos.
    final subfolders = _directChildren(allSubfolders, parent);

    return NextcloudBrowseResult(
      folder: parent,
      subfolders: subfolders,
      images: (json['images'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(NextcloudImage.fromJson)
          .map((img) {
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
          .toList(),
    );
  }

  @override
  List<Object?> get props => [folder, subfolders, images];
}

/// Retorna solo los hijos directos de [parent] dentro de la lista plana.
/// Para raíz (parent == null): carpetas sin '/'.
/// Para una ruta dada: carpetas que empiezan con 'parent/' y no tienen '/' adicional.
List<NextcloudFolder> _directChildren(
  List<NextcloudFolder> all,
  String? parent,
) {
  if (parent == null || parent.isEmpty) {
    return all.where((f) => !f.nombre.contains('/')).toList();
  }
  final prefix = '$parent/';
  return all
      .where((f) =>
          f.nombre.startsWith(prefix) &&
          !f.nombre.substring(prefix.length).contains('/'))
      .toList();
}
