import 'package:flutter/material.dart';
import 'not_found_screen.dart';

/// Carga una entidad por ID y construye una pantalla con ella.
///
/// Habilita el **deep-linking real** (Fase 3): cuando se entra a una ruta de
/// detalle/edición con el objeto ya en memoria (`arguments`), el router usa esa
/// vía rápida y no llega aquí. Pero al **refrescar la página (F5)** o abrir la
/// URL en una pestaña nueva, `arguments` es `null`; entonces el router delega en
/// este loader, que hace `fetch` por ID y muestra:
///   - un spinner mientras carga,
///   - la pantalla real cuando llega la entidad,
///   - una [NotFoundScreen] si el fetch falla o no existe.
///
/// El `fetch` se dispara una sola vez (guardado en `initState`) para no repetirse
/// en cada rebuild.
class EntityLoader<T> extends StatefulWidget {
  final Future<T> Function() fetch;
  final Widget Function(BuildContext context, T entity) builder;
  final String notFoundMessage;

  const EntityLoader({
    super.key,
    required this.fetch,
    required this.builder,
    this.notFoundMessage = 'No se encontró el recurso solicitado.',
  });

  @override
  State<EntityLoader<T>> createState() => _EntityLoaderState<T>();
}

class _EntityLoaderState<T> extends State<EntityLoader<T>> {
  late final Future<T> _future = widget.fetch();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return NotFoundScreen(message: widget.notFoundMessage);
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}
