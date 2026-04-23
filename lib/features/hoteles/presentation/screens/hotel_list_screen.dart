import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_router.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/hotel.dart';
import '../bloc/hotel_bloc.dart';
import '../bloc/hotel_event.dart';
import '../bloc/hotel_state.dart';

class HotelListScreen extends StatelessWidget {
  const HotelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 14, child: _HotelListBody());
  }
}

class _HotelListBody extends StatefulWidget {
  const _HotelListBody();

  @override
  State<_HotelListBody> createState() => _HotelListBodyState();
}

class _HotelListBodyState extends State<_HotelListBody> {
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
        ? authState.user.canWrite('hoteles')
        : false;

    return BlocConsumer<HotelBloc, HotelState>(
      listener: (context, state) {
        if (state is HotelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: SaasPalette.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        List<Hotel> hoteles = [];
        if (state is HotelLoaded) hoteles = state.hoteles;
        if (state is HotelSaving && state.hoteles != null) hoteles = state.hoteles!;
        if (state is HotelSaved && state.hoteles != null) hoteles = state.hoteles!;

        final filtered = _search.isEmpty
            ? hoteles
            : hoteles.where((h) {
                final q = _search.toLowerCase();
                return h.nombre.toLowerCase().contains(q) ||
                    h.ciudad.toLowerCase().contains(q) ||
                    h.direccion.toLowerCase().contains(q);
              }).toList();

        return RefreshIndicator(
          color: SaasPalette.brand600,
          onRefresh: () async =>
              context.read<HotelBloc>().add(const LoadHoteles()),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _HotelHeader(canWrite: canWrite),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: SaasSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar por nombre, ciudad o dirección...',
                    onChanged: (v) => setState(() => _search = v),
                    onClear: () => setState(() {
                      _searchCtrl.clear();
                      _search = '';
                    }),
                  ),
                ),
              ),
              if (state is HotelLoading && hoteles.isEmpty)
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
                          Icons.hotel_rounded,
                          size: 56,
                          color: SaasPalette.textTertiary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _search.isEmpty
                              ? 'No hay hoteles registrados'
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
                        child: _HotelCard(
                          hotel: filtered[index],
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

class _HotelHeader extends StatelessWidget {
  final bool canWrite;
  const _HotelHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
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
                      Icons.hotel_rounded,
                      color: SaasPalette.brand600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Hoteles',
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
                'Gestión de hoteles disponibles',
                style: TextStyle(color: SaasPalette.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (canWrite)
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.hotelCreate),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nuevo Hotel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SaasPalette.brand600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _HotelCard extends StatefulWidget {
  final Hotel hotel;
  final bool canWrite;
  const _HotelCard({required this.hotel, required this.canWrite});

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard> {
  bool _hovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaasPalette.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar hotel?',
          style: TextStyle(
              color: SaasPalette.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará "${widget.hotel.nombre}" permanentemente.',
          style: const TextStyle(color: SaasPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: SaasPalette.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HotelBloc>().add(DeleteHotel(widget.hotel.id!));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SaasPalette.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
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
                  Icons.hotel_rounded,
                  color: SaasPalette.brand600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.nombre,
                      style: const TextStyle(
                        color: SaasPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_city_rounded,
                            size: 12, color: SaasPalette.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          hotel.ciudad,
                          style: const TextStyle(
                              color: SaasPalette.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.phone_rounded,
                            size: 12, color: SaasPalette.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          hotel.telefono,
                          style: const TextStyle(
                              color: SaasPalette.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: SaasPalette.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hotel.direccion,
                            style: const TextStyle(
                                color: SaasPalette.textTertiary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SaasStatusBadge(active: hotel.isActive),
              if (widget.canWrite) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: SaasPalette.textTertiary, size: 18),
                  color: SaasPalette.bgCanvas,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        AppRouter.hotelEdit,
                        arguments: hotel,
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
                          Icon(Icons.edit_rounded,
                              size: 16, color: SaasPalette.brand600),
                          SizedBox(width: 8),
                          Text('Editar',
                              style:
                                  TextStyle(color: SaasPalette.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: SaasPalette.danger),
                          SizedBox(width: 8),
                          Text('Eliminar',
                              style: TextStyle(color: SaasPalette.danger)),
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
    );
  }
}
