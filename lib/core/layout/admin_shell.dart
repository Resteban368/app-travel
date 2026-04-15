import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/payment_method_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/sede_bloc.dart';
import 'package:agente_viajes/features/tour/presentation/bloc/tour_bloc.dart';
import 'package:agente_viajes/features/catalogue/presentation/bloc/catalogue_bloc.dart';
import 'package:agente_viajes/features/catalogue/presentation/bloc/catalogue_event.dart';
import 'package:agente_viajes/features/faq/presentation/bloc/faq_bloc.dart';
import 'package:agente_viajes/features/faq/presentation/bloc/faq_event.dart';
import 'package:agente_viajes/features/service/presentation/bloc/service_bloc.dart';
import 'package:agente_viajes/features/service/presentation/bloc/service_event.dart';
import 'package:agente_viajes/features/politica_reserva/presentation/bloc/politica_reserva_bloc.dart';
import 'package:agente_viajes/features/politica_reserva/presentation/bloc/politica_reserva_event.dart';
import 'package:agente_viajes/features/info_empresa/presentation/bloc/info_empresa_bloc.dart';
import 'package:agente_viajes/features/info_empresa/presentation/bloc/info_empresa_event.dart';
import 'package:agente_viajes/features/pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_bloc.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_event.dart';
import 'package:agente_viajes/features/reservas/presentation/bloc/reserva_bloc.dart';
import 'package:agente_viajes/features/reservas/presentation/bloc/reserva_event.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_event.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_bloc.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../../config/app_router.dart';

