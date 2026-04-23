import 'package:agente_viajes/config/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/sede.dart';
import '../bloc/sede_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SedeListScreen extends StatefulWidget {
  const SedeListScreen({super.key});

  @override
  State<SedeListScreen> createState() => _SedeListScreenState();
}

class _SedeListScreenState extends State<SedeListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SedeBloc>().add(LoadSedes());
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite =
        authState is AuthAuthenticated && authState.user.canWrite('sedes');

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<SedeBloc, SedeState>(
        builder: (context, state) {
          List<Sede> list = [];
          if (state is SedesLoaded) {
            list = state.sedes;
          } else if (state is SedeSaving && state.sedes != null) {
            list = state.sedes!;
          } else if (state is SedeSaved && state.sedes != null) {
            list = state.sedes!;
          }

          final filteredList = list.where((s) {
            return s.nombreSede.toLowerCase().contains(_searchQuery) ||
                s.direccion.toLowerCase().contains(_searchQuery);
          }).toList();

          final isLoading = state is SedeLoading && list.isEmpty;

          return RefreshIndicator(
            onRefresh: () async => context.read<SedeBloc>().add(LoadSedes()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SedeHeader(canWrite: canWrite),
                  ),
                ),

                // ── Search Bar ─────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar por nombre o dirección...',
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
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
                else if (filteredList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SaasEmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.storefront_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin resultados'
                          : 'Sin sedes',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos sedes que coincidan con "$_searchQuery".'
                          : 'Aún no has registrado ninguna sede operativa.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sede = filteredList[index];
                        return _SedeCard(
                          sede: sede,
                          canWrite: canWrite,
                          onEdit: () {
                            print('sede: $sede');
                            Navigator.pushNamed(
                              context,
                              AppRouter.sedeForm,
                              arguments: sede,
                            );
                          },
                          onDelete: () => _confirmDelete(sede),
                          onToggleStatus: () => context.read<SedeBloc>().add(
                            ToggleSedeActive(sede.id),
                          ),
                        );
                      }, childCount: filteredList.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(Sede sede) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: 'Eliminar Sede',
        body:
            '¿Estás seguro de que deseas eliminar la sede "${sede.nombreSede}"? Esta acción no se puede deshacer.',
        onConfirm: () {
          context.read<SedeBloc>().add(DeleteSede(sede.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SedeHeader extends StatelessWidget {
  final bool canWrite;
  const _SedeHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Configuración', 'Sedes']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gestión de Sedes',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administra las oficinas y puntos de atención de la agencia.',
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
                label: 'Nueva Sede',
                icon: Icons.add_rounded,
                onPressed: () {
                  print('Nueva Sede');
                  Navigator.pushNamed(context, AppRouter.sedeForm);
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEDE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SedeCard extends StatefulWidget {
  final Sede sede;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _SedeCard({
    required this.sede,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  State<_SedeCard> createState() => _SedeCardState();
}

class _SedeCardState extends State<_SedeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sede;

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
            onTap: widget.canWrite ? widget.onEdit : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: s.isActive
                          ? SaasPalette.brand50
                          : SaasPalette.bgSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: s.isActive
                          ? SaasPalette.brand600
                          : SaasPalette.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.nombreSede,
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
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.direccion,
                                style: const TextStyle(
                                  color: SaasPalette.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.telefono,
                              style: const TextStyle(
                                color: SaasPalette.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (widget.canWrite) ...[
                    const SizedBox(width: 16),
                    _SedeActionMenu(
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onToggleStatus: widget.onToggleStatus,
                      isActive: s.isActive,
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

class _SedeActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final bool isActive;

  const _SedeActionMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.isActive,
  });

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
        if (value == 'toggle') onToggleStatus();
      },
      itemBuilder: (context) => [
        _buildMenuItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          label: 'Editar Sede',
          color: SaasPalette.textPrimary,
        ),
        _buildMenuItem(
          value: 'toggle',
          icon: isActive
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          label: isActive ? 'Desactivar Sede' : 'Activar Sede',
          color: isActive ? SaasPalette.warning : SaasPalette.success,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          value: 'delete',
          icon: Icons.delete_outline_rounded,
          label: 'Eliminar Sede',
          color: SaasPalette.danger,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
