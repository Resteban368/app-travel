import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildPlatformNetworkImage(
  String url, {
  double height = 300,
  BoxFit fit = BoxFit.contain,
}) {
  if (url.isEmpty) return SizedBox(height: height);

  // Use url hashCode as view type ID. The try/catch handles the case where
  // the factory is already registered (e.g. widget rebuilds).
  final viewType = 'net-img-${url.hashCode}';

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
