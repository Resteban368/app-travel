import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_snackbar.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/opinion.dart';
import '../bloc/opinion_bloc.dart';
import '../bloc/opinion_event.dart';
import '../bloc/opinion_state.dart';

enum _Filtro { pendientes, publicadas, todas }

class OpinionListScreen extends StatelessWidget {
  const OpinionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _OpinionListBody());
  }
}

class _OpinionListBody extends StatefulWidget {
  const _OpinionListBody();

  @override
  State<_OpinionListBody> createState() => _OpinionListBodyState();
}

class _OpinionListBodyState extends State<_OpinionListBody> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _Filtro _filtro = _Filtro.pendientes;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite =
        authState is AuthAuthenticated && authState.user.canWrite('opiniones');

    return Scaffold(
      backgroundColor: context.saas.bgApp,
      body: BlocConsumer<OpinionBloc, OpinionState>(
        listener: (context, state) {
          if (state is OpinionSaved) {
            SaasSnackBar.showSuccess(context, state.message);
          } else if (state is OpinionError) {
            SaasSnackBar.showError(context, 'No se pudo completar la acción');
          }
        },
        builder: (context, state) {
          final list = switch (state) {
            OpinionesLoaded(:final opiniones) => opiniones,
            OpinionSaving(:final opiniones) => opiniones ?? <Opinion>[],
            OpinionSaved(:final opiniones) => opiniones ?? <Opinion>[],
            _ => <Opinion>[],
          };
          final isBusy = state is OpinionSaving;

          final pendientes = list.where((o) => !o.aprobada).length;
          final publicadas = list.length - pendientes;

          final query = _searchQuery.toLowerCase();
          final filtered = list.where((o) {
            final pasaFiltro = switch (_filtro) {
              _Filtro.pendientes => !o.aprobada,
              _Filtro.publicadas => o.aprobada,
              _Filtro.todas => true,
            };
            return pasaFiltro &&
                (o.nombre.toLowerCase().contains(query) ||
                    o.texto.toLowerCase().contains(query) ||
                    (o.plan ?? '').toLowerCase().contains(query));
          }).toList();

          final isLoading =
              (state is OpinionLoading || state is OpinionInitial) &&
              list.isEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<OpinionBloc>().add(LoadOpiniones()),
            color: context.saas.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(child: _OpinionHeader()),
                ),

                // ── Filtros + búsqueda ────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _FiltroSelector(
                          filtro: _filtro,
                          pendientes: pendientes,
                          publicadas: publicadas,
                          total: list.length,
                          onChanged: (f) => setState(() => _filtro = f),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SaasSearchField(
                            controller: _searchCtrl,
                            hintText: 'Buscar por nombre, plan u opinión...',
                            onChanged: (v) => setState(() => _searchQuery = v),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, _) => const SaasListSkeleton(),
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
                          : Icons.rate_review_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin coincidencias'
                          : switch (_filtro) {
                              _Filtro.pendientes => 'Nada por revisar',
                              _Filtro.publicadas => 'Sin opiniones publicadas',
                              _Filtro.todas => 'Aún no hay opiniones',
                            },
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos opiniones que coincidan con "$_searchQuery".'
                          : switch (_filtro) {
                              _Filtro.pendientes =>
                                'Las opiniones nuevas de la página web aparecerán aquí para que las apruebes.',
                              _Filtro.publicadas =>
                                'Cuando apruebes una opinión se mostrará en la página web.',
                              _Filtro.todas =>
                                'Los clientes pueden dejar su opinión desde la página web.',
                            },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final opinion = filtered[index];
                        return _OpinionCard(
                          opinion: opinion,
                          canWrite: canWrite,
                          busy: isBusy,
                          onToggle: () => context.read<OpinionBloc>().add(
                            SetOpinionAprobada(opinion.id, !opinion.aprobada),
                          ),
                          onDelete: () => _confirmDelete(opinion),
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

  void _confirmDelete(Opinion opinion) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar opinión?',
        body:
            'Esta acción no se puede deshacer. La opinión de "${opinion.nombre}" se eliminará permanentemente'
            '${opinion.aprobada ? ' y dejará de verse en la página web' : ''}.',
        onConfirm: () {
          context.read<OpinionBloc>().add(DeleteOpinion(opinion.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _OpinionHeader extends StatelessWidget {
  const _OpinionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Página Web', 'Opiniones']),
        const SizedBox(height: 16),
        Text(
          'Opiniones de Clientes',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa las opiniones enviadas desde la página web. Solo las aprobadas se publican.',
          style: TextStyle(color: context.saas.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILTRO
// ─────────────────────────────────────────────────────────────────────────────
class _FiltroSelector extends StatelessWidget {
  final _Filtro filtro;
  final int pendientes;
  final int publicadas;
  final int total;
  final ValueChanged<_Filtro> onChanged;

  const _FiltroSelector({
    required this.filtro,
    required this.pendientes,
    required this.publicadas,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(_Filtro value, String label, int count) {
      final selected = filtro == value;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.saas.brand600.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? context.saas.brand600
                      : context.saas.textSecondary,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: value == _Filtro.pendientes && count > 0
                      ? context.saas.warning.withValues(alpha: 0.15)
                      : context.saas.bgSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: value == _Filtro.pendientes && count > 0
                        ? context.saas.warning
                        : context.saas.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(_Filtro.pendientes, 'Pendientes', pendientes),
          item(_Filtro.publicadas, 'Publicadas', publicadas),
          item(_Filtro.todas, 'Todas', total),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OPINION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OpinionCard extends StatelessWidget {
  final Opinion opinion;
  final bool canWrite;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _OpinionCard({
    required this.opinion,
    required this.canWrite,
    required this.busy,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final o = opinion;
    final inicial = o.nombre.trim().isEmpty
        ? '?'
        : o.nombre.trim()[0].toUpperCase();
    final fecha = o.createdAt != null
        ? DateFormat('dd/MM/yyyy · HH:mm').format(o.createdAt!.toLocal())
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.saas.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: o.aprobada
                ? context.saas.border
                : context.saas.warning.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.saas.brand50,
                  child: Text(
                    inicial,
                    style: TextStyle(
                      color: context.saas.brand600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.nombre,
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (o.plan != null && o.plan!.isNotEmpty) o.plan!,
                          ?fecha,
                        ].join('  ·  '),
                        style: TextStyle(
                          color: context.saas.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SaasStatusBadge(
                  active: o.aprobada,
                  activeLabel: 'Publicada',
                  inactiveLabel: 'Pendiente',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < o.calificacion
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 18,
                  color: i < o.calificacion
                      ? const Color(0xFFF5A623)
                      : context.saas.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              o.texto,
              style: TextStyle(
                color: context.saas.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (canWrite) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SaasButton(
                      label: 'Eliminar',
                      icon: Icons.delete_outline_rounded,
                      isPrimary: false,
                      onPressed: busy ? () {} : onDelete,
                    ),
                    SaasButton(
                      label: o.aprobada
                          ? 'Retirar de la web'
                          : 'Aprobar y publicar',
                      icon: o.aprobada
                          ? Icons.visibility_off_outlined
                          : Icons.check_circle_outline_rounded,
                      isPrimary: !o.aprobada,
                      onPressed: busy ? () {} : onToggle,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
