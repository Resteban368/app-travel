import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/di/injection_container.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';

/// Muestra una imagen que requiere autenticación JWT.
/// Usa [sl<http.Client>()] (AuthClient) para hacer GET con el token.
/// Cache estático en memoria para la sesión.
class AuthNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AuthNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  static final Map<String, Uint8List> _cache = {};

  @override
  State<AuthNetworkImage> createState() => _AuthNetworkImageState();
}

class _AuthNetworkImageState extends State<AuthNetworkImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(AuthNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _load();
      setState(() {});
    }
  }

  Future<Uint8List?> _load() async {
    if (AuthNetworkImage._cache.containsKey(widget.url)) {
      return AuthNetworkImage._cache[widget.url];
    }
    try {
      final resp = await sl<http.Client>().get(Uri.parse(widget.url));
      if (resp.statusCode == 200) {
        AuthNetworkImage._cache[widget.url] = resp.bodyBytes;
        return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: FutureBuilder<Uint8List?>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SaasPalette.brand600,
                  ),
                ),
              ),
            );
          }
          if (snap.data == null) {
            return Container(
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: SaasPalette.textTertiary,
                      size: 22,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sin vista previa',
                      style: TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return Image.memory(
            snap.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            gaplessPlayback: true,
          );
        },
      ),
    );
  }
}
