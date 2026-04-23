import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/politica_reserva.dart';
import '../bloc/politica_reserva_bloc.dart';
import '../bloc/politica_reserva_event.dart';
import '../bloc/politica_reserva_state.dart';

class PoliticaReservaListScreen extends StatefulWidget {
  const PoliticaReservaListScreen({super.key});

  @override
  State<PoliticaReservaListScreen> createState() =>
      _PoliticaReservaListScreenState();
}

class _PoliticaReservaListScreenState extends State<PoliticaReservaListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<PoliticaReservaBloc, PoliticaReservaState>(
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          final canWrite =
              authState is AuthAuthenticated &&
              authState.user.canWrite('politicasReserva');

          List<PoliticaReserva> politicas = [];
          if (state is PoliticaLoaded) {
            politicas = state.politicas;
          } else if (state is PoliticaSaving && state.politicas != null) {
            politicas = state.politicas!;
          } else if (state is PoliticaSaved) {
            politicas = state.politicas;
          }

          final filtered = politicas.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.titulo.toLowerCase().contains(query) ||
                p.descripcion.toLowerCase().contains(query);
          }).toList();

          final isLoading = state is PoliticaLoading && politicas.isEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<PoliticaReservaBloc>().add(LoadPoliticas()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PoliticaHeader(canWrite: canWrite),
                  ),
                ),

                // ── Search Field ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar políticas por título o contenido...',
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
                        childCount: 4,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SaasEmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.policy_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin resultados'
                          : 'Sin políticas',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos políticas que coincidan con "$_searchQuery".'
                          : 'Aún no has definido las políticas de reserva de la agencia.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final politica = filtered[index];
                        return _PoliticaCard(
                          politica: politica,
                          canWrite: canWrite,
                          onDelete: () => _confirmDelete(politica),
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

  void _confirmDelete(PoliticaReserva politica) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar Política?',
        body: 'Esta acción borrará "${politica.titulo}" permanentemente.',
        onConfirm: () {
          context.read<PoliticaReservaBloc>().add(DeletePolitica(politica.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _PoliticaHeader extends StatelessWidget {
  final bool canWrite;
  const _PoliticaHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Legal', 'Políticas']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Políticas de Reserva',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Define los términos, condiciones y políticas de cancelación.',
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
                label: 'Nueva Política',
                icon: Icons.add_rounded,
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRouter.politicaReservaCreate,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  POLITICA CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PoliticaCard extends StatefulWidget {
  final PoliticaReserva politica;
  final bool canWrite;
  final VoidCallback onDelete;

  const _PoliticaCard({
    required this.politica,
    required this.canWrite,
    required this.onDelete,
  });

  @override
  State<_PoliticaCard> createState() => _PoliticaCardState();
}

class _PoliticaCardState extends State<_PoliticaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.politica;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? SaasPalette.brand600 : SaasPalette.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.08 : 0.03),
                blurRadius: _hovered ? 16 : 8,
                offset: Offset(0, _hovered ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.politicaReservaEdit,
              arguments: p,
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
                      Icons.policy_rounded,
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
                                p.titulo,
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SaasStatusBadge(active: p.activo),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.descripcion,
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
                                color: SaasPalette.bgApp,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SaasPalette.border),
                              ),
                              child: Text(
                                p.tipoPolitica.toUpperCase(),
                                style: const TextStyle(
                                  color: SaasPalette.brand600,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (widget.canWrite)
                              _PoliticaActionMenu(
                                onEdit: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.politicaReservaEdit,
                                  arguments: p,
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

class _PoliticaActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PoliticaActionMenu({required this.onEdit, required this.onDelete});

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
              Text('Editar política', style: TextStyle(fontSize: 13)),
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
