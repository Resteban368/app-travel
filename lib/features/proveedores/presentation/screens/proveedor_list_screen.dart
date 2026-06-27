import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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

        final authState = context.watch<AuthBloc>().state;
        final canWrite = authState is AuthAuthenticated
            ? authState.user.canWrite('proveedores')
            : true;

        final filtered = _search.isEmpty
            ? proveedores
            : proveedores.where((p) {
                final q = _search.toLowerCase();
                return p.nombre.toLowerCase().contains(q) ||
                    p.tipo.toLowerCase().contains(q) ||
                    (p.nit?.toLowerCase().contains(q) ?? false);
              }).toList();

        return RefreshIndicator(
          color: context.saas.brand600,
          onRefresh: () async =>
              context.read<ProveedorBloc>().add(const LoadProveedores()),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _ProveedorHeader(canWrite: canWrite),
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
                          color: context.saas.textTertiary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'No hay proveedores registrados'
                              : 'Sin resultados para "$_search"',
                          style: TextStyle(
                            color: context.saas.textSecondary,
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
                        child: _ProveedorCard(proveedor: filtered[index], canWrite: canWrite),
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
  final bool canWrite;
  const _ProveedorHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    final addBtn = ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, AppRouter.proveedorCreate),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Nuevo Proveedor'),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.saas.brand600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );

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
                      color: context.saas.brand50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: context.saas.brand600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Proveedores',
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (canWrite) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: addBtn),
              ],
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
                          color: context.saas.brand50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: context.saas.brand600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Proveedores',
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestión de proveedores del negocio',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite) addBtn,
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
        color: context.saas.brand50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.saas.brand600.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label(tipo),
        style: TextStyle(
          color: context.saas.brand600,
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
  final bool canWrite;
  const _ProveedorCard({required this.proveedor, required this.canWrite});

  @override
  State<_ProveedorCard> createState() => _ProveedorCardState();
}

class _ProveedorCardState extends State<_ProveedorCard> {
  bool _hovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.saas.bgCanvas,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar proveedor?',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Se eliminará "${widget.proveedor.nombre}" permanentemente.',
          style: TextStyle(color: context.saas.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.saas.textSecondary),
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
              backgroundColor: context.saas.danger,
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
          color: context.saas.bgCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? context.saas.brand600.withValues(alpha: 0.3)
                : context.saas.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: context.saas.brand600.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          onTap: () async {
            final bloc = context.read<ProveedorBloc>();
            await Navigator.pushNamed(
              context,
              AppRouter.proveedorEdit,
              arguments: p,
            );
            bloc.add(const LoadProveedores());
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.saas.brand50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: context.saas.brand600,
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
                            style: TextStyle(
                              color: context.saas.textPrimary,
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
                              Icon(
                                Icons.badge_outlined,
                                size: 12,
                                color: context.saas.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'NIT: ${p.nit}',
                                style: TextStyle(
                                  color: context.saas.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        if (p.telefono != null && p.telefono!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 12,
                                color: context.saas.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.telefono!,
                                style: TextStyle(
                                  color: context.saas.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        if (p.email != null && p.email!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_rounded,
                                size: 12,
                                color: context.saas.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.email!,
                                style: TextStyle(
                                  color: context.saas.textSecondary,
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
              if (widget.canWrite) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: context.saas.textTertiary,
                    size: 18,
                  ),
                  color: context.saas.bgCanvas,
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
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: context.saas.brand600),
                          SizedBox(width: 8),
                          Text('Editar', style: TextStyle(color: context.saas.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: context.saas.danger),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: context.saas.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }
}
