import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_method_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

class PaymentMethodFormScreen extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  const PaymentMethodFormScreen({super.key, this.paymentMethod});

  @override
  State<PaymentMethodFormScreen> createState() =>
      _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState extends State<PaymentMethodFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _accountHolderCtrl;
  String _accountType = 'Ahorro';
  String _paymentType = 'Transferencia';
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.paymentMethod != null;
  static const _accountTypes = ['Ahorro', 'Corriente', 'Llave'];
  static const _paymentTypes = [
    'Transferencia',
    'Efectivo',
    'Datáfono / Bold',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final pm = widget.paymentMethod;
    _bankCtrl = TextEditingController(text: pm?.name ?? '');
    _accountNumberCtrl = TextEditingController(text: pm?.accountNumber ?? '');
    _accountHolderCtrl = TextEditingController(text: pm?.accountHolder ?? '');
    _paymentType = pm?.paymentType ?? 'Transferencia';
    if (pm != null) {
      _accountType = pm.accountType;
      _isActive = pm.isActive;
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bankCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final method = PaymentMethod(
      id: _isEditing ? widget.paymentMethod!.id : 0,
      name: _bankCtrl.text.trim(),
      paymentType: _paymentType,
      accountType: _accountType,
      accountNumber: _accountNumberCtrl.text.trim(),
      accountHolder: _accountHolderCtrl.text.trim(),
      isActive: _isActive,
      createdAt: _isEditing ? widget.paymentMethod!.createdAt : DateTime.now(),
    );

    if (_isEditing) {
      context.read<PaymentMethodBloc>().add(UpdatePaymentMethod(method));
    } else {
      context.read<PaymentMethodBloc>().add(CreatePaymentMethod(method));
    }
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? D.rose : D.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('paymentMethods')
        : true;

    return BlocListener<PaymentMethodBloc, PaymentMethodState>(
      listener: (context, state) {
        if (state is PaymentMethodSaved) {
          _showToast(
            context,
            _isEditing ? 'Método actualizado' : 'Método creado',
          );
          Navigator.pop(context, true);
        } else if (state is PaymentMethodError) {
          _showToast(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            const PremiumBackground(),
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing && !canWrite
                      ? 'Ver Cuenta'
                      : (_isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
                  actions: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Etiqueta de seguridad reforzada
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: D.emerald.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: D.emerald.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.security_rounded,
                                          color: D.emerald,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Información Financiera Segura',
                                          style: TextStyle(
                                            color: D.emerald,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  PremiumSectionCard(
                                    title: 'DATOS DE LA CUENTA',
                                    icon: Icons.account_balance_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _bankCtrl,
                                        label: 'Nombre del Banco / Entidad *',
                                        icon: Icons.account_balance_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDropdown(
                                              value: _paymentType,
                                              label: 'Tipo de Pago',
                                              icon: Icons.payments_rounded,
                                              items: _paymentTypes,
                                              onChanged: canWrite
                                                  ? (v) => setState(
                                                      () => _paymentType = v!,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: _buildDropdown(
                                              value: _accountType,
                                              label: 'Tipo de Cuenta',
                                              icon: Icons.credit_card_rounded,
                                              items: _accountTypes,
                                              onChanged: canWrite
                                                  ? (v) => setState(
                                                      () => _accountType = v!,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _accountNumberCtrl,
                                        label: 'Número de Cuenta o Teléfono *',
                                        icon: Icons.numbers_rounded,
                                        // isNumeric: true,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _accountHolderCtrl,
                                        label: 'Titular de la Cuenta *',
                                        icon: Icons.person_outline_rounded,
                                        readOnly: !canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  PremiumSectionCard(
                                    title: 'VISIBILIDAD',
                                    icon: Icons.toggle_on_rounded,
                                    children: [
                                      _buildVisibilitySwitch(
                                        canWrite: canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 48),

                                  if (canWrite)
                                    Builder(
                                      builder: (ctx) =>
                                          BlocBuilder<
                                            PaymentMethodBloc,
                                            PaymentMethodState
                                          >(
                                            builder: (context, state) {
                                              return PremiumActionButton(
                                                label: _isEditing
                                                    ? 'ACTUALIZAR MÉTODO'
                                                    : 'GUARDAR MÉTODO',
                                                icon: Icons.save_rounded,
                                                isLoading:
                                                    state
                                                        is PaymentMethodSaving,
                                                onTap: () => _save(ctx),
                                              );
                                            },
                                          ),
                                    ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: D.slate400,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (onChanged == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: D.surfaceHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(icon, color: D.skyBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            dropdownColor: D.surfaceHigh,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: D.skyBlue, size: 20),
              filled: true,
              fillColor: D.surfaceHigh.withOpacity(0.5),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: D.skyBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: items
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: onChanged,
          ),
      ],
    );
  }

  Widget _buildVisibilitySwitch({required bool canWrite}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: SwitchListTile(
            title: const Text(
              'Estado de la Cuenta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isActive ? 'Activa para cobros' : 'Inactiva temporalmente',
              style: const TextStyle(color: D.slate400, fontSize: 12),
            ),
            value: _isActive,
            activeColor: D.emerald,
            activeTrackColor: D.emerald.withOpacity(0.3),
            inactiveThumbColor: D.slate400,
            inactiveTrackColor: D.bg.withOpacity(0.5),
            onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
          ),
        ),
      ),
    );
  }
}
