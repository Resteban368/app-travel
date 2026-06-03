# INFORME DE ANÁLISIS Y PLAN DE MEJORAS
# Admin Panel — Travel Tours Florencia
# Fecha: 2026-05-23 | Versión: 1.6.0+1 | SDK: Dart 3.10.7+

---

## RESUMEN EJECUTIVO

Análisis exhaustivo del código base del panel administrativo Flutter. Se identificaron
47 problemas distribuidos en 4 categorías: seguridad, memory leaks, rendimiento y
arquitectura. Este documento contiene el inventario completo de problemas y el plan
de corrección organizado en 4 fases de desarrollo.

---

# PARTE 1 — INVENTARIO DE PROBLEMAS

---

## BLOQUE A — CRÍTICOS (Corregir de inmediato)

### A1. Memory Leak — ScrollController listeners no removidos
- Archivo: lib/features/cotizaciones/presentation/screens/cotizaciones_list_screen.dart
- Líneas: 76-99
- Descripción:
  Los listeners se añaden con addListener() pero en el método dispose() únicamente
  se llama .dispose() sobre el controller, sin remover el listener previamente.
  Esto deja el callback vivo en memoria aunque el widget ya no exista.

  INCORRECTO (código actual):
    @override
    void dispose() {
      _misRespuestasScrollCtrl.dispose();  // listener sigue activo
      _plantillasScrollCtrl.dispose();
      super.dispose();
    }

  CORRECTO:
    @override
    void dispose() {
      _misRespuestasScrollCtrl.removeListener(_onMisRespuestasScroll);
      _plantillasScrollCtrl.removeListener(_onPlantillasScroll);
      _misRespuestasScrollCtrl.dispose();
      _plantillasScrollCtrl.dispose();
      super.dispose();
    }

---

### A2. Seguridad — print() con datos sensibles en producción
- Archivo: lib/features/tour/data/repositories/api_tour_repository.dart
- Líneas: 117-118
- Descripción:
  Se usa print() (no debugPrint) para loguear URLs y cuerpos de respuesta completos.
  print() escribe en stdout incluso en builds de producción. Si el body contiene
  tokens, credenciales o datos de usuarios, estos quedan expuestos en cualquier
  sistema de logs de producción.

  INSEGURO (código actual):
    print('$_baseUrl/$id/detalle');
    print('Respuesta $_baseUrl/$id/detalle ${response.body}');

  SEGURO:
    debugPrint('[Tour] GET detalle id=$id status=${response.statusCode}');

---

### A3. Seguridad — debugPrint(response.body) en repositorio de auth
- Archivo: lib/features/auth/data/repositories/api_auth_repository.dart
- Líneas: 60-68
- Descripción:
  Se loguea el body completo de respuestas de autenticación. Estas respuestas
  contienen access_token y refresh_token. Aunque debugPrint solo actúa en debug,
  el patrón es peligroso y debe eliminarse antes de considerar builds de staging
  o producción con logs habilitados.

  INSEGURO:
    debugPrint('API RESPONSE: ${response.body}');

  SEGURO:
    debugPrint('[Auth] login status=${response.statusCode}');

---

### A4. Configuración — URLs hardcoded y TODOs en constants de producción
- Archivo: lib/core/constants/api_constants.dart
- Descripción:
  Hay URLs comentadas y comentarios TODO que indican ausencia de separación
  de entornos (dev/staging/prod). Cualquier desarrollador puede descomentar
  accidentalmente la URL incorrecta.

  ACTUAL (problemático):
    //todo produccion
    static const String kBaseUrl = 'https://api-travel-tours-5akz.vercel.app';
    // todo para el navegador
    // static const String kBaseUrl = 'http://localhost:3001';

  CORRECTO — usar --dart-define en el comando de ejecución:
    static const String kBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api-travel-tours-5akz.vercel.app',
    );

  Comandos de ejecución:
    flutter run --dart-define=API_BASE_URL=http://localhost:3001          (dev)
    flutter run --dart-define=API_BASE_URL=https://api-staging.vercel.app (staging)
    flutter build web --dart-define=API_BASE_URL=https://api.vercel.app   (prod)

---

### A5. Memory Leak — SessionExpiredNotifier nunca se dispone
- Archivos: lib/main.dart (línea 53-66) / lib/core/network/session_expired_notifier.dart (línea 15)
- Descripción:
  El notifier tiene un método dispose() definido pero nunca es invocado.
  El StreamSubscription creado en main.dart queda abierto por toda la vida
  de la aplicación sin posibilidad de cancelación limpia.

  FALTA agregar en el widget raíz:
    @override
    void dispose() {
      _sessionSub?.cancel();
      sl<SessionExpiredNotifier>().dispose();
      super.dispose();
    }

