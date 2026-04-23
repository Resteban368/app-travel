import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/cliente.dart';
import '../bloc/cliente_bloc.dart';
import '../bloc/cliente_event.dart';
import '../bloc/cliente_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ClienteListScreen extends StatefulWidget {
  const ClienteListScreen({super.key});

  @override
  State<ClienteListScreen> createState() => _ClienteListScreenState();
}

class _ClienteListScreenState extends State<ClienteListScreen>
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

    context.read<ClienteBloc>().add(LoadClientes());
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
      currentIndex: 13,
      child: Scaffold(
        body: Stack(
          children: [
            BlocConsumer<ClienteBloc, ClienteState>(
              listener: (context, state) {
                if (state is ClienteError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: D.rose,
                    ),
                  );
                } else if (state is ClienteActionSuccess) {
                  context.read<ClienteBloc>().add(LoadClientes());
                }
              },
              builder: (context, state) {
                final authState = context.watch<AuthBloc>().state;
                final canWrite =
                    authState is AuthAuthenticated &&
                    authState.user.canWrite('clientes');

                List<Cliente>? clientes;
                if (state is ClienteLoaded) {
                  clientes = state.clientes;
                } else if (state is ClienteSaving && state.clientes != null) {
                  clientes = state.clientes;
                } else if (state is ClienteActionSuccess) {
                  clientes = state.clientes;
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                      child: FadeTransition(
                        opacity: _headerOpacity,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: _buildHeader(context, canWrite),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 10),
                      child: SaasSearchField(
                        controller: _searchCtrl,
                        hintText: 'Buscar clientes',
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onClear: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverFadeTransition(
                            opacity: _contentOpacity,
                            sliver: _buildContent(
                              context,
                              state,
                              clientes,
                              canWrite,
                            ),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 100),
                          ),
                        ],
                      ),
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Operaciones', 'Clientes']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gestión de Clientes',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administra la información y el historial de tus clientes.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite)
              SaasButton(
                label: 'Nuevo Cliente',
                icon: Icons.add_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.clienteCreate),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClienteState state,
    List<Cliente>? clientes,
    bool canWrite,
  ) {
    if (state is ClienteLoading && clientes == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _SkelCard(),
          childCount: 5,
        ),
      );
    }

    if (clientes == null || clientes.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState());
    }

    final filtered = clientes.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.nombre.toLowerCase().contains(q) ||
          c.correo.toLowerCase().contains(q) ||
          c.telefono.toLowerCase().contains(q) ||
          c.documento.toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState(isSearch: true));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final cliente = filtered[index];
          return _ClienteCard(
            cliente: cliente,
            state: state,
            canWrite: canWrite,
          );
        }, childCount: filtered.length),
      ),
    );
  }
}

class _ClienteCard extends StatefulWidget {
  final Cliente cliente;
  final ClienteState state;
  final bool canWrite;
  const _ClienteCard({
    required this.cliente,
    required this.state,
    required this.canWrite,
  });

  @override
  State<_ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends State<_ClienteCard> {
  bool _hovered = false;

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Cliente?',
        content:
            'Esta acción borrará a "${widget.cliente.nombre}" permanentemente.',
        onConfirm: () {
          context.read<ClienteBloc>().add(DeleteCliente(widget.cliente.id!));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? SaasPalette.brand600 : SaasPalette.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.08 : 0.03),
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 4 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.canWrite
              ? () => Navigator.pushNamed(
                  context,
                  AppRouter.clienteEdit,
                  arguments: widget.cliente,
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: D.royalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: D.royalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nombre,
                        style: const TextStyle(
                          color: D.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.correo,
                        style: TextStyle(color: D.slate400, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: D.bg),
                          const SizedBox(width: 4),
                          Text(
                            c.telefono,
                            style: TextStyle(color: D.surface, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 12, color: D.bg),
                          const SizedBox(width: 4),
                          Text(
                            '${c.tipoDocumento}: ${c.documento}',
                            style: TextStyle(color: D.surface, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.canWrite) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final isSaving = widget.state is ClienteSaving;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: D.skyBlue, size: 20),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.clienteEdit,
            arguments: widget.cliente,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: D.rose,
            size: 20,
          ),
          onPressed: isSaving ? null : _confirmDelete,
        ),
      ],
    );
  }
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

class _SkelCard extends StatefulWidget {
  @override
  State<_SkelCard> createState() => _SkelCardState();
}

class _SkelCardState extends State<_SkelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: D.border.withOpacity(0.5)),
          gradient: LinearGradient(
            begin: Alignment(-2.0 + (_anim.value * 4), -0.5),
            end: Alignment(-1.0 + (_anim.value * 4), 0.5),
            colors: [
              D.surface.withOpacity(0.3),
              D.surface.withOpacity(0.8),
              D.surface.withOpacity(0.3),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: D.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: D.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: D.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: D.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
          size: 64,
          color: D.slate800,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch ? 'No se encontraron clientes' : 'Sin clientes registrados',
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
