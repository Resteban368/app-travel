import 'package:flutter/material.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';

/// Muestra una imagen de red con indicador de carga y placeholder de error.
/// Usa Image.network() para aprovechar la caché nativa del browser y evitar
/// CORS preflight que ocurre al enviar headers Authorization en recursos públicos.
class AuthNetworkImage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
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
                SizedBox(height: 2),
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
