import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/bus_layout.dart';
import '../bloc/bus_layout_bloc.dart';
import '../bloc/bus_layout_event.dart';
import '../bloc/bus_layout_state.dart';

class BusLayoutListScreen extends StatelessWidget {
  const BusLayoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _BusLayoutListBody());
  }
}

class _BusLayoutListBody extends StatefulWidget {
  const _BusLayoutListBody();

  @override
  State<_BusLayoutListBody> createState() => _BusLayoutListBodyState();
}

class _BusLayoutListBodyState extends State<_BusLayoutListBody> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('bus_layouts')
        : false;

    return BlocConsumer<BusLayoutBloc, BusLayoutState>(
      listener: (context, state) {
        if (state is BusLayoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.saas.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        List<BusLayout> layouts = [];
        if (state is BusLayoutLoaded) layouts = state.layouts;
        if (state is BusLayoutSaving && state.layouts != null) {
          layouts = state.layouts!;
        }
        if (state is BusLayoutSaved && state.layouts != null) {
          layouts = state.layouts!;
        }

        final filtered = _search.isEmpty
            ? layouts
            : layouts.where((l) {
                final q = _search.toLowerCase();
                return l.nombre.toLowerCase().contains(q) ||
                    l.descripcion.toLowerCase().contains(q);
              }).toList();

        return RefreshIndicator(
          color: context.saas.brand600,
          onRefresh: () async =>
              context.read<BusLayoutBloc>().add(const LoadBusLayouts()),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _BusLayoutHeader(canWrite: canWrite),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: SaasSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar por nombre o descripción...',
                    onChanged: (v) => setState(() => _search = v),
                    onClear: () => setState(() {
                      _searchCtrl.clear();
                      _search = '';
                    }),
                  ),
                ),
              ),
              if (state is BusLayoutLoading && layouts.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const SaasListSkeleton(),
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
                          Icons.directions_bus_rounded,
                          size: 56,
                          color: context.saas.textTertiary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'No hay layouts de bus registrados'
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
                        child: _BusLayoutCard(
                          layout: filtered[index],
                          canWrite: canWrite,
                        ),
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

class _BusLayoutHeader extends StatelessWidget {
  final bool canWrite;
  const _BusLayoutHeader({required this.canWrite});

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
                      color: context.saas.brand50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: context.saas.brand600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Diseños de Bus',
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (canWrite)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.busLayoutCreate),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nuevo Diseño'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.saas.brand600,
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
                          color: context.saas.brand50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_bus_rounded,
                          color: context.saas.brand600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Diseños de Bus',
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
                    'Configuraciones de distribución de asientos',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite)
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.busLayoutCreate),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo Diseño'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.saas.brand600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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

// ── Card ──────────────────────────────────────────────────────────────────────

class _BusLayoutCard extends StatefulWidget {
  final BusLayout layout;
  final bool canWrite;
  const _BusLayoutCard({required this.layout, required this.canWrite});

  @override
  State<_BusLayoutCard> createState() => _BusLayoutCardState();
}

class _BusLayoutCardState extends State<_BusLayoutCard> {
  bool _hovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar layout?',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Se desactivará "${widget.layout.nombre}".',
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
              context.read<BusLayoutBloc>().add(
                DeleteBusLayout(widget.layout.id!),
              );
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
    final layout = widget.layout;
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
            final bloc = context.read<BusLayoutBloc>();
            await Navigator.pushNamed(
              context,
              AppRouter.busLayoutEdit,
              arguments: layout,
            );
            bloc.add(const LoadBusLayouts());
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
                    Icons.directions_bus_rounded,
                    color: context.saas.brand600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layout.nombre,
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (layout.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          layout.descripcion,
                          style: TextStyle(
                            color: context.saas.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.saas.brand50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: context.saas.brand600.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_seat_rounded,
                                  size: 11,
                                  color: context.saas.brand600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${layout.totalAsientosCliente} asientos',
                                  style: TextStyle(
                                    color: context.saas.brand600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (layout.configuracion != null)
                            Text(
                              '${layout.configuracion!.filas} filas × ${layout.configuracion!.columnas} col.',
                              style: TextStyle(
                                color: context.saas.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SaasStatusBadge(active: layout.activo),
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
                          AppRouter.busLayoutEdit,
                          arguments: layout,
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
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: context.saas.brand600,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Editar',
                              style: TextStyle(color: context.saas.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: context.saas.danger,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: context.saas.danger),
                            ),
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
