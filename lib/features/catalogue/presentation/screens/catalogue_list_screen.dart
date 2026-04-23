import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/catalogue.dart';
import '../bloc/catalogue_bloc.dart';
import '../bloc/catalogue_event.dart';
import '../bloc/catalogue_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CatalogueListScreen extends StatelessWidget {
  const CatalogueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 4, child: _CatalogueListBody());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BODY
// ─────────────────────────────────────────────────────────────────────────────
class _CatalogueListBody extends StatefulWidget {
  const _CatalogueListBody();

  @override
  State<_CatalogueListBody> createState() => _CatalogueListBodyState();
}

class _CatalogueListBodyState extends State<_CatalogueListBody> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CatalogueBloc>().add(LoadCatalogues());
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
        authState is AuthAuthenticated && authState.user.canWrite('catalogues');

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          List<Catalogue> list = [];
          if (state is CatalogueLoaded) {
            list = state.catalogues;
          } else if (state is CatalogueSaving && state.catalogues != null) {
            list = state.catalogues!;
          } else if (state is CatalogueSaved && state.catalogues != null) {
            list = state.catalogues!;
          }

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            list = list
                .where((c) => c.nombreCatalogue.toLowerCase().contains(q))
                .toList();
          }

          final isLoading = state is CatalogueLoading && list.isEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<CatalogueBloc>().add(LoadCatalogues()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CatalogueHeader(canWrite: canWrite),
                  ),
                ),

                // ── Search bar (shared SaasSearchField) ────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar catálogos por nombre…',
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
                else if (list.isEmpty)
                  SliverFillRemaining(
                    child: SaasEmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.picture_as_pdf_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin resultados'
                          : 'Sin catálogos',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos catálogos con ese nombre.'
                          : 'Empieza añadiendo tu primer catálogo.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final cat = list[index];
                        return _CatalogueCard(
                          catalogue: cat,
                          canWrite: canWrite,
                          onEdit: () => Navigator.pushNamed(
                            context,
                            AppRouter.catalogueEdit,
                            arguments: cat,
                          ),
                          onDelete: () => _confirmDelete(cat),
                          onStatusChanged: (v) {
                            context.read<CatalogueBloc>().add(
                              UpdateCatalogue(cat.copyWith(activo: v)),
                            );
                          },
                        );
                      }, childCount: list.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(Catalogue cat) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: 'Eliminar catálogo',
        body:
            'Estás a punto de eliminar "${cat.nombreCatalogue}". Esta acción no se puede deshacer.',
        onConfirm: () {
          context.read<CatalogueBloc>().add(DeleteCatalogue(cat.idCatalogue));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER  (usa SaasBreadcrumbs + SaasButton del sistema de diseño)
// ─────────────────────────────────────────────────────────────────────────────
class _CatalogueHeader extends StatelessWidget {
  final bool canWrite;
  const _CatalogueHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Catálogos']),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Catálogos',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestiona tus guías y PDFs informativos para clientes.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite) ...[
              const SizedBox(width: 16),
              SaasButton(
                label: 'Nuevo',
                icon: Icons.add_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.catalogueCreate),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CATALOGUE CARD  (específico de este módulo — no es reutilizable per-se)
// ─────────────────────────────────────────────────────────────────────────────
class _CatalogueCard extends StatefulWidget {
  final Catalogue catalogue;
  final bool canWrite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onStatusChanged;

  const _CatalogueCard({
    required this.catalogue,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  State<_CatalogueCard> createState() => _CatalogueCardState();
}

class _CatalogueCardState extends State<_CatalogueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.catalogue;
    final dateStr = DateFormat('dd MMM yyyy', 'es').format(cat.fechaCreacion);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? SaasPalette.brand600 : SaasPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.07 : 0.03),
                blurRadius: _hovered ? 16 : 6,
                offset: Offset(0, _hovered ? 6 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.canWrite ? widget.onEdit : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ── Icon ────────────────────────────────────────────────
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cat.activo
                          ? SaasPalette.brand600.withOpacity(0.1)
                          : SaasPalette.bgSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: cat.activo
                          ? SaasPalette.brand600
                          : SaasPalette.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ── Info ────────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.nombreCatalogue,
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ✅ Shared SaasStatusBadge
                            SaasStatusBadge(active: cat.activo),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.link_rounded,
                              size: 12,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cat.urlArchivo,
                                style: const TextStyle(
                                  color: SaasPalette.brand600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Actions ─────────────────────────────────────────────
                  if (widget.canWrite) ...[
                    const SizedBox(width: 12),
                    _ActionMenu(
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onToggleStatus: () => widget.onStatusChanged(!cat.activo),
                      isActive: cat.activo,
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

// ─────────────────────────────────────────────────────────────────────────────
//  ACTION MENU  (específico: opciones Editar / Activar / Eliminar)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final bool isActive;

  const _ActionMenu({
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
        size: 20,
      ),
      color: SaasPalette.bgCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SaasPalette.border),
      ),
      elevation: 4,
      itemBuilder: (_) => [
        _item('edit', Icons.edit_rounded, 'Editar', SaasPalette.textPrimary),
        _item(
          'toggle',
          isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          isActive ? 'Desactivar' : 'Activar',
          isActive ? SaasPalette.warning : SaasPalette.success,
        ),
        _item(
          'delete',
          Icons.delete_outline_rounded,
          'Eliminar',
          SaasPalette.danger,
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'toggle') onToggleStatus();
        if (value == 'delete') onDelete();
      },
    );
  }

  PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
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
