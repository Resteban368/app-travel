import 'package:flutter/material.dart';

/// Pantalla 404 para rutas desconocidas o recursos inexistentes.
///
/// Reemplaza el antiguo fallback silencioso a `ProfileScreen` en
/// `onGenerateNestedRoute`: ahora una ruta inválida es visible y el usuario
/// tiene una salida clara en vez de aparecer en su perfil sin explicación.
class NotFoundScreen extends StatelessWidget {
  final String message;

  const NotFoundScreen({
    super.key,
    this.message = 'La página que buscas no existe o fue movida.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 72,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Página no encontrada',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    if (nav.canPop()) {
                      nav.pop();
                    } else {
                      // Ruta literal para no acoplar esta pantalla al grafo
                      // completo de AppRouter (que arrastra dependencias web).
                      nav.pushReplacementNamed('/dashboard');
                    }
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
