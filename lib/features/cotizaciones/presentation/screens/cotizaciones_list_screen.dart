import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_router.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../core/permissions/permission_helper.dart';
import '../../domain/entities/cotizacion.dart';
import '../bloc/cotizacion_bloc.dart';
import '../bloc/cotizacion_event.dart';
import '../bloc/cotizacion_state.dart';

class CotizacionesListScreen extends StatelessWidget {
  const CotizacionesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 12, child: _CotizacionesBody());
  }
}

class _CotizacionesBody extends StatefulWidget {
  const _CotizacionesBody();
  @override
  State<_CotizacionesBody> createState() => _CotizacionesBodyState();
}

class _CotizacionesBodyState extends State<_CotizacionesBody>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Animations
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _listOpacity;

  @override
  void initState() {
    super.initState();
    context.read<CotizacionBloc>().add(LoadCotizaciones());

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _listOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCotizacionTap(Cotizacion cot) {
    Navigator.pushNamed(context, AppRouter.cotizacionCreate, arguments: cot);
  }

  void _goToPage(int page) {
    context.read<CotizacionBloc>().add(LoadCotizaciones(page: page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<CotizacionBloc, CotizacionState>(
        builder: (context, state) {
          List<Cotizacion> list = [];
          int currentPage = 1;
          int totalPages = 1;
          int totalResults = 0;

          if (state is CotizacionLoaded) {
            list = state.cotizaciones;
            currentPage = state.page;
            totalPages = state.totalPages;
            totalResults = state.total;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              list = list.where((c) {
                final chat = c.chatId.toLowerCase();
                return c.nombreCompleto.toLowerCase().contains(q) ||
                    c.detallesPlan.toLowerCase().contains(q) ||
                    chat.contains(q);
              }).toList();
            }
          }

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                child: FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SaasBreadcrumbs(
                          items: ['Inicio', 'Operaciones', 'Cotizaciones'],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Gestión de Cotizaciones',
                                    style: TextStyle(
                                      color: SaasPalette.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Administra las propuestas de viaje de tus clientes.',
                                    style: TextStyle(
                                      color: SaasPalette.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SaasButton(
                              label: 'Nueva Cotización',
                              icon: Icons.add_rounded,
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRouter.cotizacionCreate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: SaasSearchField(
                  controller: _searchCtrl,
                  hintText: 'Buscar por nombre, celular o destino...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),

              // Scrollable content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => context.read<CotizacionBloc>().add(
                    LoadCotizaciones(page: currentPage),
                  ),
                  color: SaasPalette.brand600,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (state is CotizacionLoading)
                        const SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          sliver: SliverToBoxAdapter(
                            child: SaasListSkeleton(height: 100),
                          ),
                        )
                      else if (state is CotizacionError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: SaasPalette.danger,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar cotizaciones',
                                  style: TextStyle(
                                    color: SaasPalette.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    state.message,
                                    style: const TextStyle(
                                      color: SaasPalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SaasButton(
                                  label: 'Reintentar',
                                  isPrimary: true,
                                  onPressed: () => context
                                      .read<CotizacionBloc>()
                                      .add(LoadCotizaciones(page: currentPage)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: SaasEmptyState(
                            icon: Icons.request_quote_outlined,
                            title: 'Sin cotizaciones',
                            subtitle: _searchQuery.isNotEmpty
                                ? 'No encontramos cotizaciones que coincidan con "$_searchQuery".'
                                : 'Aún no has registrado ninguna solicitud de viaje.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final cot = list[index];
                              return FadeTransition(
                                opacity: _listOpacity,
                                child: _CotizacionCard(
                                  cotizacion: cot,
                                  onTap: () => _onCotizacionTap(cot),
                                ),
                              );
                            }, childCount: list.length),
                          ),
                        ),

                      if (state is CotizacionLoaded && totalPages > 1)
                        SliverToBoxAdapter(
                          child: _PaginationBar(
                            page: currentPage,
                            totalPages: totalPages,
                            total: totalResults,
                            onPageChanged: _goToPage,
                          ),
                        ),

                      const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CotizacionCard extends StatefulWidget {
  final Cotizacion cotizacion;
  final VoidCallback onTap;
  const _CotizacionCard({required this.cotizacion, required this.onTap});

  @override
  State<_CotizacionCard> createState() => _CotizacionCardState();
}

class _CotizacionCardState extends State<_CotizacionCard> {
  bool _hover = false;

  void _confirmDelete(BuildContext context, Cotizacion c) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar cotización?',
        body:
            'Esta acción no se puede deshacer. ¿Deseas eliminar la cotización de ${c.nombreCompleto}?',
        onConfirm: () {
          context.read<CotizacionBloc>().add(DeleteCotizacion(c.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    final isUnread = !c.isRead;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover ? SaasPalette.brand600 : SaasPalette.border,
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.08 : 0.03),
                blurRadius: _hover ? 16 : 8,
                offset: Offset(0, _hover ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isUnread
                          ? SaasPalette.brand600.withOpacity(0.1)
                          : SaasPalette.bgSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUnread
                          ? Icons.mark_as_unread_rounded
                          : Icons.mark_email_read_rounded,
                      color: isUnread
                          ? SaasPalette.brand600
                          : SaasPalette.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.nombreCompleto,
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SaasStatusBadge(
                              active: c.estado.toLowerCase() == 'atendida',
                              activeLabel: 'ATENDIDA',
                              inactiveLabel: c.estado.toUpperCase(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.detallesPlan,
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: SaasPalette.textTertiary,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd MMM, hh:mm a',
                              ).format(c.createdAt.toLocal()),
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SaasPalette.brand600.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NUEVA',
                                  style: TextStyle(
                                    color: SaasPalette.brand600,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (context.canWrite('cotizaciones'))
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: SaasPalette.textTertiary,
                        size: 20,
                      ),
                      onPressed: () => _confirmDelete(context, c),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SaasPalette.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final void Function(int) onPageChanged;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaasPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageBtn(
              icon: Icons.chevron_left_rounded,
              enabled: page > 1,
              onTap: () => onPageChanged(page - 1),
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                Text(
                  'Página $page de $totalPages',
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total resultados',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            _PageBtn(
              icon: Icons.chevron_right_rounded,
              enabled: page < totalPages,
              onTap: () => onPageChanged(page + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? SaasPalette.brand600.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? SaasPalette.brand600 : SaasPalette.border,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? SaasPalette.brand600 : SaasPalette.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
