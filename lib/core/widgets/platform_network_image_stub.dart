import 'package:agente_viajes/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Widget buildPlatformNetworkImage(
  String url, {
  double height = 300,
  BoxFit fit = BoxFit.contain,
}) {
  if (url.isEmpty) return SizedBox(height: height);

  return Image.network(
    url,
    height: height,
    fit: fit,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return SizedBox(
        height: height,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColors.cobalt),
          ),
        ),
      );
    },
    errorBuilder: (_, _, _) => Container(
      height: 200,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image_rounded,
        size: 48,
        color: AppColors.grey,
      ),
    ),
  );
}