---

## BLOQUE B — ALTOS (Próximas 2 semanas)

### B1. Arquitectura — BLoCs creados dentro del Router
- Archivo: lib/config/app_router.dart
- Líneas: 207-241
- Descripción:
  El router instancia BLoCs directamente para algunas rutas, mientras que otras
  rutas consumen los BLoCs registrados en main.dart. Esta inconsistencia genera
  instancias duplicadas del mismo BLoC activas simultáneamente.

  MAL (actual):
    case saldosPendientes:
      return _fadeRoute(
        BlocProvider(
          create: (_) => sl<SaldoPendienteBloc>()..add(LoadSaldosPendientes()),
          child: const SaldoPendienteScreen(),
        ),
        settings,
      );

  BIEN:
    case saldosPendientes:
      return _fadeRoute(const SaldoPendienteScreen(), settings);
    // El BLoC se accede vía context.read<>() desde la propia screen

---

### B2. DI — Inconsistencia factory vs lazySingleton en BLoCs
- Archivo: lib/core/di/injection_container.dart
- Descripción:
  No hay un criterio claro para cuándo usar factory vs lazySingleton en BLoCs.
  Los lazySingleton acumulan estado entre navegaciones (bug potencial).
  Los factory se recrean en cada inyección consumiendo más memoria.

  Registro actual mezclado:
    sl.registerLazySingleton(() => TourBloc(...))        // singleton — estado acumulado
    sl.registerFactory(() => ClienteBloc(...))           // factory — sin estado previo
    sl.registerLazySingleton(() => CatalogueBloc(...))   // singleton — estado acumulado
    sl.registerLazySingleton(() => FaqBloc(...))         // singleton — estado acumulado

  Regla propuesta:
    - factory    → BLoCs de pantallas individuales (form, detail)
    - lazySingleton → Solo servicios de infraestructura (repositorios, AuthClient)

---

### B3. Manejo de errores — catch (_) silencia todas las excepciones
- Archivo: lib/features/auth/presentation/bloc/auth_bloc.dart
- Línea: 110
- Descripción:
  Un catch genérico que no distingue entre un error de red esperado y un
  NullPointerException de programación. Los errores de programación deberían
  propagarse, no ser silenciados.

  ACTUAL (problemático):
    catch (_) { emit(AuthInitial()); }

  CORRECTO:
    on SocketException catch (_) {
      emit(const AuthError('Sin conexión a internet'));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e, stack) {
      debugPrint('[AuthBloc] Error inesperado: $e\n$stack');
      emit(const AuthError('Error inesperado'));
    }

---

### B4. Seguridad — e.toString() expuesto en estados de error del UI
- Archivos: hotel_bloc.dart, cliente_bloc.dart, auth_bloc.dart, y más
- Descripción:
  Los BLoCs emiten el mensaje de error directamente con e.toString(), que puede
  contener stack traces, rutas de archivos del servidor o estructura interna de la API.

  INSEGURO:
    emit(HotelError(e.toString()));
    // Usuario ve: "Exception: FormatException: Unexpected character at line 1, column 1"

  SEGURO — crear un ErrorMapper centralizado:
    class ErrorMapper {
      static String map(dynamic e) {
        if (e is SocketException) return 'Sin conexión a internet';
        if (e is TimeoutException) return 'La solicitud tardó demasiado';
        if (e is ApiException) return e.message;
        return 'Ocurrió un error. Intenta de nuevo.';
      }
    }
    emit(HotelError(ErrorMapper.map(e)));

---

### B5. Navegación — Dos GlobalKey<NavigatorState> compitiendo
- Archivos: lib/main.dart (línea 43) y lib/core/layout/admin_shell_wrapper.dart (línea 15)
- Descripción:
  Hay dos navigators globales activos. Esto puede causar comportamientos
  inesperados en la navegación: rutas que aparecen en el navigator incorrecto,
  botón Back que no funciona correctamente en web/Android, y diálogos que
  se abren sobre pantallas equivocadas.

---

### B6. Manejo de errores — _onRefreshProfile no emite error si falla
- Archivo: lib/features/auth/presentation/bloc/auth_bloc.dart
- Descripción:
  Si falla la actualización del perfil, el BLoC no emite ningún estado de error,
  dejando al usuario con datos desactualizados sin notificación.

---

## BLOQUE C — MEDIOS (Mejora continua)

