import 'dart:async';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/payment_method_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/sede_bloc.dart';
import 'package:agente_viajes/features/catalogue/presentation/bloc/catalogue_bloc.dart';
import 'package:agente_viajes/features/faq/presentation/bloc/faq_bloc.dart';
import 'package:agente_viajes/features/service/presentation/bloc/service_bloc.dart';
import 'package:agente_viajes/features/politica_reserva/presentation/bloc/politica_reserva_bloc.dart';
import 'package:agente_viajes/features/info_empresa/presentation/bloc/info_empresa_bloc.dart';
import 'package:agente_viajes/features/pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import 'package:agente_viajes/features/whatsapp/presentation/bloc/whatsapp_bloc.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_bloc.dart';
import 'package:agente_viajes/features/reservas/presentation/bloc/reserva_bloc.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_bloc.dart';
import 'package:agente_viajes/features/hoteles/presentation/bloc/hotel_bloc.dart';
import 'package:agente_viajes/features/uploads/presentation/bloc/upload_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart';
import 'core/network/session_expired_notifier.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/premium_palette.dart';
import 'config/app_router.dart';
import 'features/tour/presentation/bloc/tour_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  initDependencies();
  initializeDateFormatting('es_CO', null);
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
                Text(
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
                      navigatorKey.currentState?.pushNamedAndRemoveUntil(
                        AppRouter.login,
                        (_) => false,
                      );
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<TourBloc>(create: (_) => sl<TourBloc>()..add(LoadTours())),
        BlocProvider<SedeBloc>(create: (_) => sl<SedeBloc>()),
        BlocProvider<CatalogueBloc>(create: (_) => sl<CatalogueBloc>()),
        BlocProvider<PaymentMethodBloc>(create: (_) => sl<PaymentMethodBloc>()),
        BlocProvider<FaqBloc>(create: (_) => sl<FaqBloc>()),
        BlocProvider<ServiceBloc>(create: (_) => sl<ServiceBloc>()),
        BlocProvider<PoliticaReservaBloc>(
          create: (_) => sl<PoliticaReservaBloc>(),
        ),
        BlocProvider<InfoEmpresaBloc>(create: (_) => sl<InfoEmpresaBloc>()),
        BlocProvider<PagoRealizadoBloc>(create: (_) => sl<PagoRealizadoBloc>()),
        BlocProvider<WhatsAppBloc>(create: (_) => sl<WhatsAppBloc>()),
        BlocProvider<CotizacionBloc>(create: (_) => sl<CotizacionBloc>()),
        BlocProvider<AgenteBloc>(create: (_) => sl<AgenteBloc>()),
        BlocProvider<ReservaBloc>(create: (_) => sl<ReservaBloc>()),
        BlocProvider<ClienteBloc>(create: (_) => sl<ClienteBloc>()),
        BlocProvider<HotelBloc>(create: (_) => sl<HotelBloc>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<UploadBloc>(create: (_) => sl<UploadBloc>()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Agente Viajes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('es', 'CO'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'CO'), Locale('en', 'US')],
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
