import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildPlatformNetworkImage(
  String url, {
  double height = 300,
  BoxFit fit = BoxFit.contain,
  String id = '0',
}) {
  if (url.isEmpty) return SizedBox(height: height);

  // Combine url + id so the same URL used in different contexts (e.g. main
  // preview and thumbnail) gets separate platform views without colliding.
  final viewType = 'net-img-${url.hashCode}-$id';

  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (_) {
      final objectFitValue = switch (fit) {
        BoxFit.cover => 'cover',
        BoxFit.fill => 'fill',
        BoxFit.fitWidth => 'scale-down',
        BoxFit.fitHeight => 'scale-down',
        _ => 'contain',
      };

      final img = web.HTMLImageElement();
      img.src = url;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = objectFitValue;
      img.style.display = 'block';
      return img;
    });
  } catch (_) {
    // Factory already registered — safe to ignore.
  }

  return SizedBox(
    height: height,
    width: double.infinity,
    child: HtmlElementView(viewType: viewType),
  );
}