/// Persistent sidebar shell for the admin panel.
/// Wraps all authenticated screens with a NavigationRail (desktop)
/// or Drawer (mobile).
class AdminShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _isExpanded = true;

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: AppRouter.dashboard,
      permission: 'dashboard',
    ),
    _NavItem(
      icon: Icons.tour_rounded,
      label: 'Tours\nPromociones',
      route: AppRouter.tours,
      permission: 'tours',
    ),
    _NavItem(
      icon: Icons.store_rounded,
      label: 'Sedes',
      route: AppRouter.sedes,
      permission: 'sedes',
    ),
    _NavItem(
      icon: Icons.payment_rounded,
      label: 'Métodos\nde Pago',
      route: AppRouter.paymentMethods,
      permission: 'paymentMethods',
    ),
    _NavItem(
      icon: Icons.picture_as_pdf_rounded,
      label: 'Catálogos',
      route: AppRouter.catalogues,
      permission: 'catalogues',
    ),
    _NavItem(
      icon: Icons.help_outline_rounded,
      label: 'Preguntas\nFrecuentes',
      route: AppRouter.faqs,
      permission: 'faqs',
    ),
    _NavItem(
      icon: Icons.settings_suggest_rounded,
      label: 'Servicios',
      route: AppRouter.services,
      permission: 'services',
    ),
    _NavItem(
      icon: Icons.policy_rounded,
      label: 'Políticas de\nReserva',
      route: AppRouter.politicasReserva,
      permission: 'politicasReserva',
    ),
    _NavItem(
      icon: Icons.business_rounded,
      label: 'Información\nEmpresa',
      route: AppRouter.infoEmpresa,
      permission: 'infoEmpresa',
    ),
    _NavItem(
      icon: Icons.payments_rounded,
      label: 'Pagos\nRealizados',
      route: AppRouter.pagosRealizados,
      permission: 'pagosRealizados',
    ),
    _NavItem(
      icon: Icons.person_add_alt_1_rounded,
      label: 'Gestión\nde Agentes',
      route: AppRouter.agentes,
      permission: 'agentes',
    ),
    _NavItem(
      icon: Icons.airplane_ticket_rounded,
      label: 'Gestión\nde Reservas',
      route: AppRouter.reservas,
      permission: 'reservas',
    ),
    _NavItem(
      icon: Icons.request_quote_rounded,
      label: 'Cotizaciones',
      route: AppRouter.cotizaciones,
      permission: 'cotizacion',
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Clientes',
      route: AppRouter.clientes,
      permission: 'clientes',
    ),
    _NavItem(
      icon: Icons.account_circle_rounded,
      label: 'Mi Perfil',
      route: AppRouter.profile,
      permission: '',
    ),
  ];

  void _onItemTapped(_NavItem item) {
    final currentRoute = widget.currentIndex >= 0 && widget.currentIndex < _navItems.length
        ? _navItems[widget.currentIndex].route
        : '';
    if (item.route == currentRoute) return;

    // Profile uses push (not replacement) to keep back navigation
    if (item.route == AppRouter.profile) {
      Navigator.pushNamed(context, AppRouter.profile);
      return;
    }

    switch (item.route) {
      case AppRouter.tours:
        context.read<TourBloc>().add(LoadTours());
      case AppRouter.sedes:
        context.read<SedeBloc>().add(LoadSedes());
      case AppRouter.paymentMethods:
        context.read<PaymentMethodBloc>().add(LoadPaymentMethods());
      case AppRouter.catalogues:
        context.read<CatalogueBloc>().add(LoadCatalogues());
      case AppRouter.faqs:
        context.read<FaqBloc>().add(LoadFaqs());
      case AppRouter.services:
        context.read<ServiceBloc>().add(LoadServices());
      case AppRouter.politicasReserva:
        context.read<PoliticaReservaBloc>().add(LoadPoliticas());
      case AppRouter.infoEmpresa:
        context.read<InfoEmpresaBloc>().add(LoadInfo());
      case AppRouter.pagosRealizados:
        context.read<PagoRealizadoBloc>().add(const LoadPagos());
      case AppRouter.agentes:
        context.read<AgenteBloc>().add(LoadAgentes());
      case AppRouter.reservas:
        context.read<ReservaBloc>().add(const LoadReservas());
      case AppRouter.cotizaciones:
        context.read<CotizacionBloc>().add(LoadCotizaciones());
      case AppRouter.clientes:
        context.read<ClienteBloc>().add(LoadClientes());
    }

    Navigator.pushReplacementNamed(context, item.route);
  }

  void _onLogout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    final authState = context.watch<AuthBloc>().state;

    // Auto-collapse on medium screens (800–1000px)
    if (isDesktop && width < 1000 && _isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isExpanded = false);
      });
    }

    final user = authState is AuthAuthenticated ? authState.user : null;
    final currentRoute = widget.currentIndex >= 0 && widget.currentIndex < _navItems.length
        ? _navItems[widget.currentIndex].route
        : '';
    final visibleItems = user == null
        ? <_NavItem>[]
        : _navItems.where((item) => user.hasPermission(item.permission)).toList();

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.cobalt,
          foregroundColor: AppColors.white,
          title: const Text(
            'Travel Tours Florencia',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(
          user?.username ?? 'Sin usuario',
          visibleItems,
          currentRoute,
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(
            user?.username ?? 'Sin usuario',
            visibleItems,
            currentRoute,
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    String userInfo,
    List<_NavItem> visibleItems,
    String currentRoute,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isExpanded ? 260 : 72,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo / Header
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flight,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Travel Tours\nFlorencia',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
          if (_isExpanded)
            Text(
              userInfo,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.navyLight, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return _SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  isActive: item.route == currentRoute,
                  isExpanded: _isExpanded,
                  onTap: () => _onItemTapped(item),
                );
              },
            ),
          ),
          // Collapse / Expand button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _SidebarItem(
              icon: _isExpanded
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              label: 'Colapsar',
              isActive: false,
              isExpanded: _isExpanded,
              onTap: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          const Divider(color: AppColors.navyLight, indent: 16, endIndent: 16),
          // Logout
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
            child: _SidebarItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar Sesión',
              isActive: false,
              isExpanded: _isExpanded,
              onTap: _onLogout,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    String userInfo,
    List<_NavItem> visibleItems,
    String currentRoute,
  ) {
    return Drawer(
      backgroundColor: AppColors.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Travel Tours Florencia',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              userInfo,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(
              color: AppColors.navyLight,
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return _SidebarItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: item.route == currentRoute,
                    isExpanded: true,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(item);
                    },
                  );
                },
              ),
            ),
            const Divider(
              color: AppColors.navyLight,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
              child: _SidebarItem(
                icon: Icons.logout_rounded,
                label: 'Cerrar Sesión',
                isActive: false,
                isExpanded: true,
                onTap: () {
                  //dialogo de confirmacion
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cerrar Sesión'),
                      content: const Text(
                        '¿Está seguro de que desea cerrar sesión?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _onLogout();
                          },
                          child: const Text('Cerrar Sesión'),
                        ),
                      ],
                    ),
                  );
                },
                isDestructive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private helpers ─────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final String permission;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.permission,
  });
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (widget.isActive) {
      bgColor = AppColors.sidebarActive;
    } else if (_isHovered) {
      bgColor = AppColors.sidebarHover;
    } else {
      bgColor = Colors.transparent;
    }

    final iconColor = widget.isDestructive
        ? AppColors.error
        : (widget.isActive ? AppColors.accent : AppColors.greyLight);
    final textColor = widget.isDestructive
        ? AppColors.error
        : (widget.isActive ? AppColors.white : AppColors.greyLight);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExpanded ? 16 : 0,
                vertical: 12,
              ),
              child: widget.isExpanded
                  ? Row(
                      children: [
                        Icon(widget.icon, color: iconColor, size: 22),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Icon(widget.icon, color: iconColor, size: 22),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
