import 'package:flutter/material.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';

/// Muestra una imagen de red con indicador de carga y placeholder de error.
/// Usa Image.network() para aprovechar la caché nativa del browser y evitar
/// CORS preflight que ocurre al enviar headers Authorization en recursos públicos.
///
/// **Performance (Fase 4):** decodifica la imagen al tamaño en el que se muestra
/// (`cacheWidth`/`cacheHeight`) en vez de a resolución completa. Si no se
/// especifican, se derivan de `width`/`height` × `devicePixelRatio`. Esto evita
/// que una foto de 4000 px se decodifique entera para un thumbnail de 80 px —
/// clave en grids/listas con muchas imágenes (galería, tours).
class AuthNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Ancho de decodificación en píxeles físicos. Si es null se deriva de
  /// `width × devicePixelRatio`.
  final int? cacheWidth;

  /// Alto de decodificación en píxeles físicos. Solo se usa si no hay un
  /// `cacheWidth` efectivo (para no distorsionar el aspect ratio al decodificar).
  final int? cacheHeight;

  const AuthNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final resolvedCacheWidth = cacheWidth ??
        ((width != null && width!.isFinite) ? (width! * dpr).round() : null);
    // Solo aplicamos cacheHeight cuando no hay un ancho por el que cortar, para
    // preservar la relación de aspecto en la decodificación.
    final resolvedCacheHeight = resolvedCacheWidth == null
        ? (cacheHeight ??
            ((height != null && height!.isFinite)
                ? (height! * dpr).round()
                : null))
        : null;

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: resolvedCacheWidth,
      cacheHeight: resolvedCacheHeight,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF1F5F9),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.saas.brand600,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF1F5F9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: context.saas.textTertiary,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sin vista previa',
                  style: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
