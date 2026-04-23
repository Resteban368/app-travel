import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/service.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _ServiceListBody());
  }
}

class _ServiceListBody extends StatefulWidget {
  const _ServiceListBody();

  @override
  State<_ServiceListBody> createState() => _ServiceListBodyState();
}

class _ServiceListBodyState extends State<_ServiceListBody> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite =
        authState is AuthAuthenticated && authState.user.canWrite('services');

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          List<Service> list = [];
          if (state is ServicesLoaded) {
            list = state.services;
          } else if (state is ServiceSaving && state.services != null) {
            list = state.services!;
          } else if (state is ServiceSaved && state.services != null) {
            list = state.services!;
          }

          final filtered = list.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.name.toLowerCase().contains(query) ||
                s.description.toLowerCase().contains(query);
          }).toList();

          final isLoading = state is ServiceLoading && list.isEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ServiceBloc>().add(LoadServices()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ServiceHeader(canWrite: canWrite),
                  ),
                ),

                // ── Search Field ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar servicios o descripción...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SaasListSkeleton(),
                        childCount: 5,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SaasEmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.room_service_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin resultados'
                          : 'Sin servicios',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos servicios que coincidan con tu búsqueda.'
                          : 'Comienza agregando los beneficios y extras que ofreces.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final service = filtered[index];
                        return _ServiceCard(
                          service: service,
                          canWrite: canWrite,
                          onDelete: () => _confirmDelete(service),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(Service service) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar Servicio?',
        body: 'El servicio "${service.name}" se eliminará permanentemente.',
        onConfirm: () {
          context.read<ServiceBloc>().add(DeleteService(service.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceHeader extends StatelessWidget {
  final bool canWrite;
  const _ServiceHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Servicios']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Catálogo de Servicios',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestiona los beneficios y servicios adicionales de tus productos.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite)
              SaasButton(
                label: 'Nuevo Servicio',
                icon: Icons.add_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.serviceCreate),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SERVICE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceCard extends StatefulWidget {
  final Service service;
  final bool canWrite;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.canWrite,
    required this.onDelete,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? SaasPalette.brand600 : SaasPalette.border,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.serviceEdit,
              arguments: s,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: SaasPalette.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: SaasPalette.brand600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SaasStatusBadge(active: s.isActive),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: SaasPalette.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s.cost != null && s.cost! > 0
                                    ? currencyFormat.format(s.cost)
                                    : 'Gratuito',
                                style: const TextStyle(
                                  color: SaasPalette.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (widget.canWrite)
                              _ServiceActionMenu(
                                onEdit: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.serviceEdit,
                                  arguments: s,
                                ),
                                onDelete: widget.onDelete,
                              ),
                          ],
                        ),
                      ],
                    ),
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

class _ServiceActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceActionMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: SaasPalette.textTertiary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: SaasPalette.bgCanvas,
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: SaasPalette.textPrimary,
              ),
              SizedBox(width: 12),
              Text('Editar servicio', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: SaasPalette.danger,
              ),
              SizedBox(width: 12),
              Text(
                'Eliminar',
                style: TextStyle(color: SaasPalette.danger, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
