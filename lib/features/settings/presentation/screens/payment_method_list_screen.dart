import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_method_bloc.dart';
import '../../../../core/theme/premium_palette.dart';



class PaymentMethodListScreen extends StatelessWidget {
  const PaymentMethodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentMethodBloc>()..add(LoadPaymentMethods()),
      child: const AdminShell(currentIndex: 3, child: _PaymentMethodListBody()),
    );
  }
}

class _PaymentMethodListBody extends StatefulWidget {
  const _PaymentMethodListBody();

  @override
  State<_PaymentMethodListBody> createState() => _PaymentMethodListBodyState();
}

class _PaymentMethodListBodyState extends State<_PaymentMethodListBody>
    with TickerProviderStateMixin {
  
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _gridOpacity;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOutCubic)));
    _gridOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    
    _floatY = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  IconData _bankIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nequi') || lower.contains('daviplata')) return Icons.phone_android_rounded;
    return Icons.account_balance_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated && authState.user.canWrite('paymentMethods');

    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(
        children: [
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, __) => _PremiumBackground(floatY: _floatY.value),
            ),
          ),

          SafeArea(
            child: BlocBuilder<PaymentMethodBloc, PaymentMethodState>(
              builder: (context, state) {
                List<PaymentMethod> list = [];
                if (state is PaymentMethodsLoaded) list = state.methods;
                else if (state is PaymentMethodSaving && state.methods != null) list = state.methods!;

                return RefreshIndicator(
                  onRefresh: () async => context.read<PaymentMethodBloc>().add(LoadPaymentMethods()),
                  color: D.skyBlue,
                  backgroundColor: D.surface,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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

                      // Grid de Métodos
                      if (state is PaymentMethodLoading && list.isEmpty)
                        const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: D.skyBlue)))
                      else if (list.isEmpty)
                        const SliverFillRemaining(child: _EmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 450,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              mainAxisExtent: 200,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final method = list[index];
                                return FadeTransition(
                                  opacity: _gridOpacity,
                                  child: _PaymentMethodCard(
                                    method: method,
                                    canWrite: canWrite,
                                    icon: _bankIcon(method.name),
                                    onEdit: () async {
                                      final result = await Navigator.pushNamed(context, AppRouter.paymentMethodForm, arguments: method);
                                      if (result == true && context.mounted) {
                                        context.read<PaymentMethodBloc>().add(LoadPaymentMethods());
                                      }
                                    },
                                    onDelete: () => _confirmDelete(context, method),
                                    onToggle: () => context.read<PaymentMethodBloc>().add(TogglePaymentMethodActive(method.id)),
                                  ),
                                );
                              },
                              childCount: list.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 50)),
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

  void _confirmDelete(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Método?',
        content: 'La cuenta de "${method.name}" será removida permanentemente.',
        onConfirm: () {
          context.read<PaymentMethodBloc>().add(DeletePaymentMethod(method.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── COMPONENTES ─────────────────────────────────────────────────────────────

class _PremiumBackground extends StatelessWidget {
  final double floatY;
  const _PremiumBackground({required this.floatY});

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
          top: -20 + floatY,
          right: -50,
          child: _orb(350, D.royalBlue.withOpacity(0.1)),
        ),
        Positioned(
          bottom: 20 - floatY,
          left: -40,
          child: _orb(280, D.cyan.withOpacity(0.08)),
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
                gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text('ADMINISTRACIÓN FINANCIERA',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Métodos de Pago',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            const SizedBox(height: 4),
            Text('Gestiona cuentas bancarias y canales de cobro.', style: TextStyle(color: D.slate400, fontSize: 13)),
          ],
        ),
        if (canWrite)
          _AddBtn(onTap: () async {
            final result = await Navigator.pushNamed(context, AppRouter.paymentMethodForm);
            if (result == true && context.mounted) {
              context.read<PaymentMethodBloc>().add(LoadPaymentMethods());
            }
          }),
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
          gradient: const LinearGradient(colors: [D.royalBlue, D.indigo]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: D.royalBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _PaymentMethodCard extends StatefulWidget {
  final PaymentMethod method;
  final bool canWrite;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _PaymentMethodCard({
    required this.method,
    required this.canWrite,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.method;
    final isActive = m.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hover ? D.surfaceHigh : D.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _hover ? D.skyBlue.withOpacity(0.4) : D.border, width: 1.5),
          boxShadow: _hover ? [BoxShadow(color: D.skyBlue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))] : [],
        ),
        child: Stack(
          children: [
            // Marca de agua de banco
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(widget.icon, size: 100, color: Colors.white.withAlpha(8)),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: D.royalBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: D.skyBlue, size: 24),
                    ),
                    if (widget.canWrite)
                      _CardActions(
                        isActive: isActive,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                        onToggle: widget.onToggle,
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: D.slate400, size: 20),
                        onPressed: widget.onEdit,
                      ),
                  ],
                ),
                const Spacer(),
                Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(m.paymentType, style: TextStyle(color: D.slate600, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(m.accountNumber,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    if (!isActive) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: D.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('INACTIVO', style: TextStyle(color: D.rose, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(m.accountHolder.toUpperCase(),
                    style: TextStyle(color: D.slate400, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _CardActions({required this.isActive, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: D.slate400),
      color: D.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: D.border)),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
        if (v == 'toggle') onToggle();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: D.slate400),
              const SizedBox(width: 8),
              Text(isActive ? 'Desactivar' : 'Activar', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: D.slate400),
              const SizedBox(width: 8),
              Text('Editar', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: D.rose),
              const SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: D.rose, fontSize: 13)),
            ],
          ),
        ),
      ],
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
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: D.slate600.withOpacity(0.4)),
          const SizedBox(height: 24),
          Text('No hay métodos registrados', style: TextStyle(color: D.slate400, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Comienza agregando un banco o cuenta Nequi.', style: TextStyle(color: D.slate600, fontSize: 13)),
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
        decoration: BoxDecoration(color: D.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: D.border)),
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
