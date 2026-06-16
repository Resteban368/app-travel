import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/phone_form_field.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/proveedor.dart';
import '../bloc/proveedor_bloc.dart';
import '../bloc/proveedor_event.dart';
import '../bloc/proveedor_state.dart';

const _kTipos = [
  'hotel',
  'aerolinea',
  'seguro',
  'transporte',
  'restaurante',
  'agencia',
  'crucero',
  'tours_operador',
  'visa',
  'pasaporte',
  'transfer',
  'guia_turismo',
  'parque_atraccion',
  'alquiler_vehiculo',
  'otro',
];

const _kTipoLabels = {
  'hotel': 'Hotel',
  'aerolinea': 'Aerolínea',
  'seguro': 'Seguro',
  'transporte': 'Transporte',
  'restaurante': 'Restaurante',
  'agencia': 'Agencia de viajes',
  'crucero': 'Crucero',
  'tours_operador': 'Tour operador',
  'visa': 'Visa / Trámites',
  'pasaporte': 'Pasaporte',
  'transfer': 'Transfer',
  'guia_turismo': 'Guía de turismo',
  'parque_atraccion': 'Parque / Atracción',
  'alquiler_vehiculo': 'Alquiler de vehículo',
  'otro': 'Otro',
};

class ProveedorFormScreen extends StatefulWidget {
  final Proveedor? proveedor;
  const ProveedorFormScreen({super.key, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _telefonoCtrl;
  String _countryCode = '+57';
  late final TextEditingController _emailCtrl;
  late final TextEditingController _bancoCtrl;
  late final TextEditingController _numeroCuentaCtrl;
  late final TextEditingController _notasCtrl;
  late String _tipo;
  late bool _isActive;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _nitCtrl = TextEditingController(text: p?.nit ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _bancoCtrl = TextEditingController(text: p?.banco ?? '');
    _numeroCuentaCtrl = TextEditingController(text: p?.numeroCuenta ?? '');
    _notasCtrl = TextEditingController(text: p?.notas ?? '');
    _tipo = p?.tipo ?? 'hotel';
    _isActive = p?.isActive ?? true;

    final rawPhone = p?.telefono ?? '';
    if (rawPhone.isNotEmpty) {
      final parsed = parsePhone(rawPhone);
      _countryCode = parsed.$1;
      _telefonoCtrl = TextEditingController(text: parsed.$2);
    } else {
      _telefonoCtrl = TextEditingController();
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nombreCtrl.dispose();
    _nitCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _bancoCtrl.dispose();
    _numeroCuentaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    if (_nombreCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'Debe ingresar el nombre del proveedor');
      return;
    }

    final proveedor = Proveedor(
      id: widget.proveedor?.id,
      nombre: _nombreCtrl.text.trim(),
      tipo: _tipo,
      nit: _nitCtrl.text.trim().isEmpty ? null : _nitCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim().isEmpty
          ? null
          : '$_countryCode${_telefonoCtrl.text.trim()}',
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      banco: _bancoCtrl.text.trim().isEmpty ? null : _bancoCtrl.text.trim(),
      numeroCuenta: _numeroCuentaCtrl.text.trim().isEmpty
          ? null
          : _numeroCuentaCtrl.text.trim(),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      isActive: _isActive,
    );

    if (_isEditing) {
      context.read<ProveedorBloc>().add(UpdateProveedor(proveedor));
    } else {
      context.read<ProveedorBloc>().add(CreateProveedor(proveedor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('proveedores')
        : true;

    return BlocListener<ProveedorBloc, ProveedorState>(
      listener: (context, state) {
        if (state is ProveedorSaved) {
          SaasSnackBar.showSuccess(
            context,
            _isEditing ? 'Proveedor actualizado' : 'Proveedor creado',
          );
          Navigator.pop(context);
        } else if (state is ProveedorError) {
          SaasSnackBar.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            PremiumSliverAppBar(
              title: _isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
              actions: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Etiqueta de sección
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: SaasPalette.brand50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: SaasPalette.brand600.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    color: SaasPalette.brand600,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'DATOS DEL PROVEEDOR',
                                    style: TextStyle(
                                      color: SaasPalette.brand600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Sección: Información del proveedor ──────────
                            PremiumSectionCard(
                              title: 'INFORMACIÓN DEL PROVEEDOR',
                              icon: Icons.business_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _nombreCtrl,
                                  label: 'Nombre *',
                                  icon: Icons.business_rounded,
                                  readOnly: !canWrite,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'El nombre es requerido'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _buildTipoDropdown(canWrite: canWrite),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _nitCtrl,
                                  label: 'NIT (opcional)',
                                  icon: Icons.badge_outlined,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                PhoneFormField(
                                  controller: _telefonoCtrl,
                                  countryCode: _countryCode,
                                  onCountryCodeChanged: (v) =>
                                      setState(() => _countryCode = v),
                                  label: 'Teléfono (opcional)',
                                  required: false,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _emailCtrl,
                                  label: 'Correo electrónico (opcional)',
                                  icon: Icons.email_rounded,
                                  readOnly: !canWrite,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Sección: Datos bancarios ────────────────────
                            PremiumSectionCard(
                              title: 'DATOS BANCARIOS',
                              icon: Icons.account_balance_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _bancoCtrl,
                                  label: 'Banco (opcional)',
                                  icon: Icons.account_balance_rounded,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _numeroCuentaCtrl,
                                  label: 'Número de cuenta (opcional)',
                                  icon: Icons.credit_card_rounded,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _notasCtrl,
                                  label: 'Notas (opcional)',
                                  icon: Icons.notes_rounded,
                                  readOnly: !canWrite,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Sección: Estado (solo edición) ──────────────
                            if (_isEditing)
                              PremiumSectionCard(
                                title: 'ESTADO',
                                icon: Icons.toggle_on_rounded,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: SaasPalette.bgSubtle,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: SaasPalette.border),
                                    ),
                                    child: SwitchListTile(
                                      title: const Text(
                                        'Proveedor Activo',
                                        style: TextStyle(
                                          color: SaasPalette.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Disponible para asignar a servicios',
                                        style: TextStyle(
                                          color: SaasPalette.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: _isActive,
                                      activeThumbColor: SaasPalette.success,
                                      activeTrackColor: SaasPalette.success.withValues(alpha: 0.25),
                                      inactiveThumbColor: SaasPalette.textTertiary,
                                      inactiveTrackColor: SaasPalette.bgSubtle,
                                      onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 48),

                            // ── Botón guardar ───────────────────────────────
                            if (canWrite)
                              Builder(
                                builder: (ctx) =>
                                    BlocBuilder<ProveedorBloc, ProveedorState>(
                                      builder: (context, state) =>
                                          PremiumActionButton(
                                            label: _isEditing
                                                ? 'GUARDAR CAMBIOS'
                                                : 'CREAR PROVEEDOR',
                                            icon: Icons.save_rounded,
                                            isLoading: state is ProveedorSaving,
                                            onTap: () => _onSave(ctx),
                                          ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTipoDropdown({required bool canWrite}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIPO DE PROVEEDOR *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tipo,
          dropdownColor: SaasPalette.bgCanvas,
          isExpanded: true,
          style: const TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: SaasPalette.bgCanvas,
            prefixIcon: const Icon(
              Icons.category_rounded,
              color: SaasPalette.brand600,
              size: 18,
            ),
            hintStyle: const TextStyle(color: SaasPalette.textTertiary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: SaasPalette.brand600,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: _kTipos
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    _kTipoLabels[t] ?? t,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: canWrite ? (v) => setState(() => _tipo = v!) : null,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'El tipo es requerido' : null,
        ),
      ],
    );
  }
}
