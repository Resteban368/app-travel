import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/faq.dart';
import '../bloc/faq_bloc.dart';
import '../bloc/faq_event.dart';
import '../bloc/faq_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class FaqListScreen extends StatelessWidget {
  const FaqListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 5, child: _FaqListBody());
  }
}

class _FaqListBody extends StatefulWidget {
  const _FaqListBody();

  @override
  State<_FaqListBody> createState() => _FaqListBodyState();
}

class _FaqListBodyState extends State<_FaqListBody> with TickerProviderStateMixin {
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
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
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
    final canWrite = authState is AuthAuthenticated && authState.user.canWrite('faqs');
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
                    top: -100 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                    right: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 30,
                    child: _Orb(color: D.royalBlue.withOpacity(0.1), size: 400),
                  ),
                  Positioned(
                    bottom: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 40,
                    left: -80 + math.sin(_bgCtrl.value * math.pi * 2) * 60,
                    child: _Orb(color: D.indigo.withOpacity(0.08), size: 300),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          // Main Content
          BlocBuilder<FaqBloc, FaqState>(
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
                      sliver: _buildSliverContent(state),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Progress overlay for saving
          BlocBuilder<FaqBloc, FaqState>(
            builder: (context, state) {
              if (state is FaqSaving) {
                return Positioned(
                  top: 0, left: 0, right: 0,
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
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'CENTRO DE AYUDA',
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
              'Preguntas Frecuentes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Administra las dudas comunes de los clientes.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (canWrite)
          _AddBtn(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.faqCreate),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: D.border.withOpacity(0.5)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar dudas o palabras clave...',
              hintStyle: TextStyle(color: D.slate600),
              prefixIcon: Icon(Icons.search_rounded, color: D.slate400, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.close_rounded, color: D.slate400, size: 20),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                  )
                : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(FaqState state) {
    List<Faq>? currentFaqs;
    if (state is FaqsLoaded) currentFaqs = state.faqs;
    else if (state is FaqSaving && state.faqs != null) currentFaqs = state.faqs;
    else if (state is FaqSaved && state.faqs != null) currentFaqs = state.faqs;

    if (state is FaqLoading && currentFaqs == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _SkelCard(),
          childCount: 5,
        ),
      );
    }

    if (state is FaqError && currentFaqs == null) {
      return SliverFillRemaining(
        child: Center(
          child: _ErrorDisplay(message: state.message),
        ),
      );
    }

    if (currentFaqs != null) {
      final filtered = currentFaqs.where((f) => 
        f.question.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        f.answer.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();

      if (filtered.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyDisplay(query: _searchQuery),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _FaqCard(
            faq: filtered[index],
            index: index,
            onDelete: () => _confirmDelete(filtered[index]),
          ),
          childCount: filtered.length,
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  void _confirmDelete(Faq faq) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar FAQ?',
        content: 'Esta acción no se puede deshacer. La pregunta se eliminará permanentemente.',
        onConfirm: () {
          context.read<FaqBloc>().add(DeleteFaq(faq.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final Faq faq;
  final int index;
  final VoidCallback onDelete;

  const _FaqCard({required this.faq, required this.index, required this.onDelete});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _isExpanded = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: widget.faq.isActive ? D.surface : D.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isExpanded ? D.royalBlue.withOpacity(0.12) : D.royalBlue.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: _isHovered ? [
                BoxShadow(color: D.royalBlue.withOpacity(0.1), blurRadius: 20, spreadRadius: -5)
              ] : null,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: D.royalBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.help_outline_rounded, color: D.skyBlue, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.faq.question,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: widget.faq.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            if (!widget.faq.isActive)
                              Text('Inactiva', style: TextStyle(color: D.rose, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(Icons.expand_more_rounded, color: D.slate400),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: D.border),
                        const SizedBox(height: 12),
                        Text(
                          widget.faq.answer,
                          style: TextStyle(color: D.slate400, fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        Builder(builder: (context) {
                          final canWrite = context.read<AuthBloc>().state is AuthAuthenticated &&
                              (context.read<AuthBloc>().state as AuthAuthenticated).user.canWrite('faqs');
                          return Row(
                            children: [
                              Text('Estado:', style: TextStyle(color: D.slate600, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (canWrite)
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: widget.faq.isActive,
                                    activeColor: D.emerald,
                                    onChanged: (v) => context.read<FaqBloc>().add(ToggleFaqActive(widget.faq.id)),
                                  ),
                                ),
                              const Spacer(),
                              if (canWrite) ...[
                                _ActionBtn(
                                  icon: Icons.edit_rounded,
                                  color: D.skyBlue,
                                  onTap: () => Navigator.pushNamed(context, AppRouter.faqEdit, arguments: widget.faq),
                                ),
                                const SizedBox(width: 12),
                                _ActionBtn(
                                  icon: Icons.delete_outline_rounded,
                                  color: D.rose,
                                  onTap: widget.onDelete,
                                ),
                              ],
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 18),
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
    const spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1, paint);
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
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: D.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
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
          Icon(Icons.help_center_outlined, size: 80, color: D.slate600),
          const SizedBox(height: 24),
          Text(
            query.isEmpty ? 'No hay preguntas frecuentes' : 'No se encontraron resultados',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty 
              ? 'Comienza agregando una nueva pregunta' 
              : 'Prueba con términos más generales',
            style: TextStyle(color: D.slate400, fontSize: 14),
          ),
        ],
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
          onPressed: () => context.read<FaqBloc>().add(LoadFaqs()),
          child: const Text('Reintentar', style: TextStyle(color: D.skyBlue)),
        ),
      ],
    );
  }
}

class _PremiumConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;

  const _PremiumConfirmDialog({required this.title, required this.content, required this.onConfirm});

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
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(content, textAlign: TextAlign.center, style: TextStyle(color: D.slate400, fontSize: 14)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: D.slate400, fontWeight: FontWeight.w600)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
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
