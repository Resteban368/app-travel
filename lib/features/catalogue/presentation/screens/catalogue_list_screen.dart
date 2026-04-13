import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/catalogue.dart';
import '../bloc/catalogue_bloc.dart';
import '../bloc/catalogue_event.dart';
import '../bloc/catalogue_state.dart';
import '../../../../core/theme/premium_palette.dart';



class CatalogueListScreen extends StatelessWidget {
  const CatalogueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 4, child: _CatalogueListBody());
  }
}

class _CatalogueListBody extends StatefulWidget {
  const _CatalogueListBody();

  @override
  State<_CatalogueListBody> createState() => _CatalogueListBodyState();
}

class _CatalogueListBodyState extends State<_CatalogueListBody>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

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
    context.read<CatalogueBloc>().add(LoadCatalogues());

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat(reverse: true);

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOutCubic)));
    _listOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    _floatY = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated && authState.user.canWrite('catalogues');

    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(
        children: [
          // Background animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatCtrl, _shimmerCtrl]),
              builder: (_, __) => _CatalogueBackground(
                shimmer: _shimmer.value,
                floatY: _floatY.value,
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: BlocBuilder<CatalogueBloc, CatalogueState>(
              builder: (context, state) {
                List<Catalogue> list = [];
                if (state is CatalogueLoaded) list = state.catalogues;
                else if (state is CatalogueSaving && state.catalogues != null) list = state.catalogues!;

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  list = list.where((c) => c.nombreCatalogue.toLowerCase().contains(q)).toList();
                }

                return RefreshIndicator(
                  onRefresh: () async => context.read<CatalogueBloc>().add(LoadCatalogues()),
                  color: D.skyBlue,
                  backgroundColor: D.surface,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _headerOpacity,
                            child: SlideTransition(
                              position: _headerSlide,
                              child: _HeaderSection(canWrite: canWrite),
                            ),
                          ),
                        ),
                      ),

                      // Buscador
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _headerOpacity,
                            child: _PremiumSearch(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              onClear: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Lista
                      if (state is CatalogueLoading && list.isEmpty)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: D.skyBlue)))
                      else if (list.isEmpty)
                        const SliverFillRemaining(child: _EmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final cat = list[index];
                                return FadeTransition(
                                  opacity: _listOpacity,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CatalogueCard(
                                      catalogue: cat,
                                      canWrite: canWrite,
                                      onEdit: () => Navigator.pushNamed(context, AppRouter.catalogueEdit, arguments: cat),
                                      onDelete: () => _confirmDelete(cat),
                                      onStatusChanged: (v) {
                                        context.read<CatalogueBloc>().add(UpdateCatalogue(cat.copyWith(activo: v)));
                                      },
                                    ),
                                  ),
                                );
                              },
                              childCount: list.length,
                            ),
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

  void _confirmDelete(Catalogue cat) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Catálogo?',
        content: 'Esta acción no se puede deshacer. ¿Deseas eliminar "${cat.nombreCatalogue}"?',
        onConfirm: () {
          context.read<CatalogueBloc>().add(DeleteCatalogue(cat.idCatalogue));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── COMPONENTES ─────────────────────────────────────────────────────────────

class _CatalogueBackground extends StatelessWidget {
  final double shimmer;
  final double floatY;
  const _CatalogueBackground({required this.shimmer, required this.floatY});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [D.bg, Color(0xFF091428), Color(0xFF050A14)],
            ),
          ),
        ),
        Positioned(
          top: -40 + floatY,
          left: -40,
          child: _orb(280, D.royalBlue.withOpacity(0.12 + shimmer * 0.05)),
        ),
        Positioned(
          bottom: 100 - floatY * 0.5,
          right: -60,
          child: _orb(320, D.cyan.withOpacity(0.08)),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1A2E45).withOpacity(0.5)
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

class _HeaderSection extends StatelessWidget {
  final bool canWrite;
  const _HeaderSection({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [D.royalBlue, D.indigo]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text('BIBLIOTECA DIGITAL',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Catálogos',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            const SizedBox(height: 4),
            Text('Gestiona tus guías y PDFs informativos.', style: TextStyle(color: D.slate400, fontSize: 13)),
          ],
        ),
        if (canWrite)
          _AddBtn(onTap: () => Navigator.pushNamed(context, AppRouter.catalogueCreate)),
      ],
    );
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: D.royalBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _PremiumSearch extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _PremiumSearch({required this.controller, required this.onChanged, required this.onClear});

  @override
  State<_PremiumSearch> createState() => _PremiumSearchState();
}

class _PremiumSearchState extends State<_PremiumSearch> {
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
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _focused ? D.skyBlue.withOpacity(0.5) : D.border, width: _focused ? 1.5 : 1),
        boxShadow: _focused ? [BoxShadow(color: D.skyBlue.withOpacity(0.08), blurRadius: 12)] : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _node,
        onChanged: widget.onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar catálogos...',
          hintStyle: const TextStyle(color: D.slate600),
          prefixIcon: Icon(Icons.search_rounded, color: _focused ? D.skyBlue : D.slate600, size: 20),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, color: D.slate400, size: 18), onPressed: widget.onClear)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

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
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.catalogue;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hover ? D.surfaceHigh : D.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hover ? D.royalBlue.withOpacity(0.4) : D.border),
          boxShadow: _hover ? [BoxShadow(color: D.royalBlue.withOpacity(0.1), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            // Thumbnail / Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: cat.activo ? [D.royalBlue, D.cyan] : [D.slate600, D.border],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.nombreCatalogue,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: D.slate600, size: 11),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd MMM yyyy').format(cat.fechaCreacion),
                          style: TextStyle(color: D.slate600, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (widget.canWrite) ...[
              Switch(
                value: cat.activo,
                onChanged: widget.onStatusChanged,
                activeColor: D.emerald,
                activeTrackColor: D.emerald.withOpacity(0.2),
              ),
              IconButton(icon: const Icon(Icons.edit_rounded, color: D.slate400, size: 20), onPressed: widget.onEdit),
              IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: D.rose, size: 20), onPressed: widget.onDelete),
            ] else
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: D.slate400, size: 20),
                onPressed: widget.onEdit,
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined, size: 64, color: D.slate600.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No hay catálogos disponibles', style: TextStyle(color: D.slate400, fontSize: 16)),
        ],
      ),
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
        decoration: BoxDecoration(color: D.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: D.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: D.gold, size: 48),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(content, textAlign: TextAlign.center, style: TextStyle(color: D.slate400, fontSize: 14)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: D.slate400)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(backgroundColor: D.rose, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Eliminar'),
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

