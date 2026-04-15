import 'dart:math' as math;
import 'package:agente_viajes/core/widgets/SmallBtn_widget.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/service.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 6, child: _ServiceListBody());
  }
}

class _ServiceListBody extends StatefulWidget {
  const _ServiceListBody();

  @override
  State<_ServiceListBody> createState() => _ServiceListBodyState();
}

class _ServiceListBodyState extends State<_ServiceListBody>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

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
    _searchCtrl.dispose();
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite =
        authState is AuthAuthenticated && authState.user.canWrite('services');

    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(
        children: [
          // Background Animations
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 + math.sin(_bgCtrl.value * math.pi * 2) * 40,
                    left: -100 + math.cos(_bgCtrl.value * math.pi * 2) * 60,
                    child: _Orb(
                      color: D.royalBlue.withOpacity(0.12),
                      size: 350,
                    ),
                  ),
                  Positioned(
                    bottom: -80 + math.cos(_bgCtrl.value * math.pi * 2) * 50,
                    right: -60 + math.sin(_bgCtrl.value * math.pi * 2) * 40,
                    child: _Orb(color: D.indigo.withOpacity(0.08), size: 300),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          // Content
          BlocBuilder<ServiceBloc, ServiceState>(
            builder: (context, state) {
              return CustomScrollView(
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
                  _buildSearch(context),
                  SliverFadeTransition(
                    opacity: _contentOpacity,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      sliver: _buildSliverContent(state, canWrite),
                    ),
                  ),
                ],
              );
            },
          ),

          // Saving Overlay
          BlocBuilder<ServiceBloc, ServiceState>(
            builder: (context, state) {
              if (state is ServiceSaving) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(D.skyBlue),
                    minHeight: 3,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
                    Icons.settings_suggest_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PORTAFOLIO DE SERVICIOS',
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
              'Servicios',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestiona los beneficios y extras ofrecidos.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (canWrite)
          _AddBtn(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.serviceCreate),
          ),
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
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
              hintText: 'Buscar servicios o descripción...',
              hintStyle: TextStyle(color: D.slate600),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: D.slate400,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: D.slate400,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(ServiceState state, bool canWrite) {
    List<Service>? currentServices;
    if (state is ServicesLoaded)
      currentServices = state.services;
    else if (state is ServiceSaving && state.services != null)
      currentServices = state.services;
    else if (state is ServiceSaved && state.services != null)
      currentServices = state.services;

    if (state is ServiceLoading && currentServices == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _SkelCard(),
          childCount: 5,
        ),
      );
    }

    if (state is ServiceError && currentServices == null) {
      return SliverFillRemaining(
        child: Center(child: _ErrorDisplay(message: state.message)),
      );
    }

    if (currentServices != null) {
      final filtered = currentServices
          .where(
            (s) =>
                s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();

      if (filtered.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyDisplay(query: _searchQuery),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ServiceCard(
            service: filtered[index],
            index: index,
            isAdmin: canWrite,
            onDelete: () => _confirmDelete(filtered[index]),
          ),
          childCount: filtered.length,
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  void _confirmDelete(Service service) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Servicio?',
        content: 'El servicio "${service.name}" se eliminará permanentemente.',
        onConfirm: () {
          context.read<ServiceBloc>().add(DeleteService(service.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final Service service;
  final int index;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.index,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return AnimatedPadding(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.serviceEdit,
            arguments: widget.service,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.service.isActive
                  ? D.surface
                  : D.surface.withOpacity(0.4),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: D.royalBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.settings_suggest_rounded,
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
                            widget.service.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: widget.service.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: D.slate400,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: D.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.service.cost != null
                            ? currencyFormat.format(widget.service.cost)
                            : 'Gratuito',
                        style: TextStyle(
                          color: D.emerald,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (widget.isAdmin)
                      Row(
                        children: [
                          SmallBtn(
                            icon: Icons.edit_rounded,
                            color: D.skyBlue,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.serviceEdit,
                              arguments: widget.service,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SmallBtn(
                            icon: Icons.delete_outline_rounded,
                            color: D.rose,
                            onTap: widget.onDelete,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: D.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String message;
  const _ErrorDisplay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, color: D.rose, size: 48),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.white)),
        TextButton(
          onPressed: () => context.read<ServiceBloc>().add(LoadServices()),
          child: const Text('Reintentar', style: TextStyle(color: D.skyBlue)),
        ),
      ],
    );
  }
}

class _EmptyDisplay extends StatelessWidget {
  final String query;
  const _EmptyDisplay({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.room_service_outlined, size: 80, color: D.slate600),
          const SizedBox(height: 24),
          Text(
            query.isEmpty
                ? 'Sin servicios adicionales'
                : 'No hay resultados para "$query"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty
                ? 'Los beneficios extras aparecerán aquí'
                : 'Intenta con otros términos',
            style: TextStyle(color: D.slate400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PremiumConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
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
        padding: const EdgeInsets.all(24),
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
                      style: TextStyle(
                        color: D.slate400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: D.rose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Eliminar',
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
