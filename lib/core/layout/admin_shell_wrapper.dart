import 'package:flutter/material.dart';
import '../../config/app_router.dart';
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
    return AdminShell(
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
