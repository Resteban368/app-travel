import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/info_empresa.dart';
import '../bloc/info_empresa_bloc.dart';
import '../bloc/info_empresa_state.dart';

class InfoEmpresaListScreen extends StatefulWidget {
  const InfoEmpresaListScreen({super.key});

  @override
  State<InfoEmpresaListScreen> createState() => _InfoEmpresaListScreenState();
}

class _InfoEmpresaListScreenState extends State<InfoEmpresaListScreen>
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
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated && authState.user.canWrite('infoEmpresa');

    return AdminShell(
      currentIndex: 8,
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

            BlocConsumer<InfoEmpresaBloc, InfoEmpresaState>(
              listener: (context, state) {
                if (state is InfoSynced) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vectores sincronizados correctamente'), backgroundColor: D.emerald),
                  );
                }
                if (state is InfoError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: D.rose),
                  );
                }
              },
              builder: (context, state) {
                List<InfoEmpresa>? infoList;
                if (state is InfoLoaded) infoList = state.infoList;
                if (state is InfoSaved) infoList = state.infoList;
                if (state is InfoSynced) infoList = state.infoList;
                if (state is InfoSyncing) infoList = state.infoList;
                if (state is InfoSaving && state.infoList != null) {
                  infoList = state.infoList;
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
                            child: _buildHeader(
                                context, infoList, canWrite, state),
                          ),
                        ),
                      ),
                    ),
                    _buildFilters(),
                    SliverFadeTransition(
                      opacity: _contentOpacity,
                      sliver: _buildContent(context, state, infoList),
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

  Widget _buildHeader(BuildContext context, List<InfoEmpresa>? infoList,
      bool canWrite, InfoEmpresaState state) {
    final showBtn =
        canWrite && (infoList == null || infoList.isEmpty) && state is! InfoLoading;

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
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PERFIL CORPORATIVO',
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
              'Información de Empresa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Datos corporativos y base de conocimiento RAG.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (showBtn)
          _AddBtn(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.infoEmpresaCreate),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
              color: D.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: D.border.withOpacity(0.5))),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar información...',
              hintStyle: TextStyle(color: D.slate600, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: D.slate600, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, InfoEmpresaState state, List<InfoEmpresa>? infoList) {
    if (state is InfoLoading) {
      return SliverList(delegate: SliverChildBuilderDelegate((_, i) => _SkelCard(), childCount: 2));
    }

    if (infoList == null || infoList.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState());
    }

    final filtered = infoList.where((i) => i.nombre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState(isSearch: true));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final info = filtered[index];
          return _InfoCard(info: info, state: state);
        }, childCount: filtered.length),
      ),
    );
  }
}

class _InfoCard extends StatefulWidget {
  final InfoEmpresa info;
  final InfoEmpresaState state;
  const _InfoCard({required this.info, required this.state});

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    final isBusy = widget.state is InfoSaving || widget.state is InfoSyncing;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _hovered ? D.royalBlue.withOpacity(0.5) : D.border, width: 1.5),
          boxShadow: _hovered ? [BoxShadow(color: D.royalBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))] : null,
        ),
        child: InkWell(
          onTap: isBusy ? null : () => Navigator.pushNamed(context, AppRouter.infoEmpresaEdit, arguments: i),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: D.royalBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.business_rounded, color: D.skyBlue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.nombre,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Gerente: ${i.nombreGerente}', style: TextStyle(color: D.slate400, fontSize: 13)),
                      ],
                    )),
                    const Icon(Icons.chevron_right_rounded, color: D.slate600),
                  ],
                ),
                const SizedBox(height: 20),
                Text(i.detalles,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: D.slate400, fontSize: 14, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _InfoBadge(icon: Icons.alternate_email_rounded, label: i.correo),
                    const SizedBox(width: 16),
                    _InfoBadge(icon: Icons.phone_android_rounded, label: i.telefono),
                  ],
                ),
                if (isBusy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(backgroundColor: D.border, valueColor: AlwaysStoppedAnimation(D.skyBlue)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: D.slate600, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: D.slate600, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
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
      height: 180,
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(color: D.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(22)));
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({this.isSearch = false});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isSearch ? Icons.search_off_rounded : Icons.business_rounded, size: 64, color: D.slate800),
        const SizedBox(height: 16),
        Text(isSearch ? 'No se encontró información que coincida' : 'Sin información corporativa registrada',
            style: TextStyle(color: D.slate600, fontSize: 16, fontWeight: FontWeight.bold))
      ]));
}
