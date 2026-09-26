import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Observador global de BLoCs para diagnóstico.
///
/// Registra en consola cada evento, transición y error de TODOS los BLoCs/Cubits
/// de la app. Sirve para cazar el bug de "la app queda cargando": si un BLoC
/// emite un estado `*Loading` y nunca aparece la transición siguiente, ese es el
/// que dejó el spinner girando (una petición HTTP colgada o un error tragado).
///
/// Solo emite en modo debug (`flutter run`) — en release no imprime nada.
/// Se activa asignándolo a `Bloc.observer` en `main()`.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!kDebugMode) return;
    debugPrint('🟦 EVENT   ${bloc.runtimeType} → ${event.runtimeType}');
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;
    debugPrint(
      '🔀 STATE   ${bloc.runtimeType}: '
      '${transition.currentState.runtimeType} → '
      '${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!kDebugMode) return;
    debugPrint('🟥 ERROR   ${bloc.runtimeType}: $error');
    debugPrint(stackTrace.toString());
  }
}
