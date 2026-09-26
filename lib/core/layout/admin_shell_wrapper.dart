import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_router.dart';
import '../di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notificaciones/presentation/bloc/notificacion_bloc.dart';
import '../../features/tour/presentation/bloc/tour_bloc.dart';
import '../../features/tour/presentation/bloc/tour_historico_bloc.dart';
import '../../features/settings/presentation/bloc/sede_bloc.dart';
import '../../features/settings/presentation/bloc/payment_method_bloc.dart';
import '../../features/catalogue/presentation/bloc/catalogue_bloc.dart';
import '../../features/faq/presentation/bloc/faq_bloc.dart';
import '../../features/service/presentation/bloc/service_bloc.dart';
import '../../features/politica_reserva/presentation/bloc/politica_reserva_bloc.dart';
import '../../features/info_empresa/presentation/bloc/info_empresa_bloc.dart';
import '../../features/pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import '../../features/whatsapp/presentation/bloc/whatsapp_bloc.dart';
import '../../features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import '../../features/agentes/presentation/bloc/agente_bloc.dart';
import '../../features/reservas/presentation/bloc/reserva_bloc.dart';
import '../../features/clientes/presentation/bloc/cliente_bloc.dart';
import '../../features/hoteles/presentation/bloc/hotel_bloc.dart';
import '../../features/proveedores/presentation/bloc/proveedor_bloc.dart';
import '../../features/bus_layouts/presentation/bloc/bus_layout_bloc.dart';
import '../../features/uploads/presentation/bloc/upload_bloc.dart';
import '../../features/saldos_pendientes/presentation/bloc/saldo_pendiente_bloc.dart';
import 'admin_shell.dart';

/// Envuelve toda el área autenticada de la app.
///
/// Aquí se proveen todos los BLoCs de feature (registrados como `factory` en
/// GetIt). Al vivir dentro de esta ruta del navigator raíz, se crean cuando el
/// usuario entra a la app y se destruyen —cerrando su estado— cuando el logout
/// hace `pushNamedAndRemoveUntil(login)` y desmonta este widget. Así ningún
/// estado ni conexión (SSE) sobrevive entre sesiones de usuario distintas.
class AdminShellWrapper extends StatefulWidget {
  final String? initialRoute;
  const AdminShellWrapper({super.key, this.initialRoute});

  @override
  State<AdminShellWrapper> createState() => _AdminShellWrapperState();
}

class _AdminShellWrapperState extends State<AdminShellWrapper> {
  late String _currentRoute;
  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();

  /// Nº de shells montados a la vez. DEBE ser 1: el navigator RAÍZ solo tiene un
  /// AdminShellWrapper y toda la navegación interna va por el navigator ANIDADO.
  /// Si se monta un segundo, se duplicarían el SSE y los ~20 BLoCs corriendo en
  /// paralelo (la causa raíz del freeze). Lo detectamos para cazar la regresión.
  static int _liveInstances = 0;

  void _onRouteChanged(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name != _currentRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentRoute = name);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _liveInstances++;
    assert(() {
      if (_liveInstances > 1) {
        debugPrint(
          '🚨 [AdminShellWrapper] ¡$_liveInstances shells montados a la vez! '
          'Alguien navegó por el navigator RAÍZ y duplicó SSE + BLoCs. '
          'Toda navegación interna debe usar el navigator ANIDADO.',
        );
      }
      return true;
    }());
    _currentRoute = widget.initialRoute ?? AppRouter.dashboard;

    // Cuando el usuario recarga la página (o el tab se suspende y recupera),
    // usePathUrlStrategy monta AdminShellWrapper directamente sin pasar por
    // SplashScreen, de modo que AppStarted nunca se dispara y la sesión nunca
    // se restaura. Lo disparamos aquí si AuthBloc aún no la ha restaurado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthInitial) {
        authBloc.add(const AppStarted());
      }
    });
  }

  @override
  void dispose() {
    _liveInstances--;
    super.dispose();
  }

  void _onItemTapped(String route) {
    if (_currentRoute == route) return;

    if (route == AppRouter.profile || route == AppRouter.auditoria) {
      _nestedNavKey.currentState?.pushNamed(route);
      return;
    }

    setState(() => _currentRoute = route);
    _nestedNavKey.currentState?.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TourBloc>(create: (_) => sl<TourBloc>()),
        BlocProvider<TourHistoricoBloc>(create: (_) => sl<TourHistoricoBloc>()),
        BlocProvider<SedeBloc>(create: (_) => sl<SedeBloc>()),
        BlocProvider<PaymentMethodBloc>(create: (_) => sl<PaymentMethodBloc>()),
        BlocProvider<CatalogueBloc>(create: (_) => sl<CatalogueBloc>()),
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
        BlocProvider<ProveedorBloc>(create: (_) => sl<ProveedorBloc>()),
        BlocProvider<BusLayoutBloc>(create: (_) => sl<BusLayoutBloc>()),
        BlocProvider<UploadBloc>(create: (_) => sl<UploadBloc>()),
        BlocProvider<SaldoPendienteBloc>(
          create: (_) => sl<SaldoPendienteBloc>(),
        ),
        BlocProvider<NotificacionBloc>(create: (_) => sl<NotificacionBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            // Sesión perdida (logout o restauración fallida) → ir al login.
            // Al desmontarse este widget, el MultiBlocProvider de arriba cierra
            // todos los BLoCs de feature y desconecta el SSE.
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.login,
              (_) => false,
            );
          } else if (state is AuthAuthenticated) {
            // Si el SSE nunca se conectó (porque montamos antes de restaurar
            // la sesión), conectarlo ahora. El guard evita reconexiones.
            final notifState = context.read<NotificacionBloc>().state;
            if (notifState is NotificacionInitial) {
              context.read<NotificacionBloc>().add(ConectarSse());
            }
          }
        },
        child: AdminShell(
          currentRoute: _currentRoute,
          onItemTapped: _onItemTapped,
          child: Navigator(
            key: _nestedNavKey,
            initialRoute: widget.initialRoute ?? AppRouter.dashboard,
            onGenerateRoute: AppRouter.onGenerateNestedRoute,
            observers: [
              _NavigatorObserver(_onRouteChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigatorObserver extends NavigatorObserver {
  final Function(Route<dynamic>?) onRouteChanged;
  _NavigatorObserver(this.onRouteChanged);

  @override
  void didPush(Route route, Route? previousRoute) => onRouteChanged(route);
  @override
  void didPop(Route route, Route? previousRoute) => onRouteChanged(previousRoute);
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => onRouteChanged(newRoute);
}
