import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/cliente.dart';
import '../bloc/cliente_bloc.dart';
import '../bloc/cliente_event.dart';
import '../bloc/cliente_state.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;
  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _numeroDocumentoCtrl;
  late final TextEditingController _notasCtrl;

  late String _tipoDocumento;
  DateTime? _fechaNacimiento;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;

  bool get _isEditing => widget.cliente != null;

  static const _tiposDocumento = ['CC', 'TI', 'Pasaporte'];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.cliente?.nombre ?? '');
    _correoCtrl = TextEditingController(text: widget.cliente?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: widget.cliente?.telefono ?? '');
    _numeroDocumentoCtrl = TextEditingController(
      text: widget.cliente?.documento ?? '',
    );
    final rawTipo = widget.cliente?.tipoDocumento ?? 'CC';
    _tipoDocumento = _tiposDocumento.firstWhere(
      (t) => t.toLowerCase() == rawTipo.toLowerCase(),
      orElse: () => 'CC',
    );
    _fechaNacimiento = widget.cliente?.fechaNacimiento;

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _numeroDocumentoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cliente = Cliente(
      id: _isEditing ? widget.cliente!.id : null,
      nombre: _nombreCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      tipoDocumento: _tipoDocumento,
      documento: _numeroDocumentoCtrl.text.trim(),
      fechaNacimiento: _fechaNacimiento,
    );

    if (_isEditing) {
      context.read<ClienteBloc>().add(UpdateCliente(cliente));
    } else {
      context.read<ClienteBloc>().add(CreateCliente(cliente));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: D.royalBlue,
            onPrimary: Colors.white,
            surface: D.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClienteBloc, ClienteState>(
      listener: (context, state) {
        if (state is ClienteActionSuccess) {
          final successMsg =
              state.message ??
              (_isEditing
                  ? 'Cliente actualizado con éxito'
                  : 'Cliente registrado');
          _showMsg(successMsg, D.emerald);
          Navigator.pop(context);
        } else if (state is ClienteError) {
          _showMsg(state.message, D.rose);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            const PremiumBackground(),
            FadeTransition(
              opacity: _fade,
              child: CustomScrollView(
                slivers: [
                  PremiumSliverAppBar(
                    title: _isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
                    actions: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: D.white),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // ── Datos Personales ─────────────────────────
                                PremiumSectionCard(
                                  title: 'DATOS PERSONALES',
                                  icon: Icons.person_rounded,
                                  children: [
                                    PremiumTextField(
                                      controller: _nombreCtrl,
                                      label: 'Nombre Completo *',
                                      icon: Icons.badge_rounded,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _correoCtrl,
                                      label: 'Correo Electrónico (opcional)',
                                      icon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _telefonoCtrl,
                                      label: 'Teléfono de Contacto *',
                                      icon: Icons.phone_rounded,
                                      keyboardType: TextInputType.number,
                                      isNumeric: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // ── Identificación ───────────────────────────
                                PremiumSectionCard(
                                  title: 'IDENTIFICACIÓN',
                                  icon: Icons.assignment_ind_rounded,
                                  children: [
                                    _buildTipoDocumentoSelector(),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _numeroDocumentoCtrl,
                                      label: 'Número de Documento *',
                                      icon: Icons.numbers_rounded,
                                      keyboardType: TextInputType.number,
                                      isNumeric: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                const SizedBox(height: 48),

                                // ── Submit ──────────────────────────────────
                                BlocBuilder<ClienteBloc, ClienteState>(
                                  builder: (context, state) {
                                    return PremiumActionButton(
                                      label: 'GUARDAR CLIENTE',
                                      icon: Icons.save_rounded,
                                      isLoading: state is ClienteSaving,
                                      onTap: _save,
                                    );
                                  },
                                ),
                                const SizedBox(height: 100),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTipoDocumentoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Documento *',
          style: TextStyle(
            color: D.slate400,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tipoDocumento,
          dropdownColor: D.surface,
          iconEnabledColor: D.slate400,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.badge_rounded,
              color: D.skyBlue,
              size: 20,
            ),
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
          items: _tiposDocumento
              .map(
                (tipo) => DropdownMenuItem(
                  value: tipo,
                  child: Text(
                    tipo,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _tipoDocumento = v!),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha de Nacimiento',
          style: TextStyle(
            color: D.slate400,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: D.surfaceHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_rounded, color: D.skyBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fechaNacimiento != null
                        ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}'
                        : 'Seleccionar fecha...',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (_fechaNacimiento != null)
                  GestureDetector(
                    onTap: () => setState(() => _fechaNacimiento = null),
                    child: Icon(
                      Icons.close_rounded,
                      color: D.slate600,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
