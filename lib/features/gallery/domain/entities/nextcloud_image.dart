import 'package:equatable/equatable.dart';

class NextcloudImage extends Equatable {
  final String filename;
  final String folder;
  final String url;
  final String? href;

  const NextcloudImage({
    required this.filename,
    required this.folder,
    required this.url,
    this.href,
  });

  factory NextcloudImage.fromJson(Map<String, dynamic> json) => NextcloudImage(
    filename: json['filename']?.toString() ?? '',
    folder: json['folder']?.toString() ?? '',
    url: json['url']?.toString() ?? '',
    href: json['href']?.toString(),
  );

  // Intenta parsear la fecha si el nombre empieza con timestamp en ms
  // ej: "1704067200000-uuid.jpg"
  DateTime? get uploadedAt {
    final parts = filename.split('-');
    if (parts.isNotEmpty) {
      final ts = int.tryParse(parts.first);
      if (ts != null && ts > 1_000_000_000_000) {
        return DateTime.fromMillisecondsSinceEpoch(ts);
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [filename, folder, url, href];
}
