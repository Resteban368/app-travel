import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_method_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';



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

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
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

  void _save() {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          _showToast(context, _isEditing ? 'Método actualizado' : 'Método creado');
          Navigator.pop(context, true);
        } else if (state is PaymentMethodError) {
          _showToast(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditing && !canWrite ? 'Ver Cuenta' : (_isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            Positioned(top: -100, right: -50, child: _orb(250, D.indigo.withOpacity(0.1))),
            Positioned(bottom: -50, left: -50, child: _orb(200, D.royalBlue.withOpacity(0.08))),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: D.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: D.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.security_rounded, color: D.emerald, size: 16),
                                const SizedBox(width: 8),
                                Text('Información Financiera Segura', style: TextStyle(color: D.slate400, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: D.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: D.border),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _bankCtrl,
                                  label: 'Nombre del Banco / Entidad',
                                  icon: Icons.account_balance_rounded,
                                  hint: 'Ej: Bancolombia, Nequi, etc.',
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                _buildDropdown(
                                  value: _paymentType,
                                  label: 'Tipo de Pago',
                                  icon: Icons.payments_rounded,
                                  items: ['Transferencia', 'Efectivo', 'Datáfono / Bold', 'Otro'],
                                  onChanged: canWrite ? (v) => setState(() => _paymentType = v!) : null,
                                ),
                                const SizedBox(height: 20),
                                _buildDropdown(
                                  value: _accountType,
                                  label: 'Tipo de Cuenta',
                                  icon: Icons.credit_card_rounded,
                                  items: _accountTypes,
                                  onChanged: canWrite ? (v) => setState(() => _accountType = v!) : null,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _accountNumberCtrl,
                                  label: 'Número de Cuenta o Teléfono',
                                  icon: Icons.numbers_rounded,
                                  hint: 'Ej: 300 123 4567 o No. Cuenta',
                                  keyboardType: TextInputType.number,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _accountHolderCtrl,
                                  label: 'Titular de la Cuenta',
                                  icon: Icons.person_outline_rounded,
                                  hint: 'Nombre completo del titular',
                                  textCapitalization: TextCapitalization.words,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: D.surfaceHigh.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: D.border),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Estado de la Cuenta', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: Text(_isActive ? 'Activa para cobros' : 'Inactiva temporalmente', style: TextStyle(color: D.slate600, fontSize: 12)),
                                    value: _isActive,
                                    activeColor: D.emerald,
                                    activeTrackColor: D.emerald.withOpacity(0.2),
                                    onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          if (canWrite)
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: BlocBuilder<PaymentMethodBloc, PaymentMethodState>(
                              builder: (context, state) {
                                final isSaving = state is PaymentMethodSaving;
                                return ElevatedButton(
                                  onPressed: isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: D.royalBlue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: D.slate600.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    elevation: 8,
                                    shadowColor: D.royalBlue.withOpacity(0.4),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(_isEditing ? 'Actualizar Método' : 'Guardar Método', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: D.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: D.slate600, fontSize: 14),
            prefixIcon: Icon(icon, color: D.skyBlue, size: 20),
            filled: true,
            fillColor: D.surfaceHigh.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.skyBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.rose)),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: D.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor: D.surfaceHigh,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: D.skyBlue, size: 20),
            filled: true,
            fillColor: D.surfaceHigh.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.skyBlue, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
      );
}
