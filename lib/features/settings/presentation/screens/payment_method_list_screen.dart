import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../config/app_router.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_method_bloc.dart';

class PaymentMethodListScreen extends StatelessWidget {
  const PaymentMethodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentMethodBloc>()..add(LoadPaymentMethods()),
      child: const Scaffold(body: _PaymentMethodListBody()),
    );
  }
}

class _PaymentMethodListBody extends StatefulWidget {
  const _PaymentMethodListBody();

  @override
  State<_PaymentMethodListBody> createState() => _PaymentMethodListBodyState();
}

class _PaymentMethodListBodyState extends State<_PaymentMethodListBody> {
  IconData _bankIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nequi') || lower.contains('daviplata')) {
      return Icons.phone_android_rounded;
    }
    return Icons.account_balance_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite =
        authState is AuthAuthenticated &&
        authState.user.canWrite('paymentMethods');

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<PaymentMethodBloc, PaymentMethodState>(
        builder: (context, state) {
          List<PaymentMethod> list = [];
          if (state is PaymentMethodsLoaded) {
            list = state.methods;
          } else if (state is PaymentMethodSaving && state.methods != null)
            list = state.methods!;

          final isLoading = state is PaymentMethodLoading && list.isEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<PaymentMethodBloc>().add(LoadPaymentMethods()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PaymentHeader(canWrite: canWrite),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 180,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SaasListSkeleton(),
                        childCount: 4,
                      ),
                    ),
                  )
                else if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: const SaasEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Sin métodos de pago',
                      subtitle:
                          'Comienza agregando un banco o cuenta Nequi para recibir pagos.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            mainAxisExtent: 185,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final method = list[index];
                        return _PaymentMethodCard(
                          method: method,
                          canWrite: canWrite,
                          icon: _bankIcon(method.name),
                          onEdit: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              AppRouter.paymentMethodForm,
                              arguments: method,
                            );
                            if (result == true && context.mounted) {
                              context.read<PaymentMethodBloc>().add(
                                LoadPaymentMethods(),
                              );
                            }
                          },
                          onDelete: () => _confirmDelete(context, method),
                          onToggle: () => context.read<PaymentMethodBloc>().add(
                            TogglePaymentMethodActive(method.id),
                          ),
                        );
                      }, childCount: list.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar Método?',
        body: 'La cuenta de "${method.name}" será removida permanentemente.',
        onConfirm: () {
          context.read<PaymentMethodBloc>().add(DeletePaymentMethod(method.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentHeader extends StatelessWidget {
  final bool canWrite;
  const _PaymentHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Configuración', 'Pagos']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Métodos de Pago',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestiona cuentas bancarias y canales de cobro oficiales.',
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
                label: 'Nuevo Método',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRouter.paymentMethodForm,
                  );
                  if (result == true && context.mounted) {
                    context.read<PaymentMethodBloc>().add(LoadPaymentMethods());
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAYMENT METHOD CARD
// ─────────────────────────────────────────────────────────────────────────────
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover ? SaasPalette.brand600 : SaasPalette.border,
            width: _hover ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.08 : 0.03),
              blurRadius: _hover ? 16 : 8,
              offset: Offset(0, _hover ? 4 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? SaasPalette.brand50
                            : SaasPalette.bgSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isActive
                            ? SaasPalette.brand600
                            : SaasPalette.textTertiary,
                        size: 24,
                      ),
                    ),
                    if (widget.canWrite)
                      _CardActions(
                        isActive: isActive,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
                        onToggle: widget.onToggle,
                      )
                    else
                      const Icon(
                        Icons.visibility_outlined,
                        color: SaasPalette.textTertiary,
                        size: 20,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  m.name,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  m.paymentType,
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.accountNumber,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SaasStatusBadge(active: isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  m.accountHolder.toUpperCase(),
                  style: const TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
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

  const _CardActions({
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: SaasPalette.textTertiary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: SaasPalette.bgCanvas,
      elevation: 4,
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
        if (v == 'toggle') onToggle();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: SaasPalette.textPrimary,
              ),
              SizedBox(width: 12),
              Text(
                'Editar cuenta',
                style: TextStyle(color: SaasPalette.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: isActive ? SaasPalette.warning : SaasPalette.success,
              ),
              const SizedBox(width: 12),
              Text(
                isActive ? 'Desactivar' : 'Activar',
                style: TextStyle(
                  color: isActive ? SaasPalette.warning : SaasPalette.success,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: SaasPalette.danger,
              ),
              SizedBox(width: 12),
              Text(
                'Eliminar',
                style: TextStyle(color: SaasPalette.danger, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
