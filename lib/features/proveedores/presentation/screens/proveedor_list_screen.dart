import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/proveedor.dart';
import '../bloc/proveedor_bloc.dart';
import '../bloc/proveedor_event.dart';
import '../bloc/proveedor_state.dart';

class ProveedorListScreen extends StatelessWidget {
  const ProveedorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _ProveedorListBody());
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _ProveedorListBody extends StatefulWidget {
  const _ProveedorListBody();

  @override
  State<_ProveedorListBody> createState() => _ProveedorListBodyState();
}

class _ProveedorListBodyState extends State<_ProveedorListBody> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProveedorBloc, ProveedorState>(
      listener: (context, state) {
        if (state is ProveedorError) {
          SaasSnackBar.showError(context, state.message);
        }
      },
      builder: (context, state) {
        List<Proveedor> proveedores = [];
        if (state is ProveedorLoaded) proveedores = state.proveedores;
        if (state is ProveedorSaving && state.proveedores != null) {
          proveedores = state.proveedores!;
        }
        if (state is ProveedorSaved && state.proveedores != null) {
          proveedores = state.proveedores!;
        }

        final filtered = _search.isEmpty
            ? proveedores
            : proveedores.where((p) {
                final q = _search.toLowerCase();
                return p.nombre.toLowerCase().contains(q) ||
                    p.tipo.toLowerCase().contains(q) ||
                    (p.nit?.toLowerCase().contains(q) ?? false);
              }).toList();

        return RefreshIndicator(
          color: SaasPalette.brand600,
          onRefresh: () async =>
              context.read<ProveedorBloc>().add(const LoadProveedores()),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: const _ProveedorHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: SaasSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar por nombre, tipo o NIT...',
                    onChanged: (v) => setState(() => _search = v),
                    onClear: () => setState(() {
                      _searchCtrl.clear();
                      _search = '';
                    }),
                  ),
                ),
              ),
              if (state is ProveedorLoading && proveedores.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => const SaasListSkeleton(),
                      childCount: 5,
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 56,
                          color: SaasPalette.textTertiary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'No hay proveedores registrados'
                              : 'Sin resultados para "$_search"',
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProveedorCard(proveedor: filtered[index]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProveedorHeader extends StatelessWidget {
  const _ProveedorHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SaasPalette.brand50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: SaasPalette.brand600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Proveedores',
                      style: TextStyle(
                        color: SaasPalette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.proveedorCreate),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nuevo Proveedor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SaasPalette.brand600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SaasPalette.brand50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: SaasPalette.brand600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Proveedores',
                        style: TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestión de proveedores del negocio',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.proveedorCreate),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo Proveedor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SaasPalette.brand600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Chip tipo ─────────────────────────────────────────────────────────────────

class _TipoChip extends StatelessWidget {
  final String tipo;
  const _TipoChip(this.tipo);

  static String _label(String tipo) {
    const map = {
      'hotel': 'Hotel',
      'aerolinea': 'Aerolínea',
      'seguro': 'Seguro',
      'transporte': 'Transporte',
      'restaurante': 'Restaurante',
      'otro': 'Otro',
    };
    return map[tipo] ?? tipo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SaasPalette.brand50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SaasPalette.brand600.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label(tipo),
        style: const TextStyle(
          color: SaasPalette.brand600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _ProveedorCard extends StatefulWidget {
  final Proveedor proveedor;
  const _ProveedorCard({required this.proveedor});

  @override
  State<_ProveedorCard> createState() => _ProveedorCardState();
}

class _ProveedorCardState extends State<_ProveedorCard> {
  bool _hovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaasPalette.bgCanvas,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar proveedor?',
          style: TextStyle(
            color: SaasPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Se eliminará "${widget.proveedor.nombre}" permanentemente.',
          style: const TextStyle(color: SaasPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: SaasPalette.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ProveedorBloc>()
                  .add(DeleteProveedor(widget.proveedor.id!));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SaasPalette.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proveedor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? SaasPalette.brand600.withValues(alpha: 0.3)
                : SaasPalette.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: SaasPalette.brand600.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SaasPalette.brand50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: SaasPalette.brand600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.nombre,
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TipoChip(p.tipo),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (p.nit != null && p.nit!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 12,
                                color: SaasPalette.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'NIT: ${p.nit}',
                                style: const TextStyle(
                                  color: SaasPalette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        if (p.telefono != null && p.telefono!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 12,
                                color: SaasPalette.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.telefono!,
                                style: const TextStyle(
                                  color: SaasPalette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        if (p.email != null && p.email!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.email_rounded,
                                size: 12,
                                color: SaasPalette.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.email!,
                                style: const TextStyle(
                                  color: SaasPalette.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SaasStatusBadge(active: p.isActive),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: SaasPalette.textTertiary,
                  size: 18,
                ),
                color: SaasPalette.bgCanvas,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRouter.proveedorEdit,
                      arguments: p,
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: SaasPalette.brand600,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Editar',
                          style: TextStyle(color: SaasPalette.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: SaasPalette.danger,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: SaasPalette.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
