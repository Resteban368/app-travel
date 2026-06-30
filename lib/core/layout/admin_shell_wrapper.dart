import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notificaciones/presentation/bloc/notificacion_bloc.dart';
import 'admin_shell.dart';

class AdminShellWrapper extends StatefulWidget {
  final String? initialRoute;
  const AdminShellWrapper({super.key, this.initialRoute});

  @override
  State<AdminShellWrapper> createState() => _AdminShellWrapperState();
}

class _AdminShellWrapperState extends State<AdminShellWrapper> {
  late String _currentRoute;
  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          // Sesión perdida (logout o restauración fallida) → ir al login.
          // Esto cubre tanto el cierre de sesión manual como la expiración.
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (_) => false,
          );
        } else if (state is AuthAuthenticated) {
          // Si el SSE nunca se conectó (porque montamos antes de restaurar
          // la sesión), conectarlo ahora. El guard evita reconexiones innecesarias.
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