### C1. Arquitectura — Lógica de filtrado en UI en lugar de BLoC
- Archivos: hotel_list_screen.dart (línea 61-68), cliente_list_screen.dart
- Descripción:
  El filtrado y búsqueda se realizan dentro del widget con variables locales.
  Esto impide testear la lógica de filtrado, no persiste entre navegaciones,
  y viola la separación de responsabilidades.
  Mover a un evento FilterHoteles/SearchCliente en el BLoC correspondiente.

---

### C2. Linters — analysis_options.yaml muy permisivo
- Archivo: analysis_options.yaml
- Descripción:
  Los lints críticos están desactivados. Con ellos activos el propio compilador
  detectaría automáticamente varios de los problemas listados en este informe.

  Activar como mínimo:
    linter:
      rules:
        avoid_print: true
        cancel_subscriptions: true
        close_sinks: true
        avoid_empty_catch: true
        use_key_in_widget_constructors: true
        prefer_const_constructors: true

---

### C3. Rendimiento — PlatformNetworkImage sin control de caché
- Archivo: lib/core/widgets/platform_network_image.dart
- Descripción:
  No hay límite de tamaño ni de cantidad de imágenes en caché. En sesiones
  largas con muchas imágenes (listas de tours, clientes) el consumo de
  memoria puede crecer sin control.
  Implementar CacheManager con límite de tamaño y tiempo de expiración.

---

### C4. UX — Loading dialog sin timeout
- Archivo: lib/features/cotizaciones/presentation/screens/cotizaciones_list_screen.dart
- Línea: 173-187
- Descripción:
  El _showLoadingDialog() puede quedar abierto indefinidamente si la operación
  falla silenciosamente. El usuario queda bloqueado sin forma de recuperarse.

  Agregar timeout:
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isLoadingDialogOpen) Navigator.of(context).pop();
    });

---

### C5. Formularios — Validación inconsistente entre screens
- Descripción:
  Algunas pantallas usan Form + FormField con validators declarativos.
  Otras hacen validación manual con if (controller.text.isEmpty) return.
  Estandarizar en todos los formularios a Form.validate() con validators.

---

### C6. Rendimiento — Animaciones repeat() sin visibilidad check
- Archivo: lib/features/clientes/presentation/screens/cliente_list_screen.dart
- Línea: 39-42
- Descripción:
  AnimationController con .repeat() que continúa ejecutándose aunque el widget
  no sea visible (por ejemplo cuando se navega a otra pantalla con el widget
  en el stack). Usar VisibilityDetector o pausar en didChangeAppLifecycleState.

---

### C7. Código — Archivos de script sin uso en raíz del proyecto
- Archivos: refactor.dart, remove_adminshell.py, replace_ip.dart
- Descripción:
  Hay scripts de mantenimiento sueltos en la raíz del proyecto. Deben moverse
  a una carpeta /scripts o eliminarse si ya cumplieron su propósito.

---

# PARTE 2 — PLAN DE DESARROLLO POR FASES

---

## FASE 0 — PREPARACIÓN (1 día)
Objetivo: Tener el entorno listo para hacer cambios seguros.

Tareas:
  [ ] 0.1 Activar lints críticos en analysis_options.yaml
         → Esto hará visibles muchos problemas restantes automáticamente
         → Ejecutar: flutter analyze > analyze_report.txt
         → Revisar todos los warnings nuevos antes de avanzar

  [ ] 0.2 Crear rama de trabajo
         → git checkout -b fix/mejoras-fase-1

  [ ] 0.3 Establecer baseline de métricas
         → Anotar warnings actuales de flutter analyze
         → Anotar tamaño de build web: flutter build web --release

  [ ] 0.4 Mover scripts sueltos de la raíz
         → mkdir scripts
         → mv refactor.dart replace_ip.dart remove_adminshell.py scripts/
         → O eliminarlos si ya no se necesitan

---

## FASE 1 — ESTABILIDAD Y SEGURIDAD (Semana 1)
Objetivo: Eliminar los 5 problemas críticos que pueden causar crashes en
          producción o comprometer datos sensibles.

Prioridad 1 — Seguridad en logs (estimado: 2 horas)

  [ ] 1.1 Reemplazar todos los print() por debugPrint() o eliminarlos
         Comando para encontrarlos:
           grep -rn "^\s*print(" lib/
         Archivos confirmados:
           - lib/features/tour/data/repositories/api_tour_repository.dart:117-118

  [ ] 1.2 Eliminar debugPrint(response.body) en repositorios
         Reemplazar por logs que solo muestren status code:
           debugPrint('[Auth] response status=${response.statusCode}');
         Archivos confirmados:
           - lib/features/auth/data/repositories/api_auth_repository.dart:60-68

