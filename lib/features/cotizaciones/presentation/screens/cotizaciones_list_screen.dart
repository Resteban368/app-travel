import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_router.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/cotizacion.dart';
import '../bloc/cotizacion_bloc.dart';
import '../bloc/cotizacion_event.dart';
import '../bloc/cotizacion_state.dart';

class CotizacionesListScreen extends StatelessWidget {
  const CotizacionesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 12, child: _CotizacionesBody());
  }
}

class _CotizacionesBody extends StatefulWidget {
  const _CotizacionesBody();
  @override
  State<_CotizacionesBody> createState() => _CotizacionesBodyState();
}

class _CotizacionesBodyState extends State<_CotizacionesBody>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Animations
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _listOpacity;
  late final Animation<double> _floatY;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    context.read<CotizacionBloc>().add(LoadCotizaciones());

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _listOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _floatY = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDetails(BuildContext context, Cotizacion cot) {
    Navigator.pushNamed(context, AppRouter.cotizacionDetail, arguments: cot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.bg,
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,

      //   title: const Text(
      //     'Cotizaciones',
      //     style: TextStyle(
      //       color: Colors.white,
      //       fontSize: 18,
      //       fontWeight: FontWeight.w600,
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [
          // Background animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatCtrl, _shimmerCtrl]),
              builder: (_, __) =>
                  _Background(shimmer: _shimmer.value, floatY: _floatY.value),
            ),
          ),

          // Contenido
          SafeArea(
            child: BlocBuilder<CotizacionBloc, CotizacionState>(
              builder: (context, state) {
                List<Cotizacion> list = [];
                if (state is CotizacionLoaded) {
                  list = state.cotizaciones;
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    list = list.where((c) {
                      final chat = c.chatId.toLowerCase();
                      return c.nombreCompleto.toLowerCase().contains(q) ||
                          c.detallesPlan.toLowerCase().contains(q) ||
                          chat.contains(q);
                    }).toList();
                  }
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<CotizacionBloc>().add(LoadCotizaciones()),
                  backgroundColor: D.surface,
                  color: D.skyBlue,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header Section
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        sliver: SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _headerOpacity,
                            child: SlideTransition(
                              position: _headerSlide,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Expanded(child: _ScreenSectionHeader()),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, AppRouter.cotizacionCreate),
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [D.indigo, D.royalBlue]),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: D.indigo.withOpacity(0.3),
                                                blurRadius: 15,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _SearchBar(
                                    controller: _searchCtrl,
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    onClear: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // List Section
                      if (state is CotizacionLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: D.skyBlue),
                          ),
                        )
                      else if (state is CotizacionError)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar cotizaciones',
                                  style: TextStyle(
                                    color: D.slate400,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () => context
                                      .read<CotizacionBloc>()
                                      .add(LoadCotizaciones()),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: D.indigo,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Reintentar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (list.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.request_quote_outlined,
                                  size: 64,
                                  color: D.slate600,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron cotizaciones',
                                  style: TextStyle(
                                    color: D.slate400,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final cot = list[index];
                              return FadeTransition(
                                opacity: _listOpacity,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CotizacionCard(
                                    cotizacion: cot,
                                    onTap: () => _showDetails(context, cot),
                                  ),
                                ),
                              );
                            }, childCount: list.length),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BACKGROUND ─────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final double shimmer;
  final double floatY;
  const _Background({required this.shimmer, required this.floatY});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [D.bg, Color(0xFF081223), Color(0xFF050A14)],
            ),
          ),
        ),
        // Orbe Indigo centralizado para Cotizaciones
        Positioned(
          top: 100 + floatY * 0.5,
          right: -40,
          child: _orb(300, D.indigo.withOpacity(0.12 + shimmer * 0.05)),
        ),
        Positioned(
          bottom: 40 - floatY,
          left: -60,
          child: _orb(250, D.royalBlue.withOpacity(0.08)),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotPainter())),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1A2E45).withOpacity(0.45)
      ..strokeCap = StrokeCap.round;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── HEADER ─────────────────────────────────────────────────────────────────
class _ScreenSectionHeader extends StatelessWidget {
  const _ScreenSectionHeader();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [D.indigo, D.royalBlue]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.request_quote_rounded, color: Colors.white, size: 12),
              SizedBox(width: 6),
              Text(
                'CENTRO DE ATENCIÓN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Cotizaciones Recibidas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona las propuestas de viaje de tus clientes.',
          style: TextStyle(color: D.slate400, fontSize: 14),
        ),
      ],
    );
  }
}

// ─── SEARCH BAR ─────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;
  final _node = FocusNode();

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() => _focused = _node.hasFocus));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? D.indigo.withOpacity(0.6) : D.border,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: D.indigo.withOpacity(0.1), blurRadius: 12)]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _node,
        onChanged: widget.onChanged,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o celular...',
          hintStyle: const TextStyle(color: D.slate600, fontSize: 14),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _focused ? D.indigo : D.slate600,
            size: 22,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: D.slate400,
                    size: 18,
                  ),
                  onPressed: widget.onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }
}

// ─── CARD ──────────────────────────────────────────────────────────────────
class _CotizacionCard extends StatefulWidget {
  final Cotizacion cotizacion;
  final VoidCallback onTap;
  const _CotizacionCard({required this.cotizacion, required this.onTap});

  @override
  State<_CotizacionCard> createState() => _CotizacionCardState();
}

class _CotizacionCardState extends State<_CotizacionCard> {
  bool _hover = false;

  List<Color> _estadoColors(String estado) {
    switch (estado.toLowerCase()) {
      case 'atendida':
        return [D.emerald, const Color(0xFF059669)];
      case 'cancelada':
        return [D.rose, const Color(0xFFBE123C)];
      case 'pendiente':
      default:
        return [Colors.amber.shade700, Colors.orange.shade800];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    final isUnread = !c.isRead;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hover
              ? (Matrix4.identity()..translate(0, -2))
              : Matrix4.identity(),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? D.surfaceHigh : D.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread
                  ? D.indigo.withOpacity(_hover ? 0.6 : 0.3)
                  : D.border,
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [
              if (isUnread || _hover)
                BoxShadow(
                  color: (isUnread ? D.indigo : Colors.black).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _estadoColors(c.estado),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isUnread
                      ? Icons.mark_as_unread_rounded
                      : Icons.mark_email_read_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.nombreCompleto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _estadoColors(c.estado).first.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _estadoColors(c.estado).first.withOpacity(0.5)),
                          ),
                          child: Text(
                            c.estado.toUpperCase(),
                            style: TextStyle(
                              color: _estadoColors(c.estado).first,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: D.indigo.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NUEVA',
                              style: TextStyle(
                                color: D.indigo,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.detallesPlan,
                      style: TextStyle(color: D.slate400, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: D.slate600,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'dd MMM, hh:mm a',
                          ).format(c.createdAt.toLocal()),
                          style: TextStyle(color: D.slate600, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: D.slate600),
            ],
          ),
        ),
      ),
    );
  }
}
