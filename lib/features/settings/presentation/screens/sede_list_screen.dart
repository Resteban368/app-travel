import 'package:agente_viajes/core/widgets/SmallBtn_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/sede.dart';
import '../bloc/sede_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class SedeListScreen extends StatefulWidget {
  const SedeListScreen({super.key});

  @override
  State<SedeListScreen> createState() => _SedeListScreenState();
}

class _SedeListScreenState extends State<SedeListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  final TextEditingController _searchCtrl = TextEditingController();
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

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });

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
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            // Floating Background Orbs
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: -100 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                      right: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 30,
                      child: _Orb(
                        color: D.royalBlue.withOpacity(0.12),
                        size: 400,
                      ),
                    ),
                    Positioned(
                      bottom: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 40,
                      left: -80 + math.sin(_bgCtrl.value * math.pi * 2) * 60,
                      child: _Orb(color: D.indigo.withOpacity(0.08), size: 350),
                    ),
                  ],
                );
              },
            ),
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

            BlocBuilder<SedeBloc, SedeState>(
              builder: (context, state) {
                final authState = context.watch<AuthBloc>().state;
                final canWrite =
                    authState is AuthAuthenticated &&
                    authState.user.canWrite('sedes');

                List<Sede>? sedes;
                if (state is SedesLoaded)
                  sedes = state.sedes;
                else if (state is SedeSaving && state.sedes != null)
                  sedes = state.sedes;
                else if (state is SedeSaved && state.sedes != null)
                  sedes = state.sedes;

                final filtered = sedes
                    ?.where(
                      (s) =>
                          s.nombreSede.toLowerCase().contains(_searchQuery) ||
                          s.direccion.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

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
                    _buildFilters(context),
                    SliverFadeTransition(
                      opacity: _contentOpacity,
                      sliver: _buildSliverContent(
                        context,
                        state,
                        filtered,
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
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'ADMINISTRACIÓN',
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
              'Sedes Mundiales',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona la ubicación y contacto de tus oficinas.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (canWrite)
          _AddBtn(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRouter.sedeForm,
              );
              if (result == true && context.mounted) {
                context.read<SedeBloc>().add(LoadSedes());
              }
            },
          ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o dirección...',
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

  Widget _buildSliverContent(
    BuildContext context,
    SedeState state,
    List<Sede>? sedes,
    bool canWrite,
  ) {
    if (state is SedeLoading && sedes == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _SkelCard(),
          childCount: 3,
        ),
      );
    }
    if (sedes == null || sedes.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyView(isSearch: _searchQuery.isNotEmpty),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _SedeCard(sede: sedes[index], canWrite: canWrite, index: index),
          childCount: sedes.length,
        ),
      ),
    );
  }
}

class _SedeCard extends StatefulWidget {
  final Sede sede;
  final bool canWrite;
  final int index;
  const _SedeCard({
    required this.sede,
    required this.canWrite,
    required this.index,
  });

  @override
  State<_SedeCard> createState() => _SedeCardState();
}

class _SedeCardState extends State<_SedeCard> {
  bool _isHovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Sede?',
        content:
            'Esto eliminará definitivamente la sede "${widget.sede.nombreSede}" del sistema.',
        onConfirm: () {
          context.read<SedeBloc>().add(DeleteSede(widget.sede.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: widget.sede.isActive ? D.surface : D.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? D.royalBlue.withOpacity(0.5) : D.border,
            width: 1.5,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: D.royalBlue.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.canWrite
              ? () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRouter.sedeForm,
                    arguments: widget.sede,
                  );
                  if (result == true && context.mounted) {
                    context.read<SedeBloc>().add(LoadSedes());
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: D.royalBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: D.skyBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sede.nombreSede,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(widget.sede.isActive),
                        ],
                      ),
                    ),
                    if (widget.canWrite) _buildDesktopActions(context),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.phone_rounded, widget.sede.telefono),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.place_rounded, widget.sede.direccion),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (active ? D.emerald : D.gold).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? D.emerald : D.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'ACTIVA' : 'OCULTA',
            style: TextStyle(
              color: active ? D.emerald : D.gold,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: D.slate600, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: D.slate400, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return SmallBtn(
      icon: Icons.delete_outline_rounded,
      color: D.rose,
      onTap: () => _confirmDelete(context),
    );
  }
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

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withOpacity(0.3);
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

class _EmptyView extends StatelessWidget {
  final bool isSearch;
  const _EmptyView({this.isSearch = false});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.store_rounded,
            size: 80,
            color: D.slate600,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? 'No encontramos sedes con ese nombre'
                : 'No hay sedes registradas',
            style: TextStyle(
              color: D.slate400,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(
        color: D.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Dialog(
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
            const Icon(Icons.warning_amber_rounded, color: D.rose, size: 54),
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
}
