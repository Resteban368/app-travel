import 'dart:async';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart';
import 'core/network/session_expired_notifier.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/premium_palette.dart';
import 'core/theme/theme_cubit.dart';
import 'config/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  initDependencies();
  await initializeDateFormatting('es_CO', null);
  await sl<ThemeCubit>().loadSavedTheme();
  runApp(const TravelToursApp());
}

/// Global navigator key — allows showing dialogs from outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TravelToursApp extends StatefulWidget {
  const TravelToursApp({super.key});

  @override
  State<TravelToursApp> createState() => _TravelToursAppState();
}

class _TravelToursAppState extends State<TravelToursApp> {
  StreamSubscription<void>? _sessionSub;
  bool _sessionDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _sessionSub = sl<SessionExpiredNotifier>().stream.listen((_) {
      _showSessionExpiredDialog();
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _showSessionExpiredDialog() {
    if (_sessionDialogVisible) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // No mostrar si ya está en la pantalla de login/splash
    final authState = ctx.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    _sessionDialogVisible = true;

    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: D.surfaceHigh,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: D.rose.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: D.rose.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: D.rose.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: D.rose,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sesión Expirada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu sesión ha expirado o no es válida. Por favor inicia sesión nuevamente para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: D.slate400,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _sessionDialogVisible = false;
                      ctx.read<AuthBloc>().add(const LogoutRequested());
                      // La navegación al login la maneja el BlocListener<AuthBloc>
                      // en AdminShellWrapper al recibir AuthInitial.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: D.rose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Aceptar — Iniciar Sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => _sessionDialogVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    // Solo los BLoCs verdaderamente globales viven en el root:
    // - ThemeCubit: singleton, su tema se carga antes de runApp.
    // - AuthBloc: lo necesitan Splash y Login, que están fuera del shell.
    // Los ~20 BLoCs de feature se proveen dentro de AdminShellWrapper (área
    // autenticada), de modo que se recrean al entrar y se destruyen —con su
    // estado— al hacer logout. Ver ANALISIS_Y_PLAN_MEJORAS.md (Fase 2).
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Agente Viajes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: const Locale('es', 'CO'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es', 'CO'), Locale('en', 'US')],
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
