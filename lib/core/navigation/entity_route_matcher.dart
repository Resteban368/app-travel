import 'package:flutter/widgets.dart' show RouteSettings;

/// Lógica **pura** de navegación de la Fase 3 (sin dependencias de pantallas),
/// para poder testearla en la VM de `flutter test` sin arrastrar `dart:html`.

/// Ruta cuyo path lleva el ID de la entidad: `/tours/123/edit`.
class EntityRoute {
  /// `tours` | `reservas` | `clientes`
  final String resource;

  /// Segmento crudo del ID (sin parsear).
  final String id;

  /// `edit` | `detalle` | `historial`
  final String action;

  const EntityRoute(this.resource, this.id, this.action);

  @override
  bool operator ==(Object other) =>
      other is EntityRoute &&
      other.resource == resource &&
      other.id == id &&
      other.action == action;

  @override
  int get hashCode => Object.hash(resource, id, action);

  @override
  String toString() => 'EntityRoute($resource/$id/$action)';
}

/// Parsea un nombre de ruta con la forma `/{resource}/{id}/{action}`.
/// Devuelve `null` si no encaja (rutas de lista, estáticas o desconocidas),
/// para que el router caiga a su switch de rutas estáticas.
EntityRoute? parseEntityRoute(String? routeName) {
  final segments = Uri.parse(routeName ?? '').pathSegments;
  if (segments.length != 3) return null;
  final id = segments[1];
  if (id.isEmpty) return null;
  return EntityRoute(segments[0], id, segments[2]);
}

/// Extrae `arguments` como [T] de forma segura: devuelve `null` en vez de lanzar
/// cuando el argumento falta o es de otro tipo (p. ej. tras un F5, donde
/// `arguments` llega `null`). Ninguna ruta debe hacer `as T` a pelo.
T? argOf<T>(RouteSettings settings) {
  final args = settings.arguments;
  return args is T ? args : null;
}
