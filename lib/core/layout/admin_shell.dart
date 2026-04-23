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
import 'package:agente_viajes/features/hoteles/presentation/bloc/hotel_bloc.dart';
import 'package:agente_viajes/features/hoteles/presentation/bloc/hotel_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_router.dart';
import '../theme/saas_palette.dart';
import 'widgets/sidebar_nav_item.dart';

/// Persistent sidebar shell for the admin panel.
/// Wraps all authenticated screens with a NavigationRail (desktop)
/// or Drawer (mobile).
class AdminShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final ValueChanged<String> onItemTapped;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onItemTapped,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      icon: Icons.hotel_rounded,
      label: 'Hoteles',
      route: AppRouter.hoteles,
      permission: 'hoteles',
    ),
    _NavItem(
      icon: Icons.manage_search_rounded,
      label: 'Auditoría',
      route: AppRouter.auditoria,
      permission: 'auditoria',
    ),
    _NavItem(
      icon: Icons.account_circle_rounded,
      label: 'Mi Perfil',
      route: AppRouter.profile,
      permission: '',
    ),
  ];

  void _onItemTapped(_NavItem item) {
    if (item.route == widget.currentRoute) return;

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
      case AppRouter.hoteles:
        context.read<HotelBloc>().add(const LoadHoteles());
    }

    widget.onItemTapped(item.route);

    final isDesktop = MediaQuery.of(context).size.width >= 800;
    if (!isDesktop) {
      Navigator.pop(context); // Close drawer on mobile
    }
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
    final user = authState is AuthAuthenticated ? authState.user : null;
    final currentRoute = widget.currentRoute;

    final baseVisibleItems = user == null
        ? <_NavItem>[]
        : _navItems
              .where((item) => user.hasPermission(item.permission))
              .toList();

    // Filtra los items basado en el buscador
    final visibleItems = _searchQuery.isEmpty
        ? baseVisibleItems
        : baseVisibleItems
              .where(
                (item) => item.label
                    .toLowerCase()
                    .replaceAll('\n', ' ')
                    .contains(_searchQuery),
              )
              .toList();

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: SaasPalette.bgApp,
        appBar: AppBar(
          backgroundColor: SaasPalette.bgCanvas,
          foregroundColor: SaasPalette.textPrimary,
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: SaasPalette.border)),
          title: const Text(
            'Travel Tours Florencia',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: SaasPalette.textPrimary,
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
          user?.name ?? user?.username ?? 'Sin usuario',
          user?.username != null
              ? '${user!.username}@agente.com'
              : 'admin@agente.com',
          visibleItems,
          currentRoute,
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: Row(
        children: [
          _buildSidebar(
            user?.name ?? user?.username ?? 'Sin usuario',
            user?.username != null
                ? '${user!.username}@agente.com'
                : 'admin@agente.com',
            visibleItems,
            currentRoute,
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    String username,
    String email,
    List<_NavItem> visibleItems,
    String currentRoute,
  ) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: SaasPalette.bgCanvas,
        border: Border(right: BorderSide(color: SaasPalette.border)),
      ),
      child: Column(
        children: [
          _buildHeader(email),
          _buildSearchBar(),
          _buildSectionLabel('WORKSPACE'),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return SidebarNavItem(
                  icon: item.icon,
                  label: item.label,
                  isActive: item.route == currentRoute,
                  onTap: () => _onItemTapped(item),
                );
              },
            ),
          ),
          const Divider(color: SaasPalette.border, height: 1),
          _buildFooter(username),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    String username,
    String email,
    List<_NavItem> visibleItems,
    String currentRoute,
  ) {
    return Drawer(
      backgroundColor: SaasPalette.bgCanvas,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildHeader(email)),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: SaasPalette.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(16),
                ),
              ],
            ),
            _buildSearchBar(),
            _buildSectionLabel('WORKSPACE'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return SidebarNavItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: item.route == currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(item);
                    },
                  );
                },
              ),
            ),
            const Divider(color: SaasPalette.border, height: 1),
            _buildFooter(username, isMobile: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String email) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: SaasPalette.brand600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flight, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Travel Tours Florencia',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: SaasPalette.bgApp,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SaasPalette.border),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.search,
                size: 16,
                color: SaasPalette.textTertiary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            // Container(
            //   margin: const EdgeInsets.only(right: 6),
            //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            //   decoration: BoxDecoration(
            //     color: SaasPalette.bgCanvas,
            //     borderRadius: BorderRadius.circular(4),
            //     border: Border.all(color: SaasPalette.border),
            //   ),
            //   child: const Text('⌘K', style: TextStyle(color: SaasPalette.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(String username, {bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: SaasPalette.brand600,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.logout_rounded,
              color: SaasPalette.textSecondary,
              size: 20,
            ),
            onPressed: () {
              _confirmLogout();
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SaasPalette.bgCanvas,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: SaasPalette.textPrimary),
        ),
        content: const Text(
          '¿Está seguro de que desea cerrar sesión?',
          style: TextStyle(color: SaasPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: SaasPalette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onLogout();
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: SaasPalette.danger),
            ),
          ),
        ],
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
