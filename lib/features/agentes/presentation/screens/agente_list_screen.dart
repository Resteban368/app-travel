import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/agente.dart';
import '../bloc/agente_bloc.dart';
import '../bloc/agente_event.dart';
import '../bloc/agente_state.dart';

class AgenteListScreen extends StatefulWidget {
  const AgenteListScreen({super.key});

  @override
  State<AgenteListScreen> createState() => _AgenteListScreenState();
}

class _AgenteListScreenState extends State<AgenteListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AgenteBloc>().add(LoadAgentes());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocConsumer<AgenteBloc, AgenteState>(
        listener: (context, state) {
          if (state is AgenteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: SaasPalette.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          final canWrite =
              authState is AuthAuthenticated &&
              authState.user.canWrite('agentes');

          List<Agente> agentes = [];
          if (state is AgenteLoaded) {
            agentes = state.agentes;
          } else if (state is AgenteSaving && state.agentes != null) {
            agentes = state.agentes!;
          } else if (state is AgenteActionSuccess) {
            agentes = state.agentes;
          }

          final filtered = agentes.where((a) {
            final query = _searchQuery.toLowerCase();
            return a.nombre.toLowerCase().contains(query) ||
                a.correo.toLowerCase().contains(query);
          }).toList();

          final isLoading = state is AgenteLoading && agentes.isEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AgenteBloc>().add(LoadAgentes()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _AgenteHeader(canWrite: canWrite),
                  ),
                ),

                // ── Search Field ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar agentes por nombre o correo...',
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
                          : Icons.people_outline_rounded,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin resultados'
                          : 'No hay agentes',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos agentes que coincidan con "$_searchQuery".'
                          : 'Aún no has registrado agentes en el sistema.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final agente = filtered[index];
                        return _AgenteCard(
                          agente: agente,
                          canWrite: canWrite,
                          onDelete: () => _confirmDelete(agente),
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

  void _confirmDelete(Agente agente) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar Agente?',
        body:
            'Esta acción borrará a "${agente.nombre}" permanentemente del sistema.',
        onConfirm: () {
          context.read<AgenteBloc>().add(DeleteAgente(agente.id!));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _AgenteHeader extends StatelessWidget {
  final bool canWrite;
  const _AgenteHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Administración', 'Agentes']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gestión de Agentes',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administra el equipo de ventas y asesores de la agencia.',
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
                label: 'Nuevo Agente',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.agenteCreate),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AGENTE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AgenteCard extends StatefulWidget {
  final Agente agente;
  final bool canWrite;
  final VoidCallback onDelete;

  const _AgenteCard({
    required this.agente,
    required this.canWrite,
    required this.onDelete,
  });

  @override
  State<_AgenteCard> createState() => _AgenteCardState();
}

class _AgenteCardState extends State<_AgenteCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.agente;

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
            onTap: widget.canWrite
                ? () => Navigator.pushNamed(
                    context,
                    AppRouter.agenteEdit,
                    arguments: a,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: SaasPalette.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: SaasPalette.brand600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.nombre,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.correo,
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.canWrite) ...[
                    const SizedBox(width: 16),
                    _AgenteActionMenu(
                      onEdit: () => Navigator.pushNamed(
                        context,
                        AppRouter.agenteEdit,
                        arguments: a,
                      ),
                      onDelete: widget.onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgenteActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgenteActionMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
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
              Text('Editar agente', style: TextStyle(fontSize: 13)),
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
