import 'package:agente_viajes/core/widgets/SmallBtn_widget.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
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

class _PoliticaReservaListScreenState extends State<PoliticaReservaListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentIndex: 7,
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            // Background Orbs
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    top: -100 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                    right: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 40,
                    child: _Orb(color: D.royalBlue.withOpacity(0.1), size: 450),
                  ),
                  Positioned(
                    bottom: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 30,
                    left: -100 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                    child: _Orb(color: D.indigo.withOpacity(0.08), size: 350),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

            BlocBuilder<PoliticaReservaBloc, PoliticaReservaState>(
              builder: (context, state) {
                final authState = context.watch<AuthBloc>().state;
                final canWrite =
                    authState is AuthAuthenticated &&
                    authState.user.canWrite('politicasReserva');

                List<PoliticaReserva>? politicas;
                if (state is PoliticaLoaded) {
                  politicas = state.politicas;
                } else if (state is PoliticaSaving && state.politicas != null) {
                  politicas = state.politicas;
                } else if (state is PoliticaSaved) {
                  politicas = state.politicas;
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _headerOpacity,
                          child: SlideTransition(
                            position: _headerSlide,
                            child: _buildHeader(context, canWrite),
                          ),
                        ),
                      ),
                    ),
                    _buildSearchBar(),
                    SliverFadeTransition(
                      opacity: _contentOpacity,
                      sliver: _buildContent(
                        context,
                        state,
                        politicas,
                        canWrite,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canWrite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.policy_rounded, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'POLÍTICAS Y TÉRMINOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Políticas de Reserva',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Condiciones y términos de servicio.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (canWrite)
          _AddBtn(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.politicaReservaCreate),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: D.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: D.border.withOpacity(0.5)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar políticas...',
              hintStyle: TextStyle(color: D.slate600, fontSize: 14),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: D.slate600,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PoliticaReservaState state,
    List<PoliticaReserva>? politicas,
    bool isAdmin,
  ) {
    if (state is PoliticaLoading && politicas == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _SkelCard(),
          childCount: 4,
        ),
      );
    }

    if (politicas == null || politicas.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState());
    }

    final filtered = politicas
        .where(
          (p) =>
              p.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.descripcion.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState(isSearch: true));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final politica = filtered[index];
          return _PoliticaCard(
            politica: politica,
            isAdmin: isAdmin,
            state: state,
          );
        }, childCount: filtered.length),
      ),
    );
  }
}

class _PoliticaCard extends StatefulWidget {
  final PoliticaReserva politica;
  final bool isAdmin;
  final PoliticaReservaState state;
  const _PoliticaCard({
    required this.politica,
    required this.isAdmin,
    required this.state,
  });

  @override
  State<_PoliticaCard> createState() => _PoliticaCardState();
}

class _PoliticaCardState extends State<_PoliticaCard> {
  bool _hovered = false;

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Política?',
        content:
            'Esta acción borrará "${widget.politica.titulo}" permanentemente.',
        onConfirm: () {
          context.read<PoliticaReservaBloc>().add(
            DeletePolitica(widget.politica.id),
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.politica;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: p.activo ? D.surface : D.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered ? D.royalBlue.withOpacity(0.5) : D.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.politicaReservaEdit,
            arguments: p,
          ),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: D.royalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.policy_rounded,
                    color: D.royalBlue,
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
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!p.activo)
                            _Tag(label: 'INACTIVO', color: D.slate600),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: D.slate400, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TypeBadge(type: p.tipoPolitica),
                          const Spacer(),
                          if (widget.isAdmin) _buildAdminActions(),
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
    );
  }

  Widget _buildAdminActions() {
    final isSaving = widget.state is PoliticaSaving;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SmallBtn(
          icon: Icons.edit_rounded,
          color: D.skyBlue,
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.politicaReservaEdit,
            arguments: widget.politica,
          ),
        ),
        const SizedBox(width: 12),
        SmallBtn(
          icon: Icons.delete_outline_rounded,
          color: D.rose,
          onTap: isSaving ? () {} : _confirmDelete,
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: D.bg.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: D.border),
    ),
    child: Text(
      type.toUpperCase(),
      style: TextStyle(
        color: D.skyBlue,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withOpacity(0.2);
    const spacing = 32.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [D.royalBlue, D.indigo]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: D.royalBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
    decoration: BoxDecoration(
      color: D.surface.withOpacity(0.5),
      borderRadius: BorderRadius.circular(22),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({this.isSearch = false});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSearch ? Icons.search_off_rounded : Icons.policy_outlined,
          size: 64,
          color: D.slate800,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch
              ? 'No se encontraron políticas'
              : 'Sin políticas registradas',
          style: TextStyle(
            color: D.slate600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _PremiumConfirmDialog extends StatelessWidget {
  final String title, content;
  final VoidCallback onConfirm;
  const _PremiumConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: D.rose, size: 48),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(color: D.slate400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: D.slate400),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.rose,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