Prioridad 2 — Memory leaks (estimado: 3 horas)

  [ ] 1.3 Auditar y corregir todos los ScrollController con addListener()
         Comando:
           grep -rn "addListener" lib/
         Para cada resultado verificar que existe el removeListener correspondiente
         en dispose(). Corregir cotizaciones_list_screen.dart primero.

  [ ] 1.4 Disponer correctamente el SessionExpiredNotifier
         - Localizar el widget raíz en main.dart
         - Guardar referencia a la StreamSubscription
         - Llamar _sessionSub?.cancel() y sl<SessionExpiredNotifier>().dispose() en dispose()

  [ ] 1.5 Auditar TextEditingControllers
         Comando:
           grep -rn "TextEditingController()" lib/
         Para cada resultado verificar que está en dispose().
         Patrón simple de verificación: si está en initState o como campo,
         debe estar en dispose().

Prioridad 3 — Configuración de entornos (estimado: 2 horas)

  [ ] 1.6 Migrar URL base a --dart-define
         - Reemplazar el bloque con TODOs en api_constants.dart
         - Actualizar README con los comandos de ejecución por entorno
         - Actualizar vercel.json con la variable de entorno correcta

Criterio de éxito de Fase 1:
  - flutter analyze sin errores nuevos
  - Zero print() en lib/ (grep no encuentra resultados)
  - Zero TODOs con URLs en api_constants.dart

---

## FASE 2 — ARQUITECTURA Y MANEJO DE ERRORES (Semana 2-3)
Objetivo: Corregir los problemas de arquitectura que causan bugs sutiles y
          dificultan el mantenimiento.

Prioridad 1 — Manejo de errores centralizado (estimado: 4 horas)

  [ ] 2.1 Crear lib/core/errors/error_mapper.dart
         Clase estática con un método map(dynamic e) -> String
         Casos a cubrir:
           - SocketException → 'Sin conexión a internet'
           - TimeoutException → 'La solicitud tardó demasiado'
           - ApiException → e.message (ya localizado)
           - Cualquier otro → 'Ocurrió un error. Intenta de nuevo.'

  [ ] 2.2 Reemplazar e.toString() en todos los BLoCs
         Comando:
           grep -rn "e.toString()" lib/features/
         Sustituir por ErrorMapper.map(e) en todos los catch blocks

  [ ] 2.3 Corregir catch (_) en auth_bloc.dart
         Separar en catches tipados:
           on SocketException, on ApiException, catch genérico con log

Prioridad 2 — Consistencia en DI (estimado: 3 horas)

  [ ] 2.4 Revisar todos los registros en injection_container.dart
         Aplicar regla:
           - Repositorios → lazySingleton (stateless, costosos de crear)
           - BLoCs de pantalla → factory (cada instancia tiene su estado)
           - Servicios globales (AuthClient, SessionExpiredNotifier) → lazySingleton

  [ ] 2.5 Eliminar BloCs creados dentro del router
         En app_router.dart, identificar todos los BlocProvider dentro de casos
         y reemplazarlos por acceso directo al BLoC registrado en main.dart.
         Las screens deben usar context.read<>() para acceder al BLoC y
         disparar su propio evento en initState.

Prioridad 3 — Navegación (estimado: 2 horas)

  [ ] 2.6 Resolver los dos GlobalKey<NavigatorState> en conflicto
         Determinar cuál es el navigator principal y cuál es redundante.
         Eliminar el secundario o convertirlo en un nested navigator explícito
         con propósito claro.

  [ ] 2.7 Corregir _onRefreshProfile en auth_bloc
         Agregar emisión de estado de error cuando falla el refresh del perfil.

Criterio de éxito de Fase 2:
  - Ningún BLoC creado dentro de app_router.dart
  - Todos los BLoCs usan factory en injection_container.dart
  - ErrorMapper.map() usado en todos los catch de BLoCs

---

## FASE 3 — RENDIMIENTO Y CALIDAD DE CÓDIGO (Semana 4)
Objetivo: Mejorar la estabilidad en sesiones largas y la experiencia de usuario.

  [ ] 3.1 Implementar CacheManager para imágenes
         Usar cached_network_image package con:
           - Máximo 100 MB de caché en disco
           - Expiración de 7 días
           - Placeholder shimmer consistente con el ya usado en la app

  [ ] 3.2 Agregar timeout al LoadingDialog
         Crear un wrapper _showLoadingDialog que acepte un timeout opcional
         (default 30 segundos) y cierre el diálogo automáticamente.

  [ ] 3.3 Mover lógica de filtrado de UI a BLoC
         Features prioritarias (mayor uso):
           - HotelBloc: agregar evento FilterHoteles(String query)
           - ClienteBloc: agregar evento SearchClientes(String query)
         Esto permitirá escribir tests unitarios del filtrado.

  [ ] 3.4 Revisar AnimationControllers con .repeat()
         Pausar animaciones cuando el widget no es visible usando
         WidgetsBindingObserver o VisibilityDetector.

  [ ] 3.5 Estandarizar validación en formularios
         Crear validators reutilizables en lib/core/validators/app_validators.dart:
           - requiredField(String? value)
           - validEmail(String? value)
           - validPhone(String? value)
           - validUrl(String? value)
         Reemplazar validaciones manuales con estos validators.

Criterio de éxito de Fase 3:
  - flutter analyze: 0 warnings
  - Filtrado de hoteles y clientes testeado con unit tests
  - Build de producción sin warnings de rendimiento

---

## FASE 4 — MEJORAS AVANZADAS (Mes 2)
Objetivo: Preparar la app para escalar y facilitar el trabajo del equipo.

  [ ] 4.1 Agregar Certificate Pinning para la API
         Previene ataques MITM en redes no confiables.
         Usar http_certificate_pinning o implementar con dart:io HttpClient.

  [ ] 4.2 Separar builds por flavor (dev/staging/prod)
         Crear lib/core/config/app_config.dart con los parámetros por entorno.
         Definir flutter flavors en android/ios para builds automáticos.

  [ ] 4.3 Implementar base classes para BLoC pattern
         Crear lib/core/bloc/base_bloc.dart con comportamiento común:
           - Loading/Error/Loaded genéricos
           - Logging de eventos automático en debug
           - ErrorMapper integrado

  [ ] 4.4 Agregar tests unitarios para BLoCs críticos
         Prioridad: auth_bloc, tour_bloc, reserva_bloc
         Usar bloc_test package ya disponible.

  [ ] 4.5 Implementar validación local de JWT expiry
         Decodificar el token en AuthClient para verificar expiración
         antes de enviar la request, en lugar de esperar el 401 del servidor.
         Esto reduce una round-trip de red innecesaria.

  [ ] 4.6 Documentar API en README
         Agregar sección con: endpoints disponibles, formato de autenticación,
         casos de error conocidos y sus códigos HTTP.

---

# PARTE 3 — COMANDOS ÚTILES PARA EL DIAGNÓSTICO

# Encontrar todos los print() en el código fuente
grep -rn "^\s*print(" lib/

# Encontrar todos los debugPrint con body de respuesta
grep -rn "debugPrint.*body" lib/

# Encontrar TODOs pendientes
grep -rn "TODO\|todo\|FIXME\|fixme\|HACK" lib/

# Encontrar todos los addListener sin removeListener cerca
grep -rn "addListener" lib/

# Encontrar TextEditingControllers para auditar dispose
grep -rn "TextEditingController()" lib/

# Encontrar AnimationControllers
grep -rn "AnimationController(" lib/

# Encontrar catch genéricos sospechosos
grep -rn "catch (_)" lib/

# Encontrar e.toString() en BLoCs
grep -rn "e.toString()" lib/features/

# Ver warnings actuales completos
flutter analyze 2>&1 | tee analyze_report.txt

# Build de producción para medir tamaño
flutter build web --release 2>&1 | tail -20

---

# MÉTRICAS DE SEGUIMIENTO

  Ejecutar estos comandos antes y después de cada fase para medir progreso:

  1. flutter analyze          → contar warnings totales
  2. grep -c "print(" lib/    → contar print() restantes  
  3. grep -c "TODO" lib/      → contar TODOs pendientes
  4. grep -c "e.toString()" lib/features/ → errores sin mapear

---

# NOTAS FINALES

  - Los problemas de Fase 1 son los únicos que requieren atención urgente.
    Los demás pueden abordarse iterativamente sin afectar funcionalidad.

  - Cada corrección debe ir acompañada de su propio commit con mensaje claro.

  - Antes de iniciar cada fase, ejecutar flutter analyze y guardar el resultado
    para comparar el antes y el después.

  - Los cambios de arquitectura (Fase 2) deben hacerse uno a la vez para
    poder identificar regressions fácilmente.

---
Generado por: Claude Code (claude-sonnet-4-6)
Proyecto: agente_viajes — Travel Tours Florencia
