import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
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
    _notasCtrl = TextEditingController(text: widget.cliente?.notas ?? '');
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
          _showMsg(
            _isEditing ? 'Cliente actualizado con éxito' : 'Cliente registrado',
            D.emerald,
          );
          Navigator.pop(context);
        } else if (state is ClienteError) {
          _showMsg(state.message, D.rose);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            _isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
            style: const TextStyle(fontWeight: FontWeight.w900, color: D.white),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildSectionCard('DATOS DEL CLIENTE', [
                            _buildField(
                              controller: _nombreCtrl,
                              label: 'Nombre Completo *',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 24),
                            _buildField(
                              controller: _correoCtrl,
                              label: 'Correo Electrónico *',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            _buildField(
                              controller: _telefonoCtrl,
                              label: 'Teléfono *',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionCard('DOCUMENTO DE IDENTIDAD', [
                            _buildTipoDocumentoSelector(),
                            const SizedBox(height: 24),
                            _buildField(
                              controller: _numeroDocumentoCtrl,
                              label: 'Número de Documento *',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ]),
                          const SizedBox(height: 24),
                          _buildSectionCard('INFORMACIÓN ADICIONAL', [
                            _buildDatePicker(),
                          ]),
                          const SizedBox(height: 48),
                          _buildSubmitButton(),
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
    );
  }

  Widget _buildTipoDocumentoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Documento *',
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tipoDocumento,
          dropdownColor: D.surface,
          iconEnabledColor: D.slate400,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.badge_outlined, color: D.slate800, size: 18),
            filled: true,
            fillColor: D.bg.withValues(alpha: 0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.skyBlue),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _tiposDocumento
              .map((tipo) => DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo, style: const TextStyle(color: Colors.white)),
                  ))
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
        Text(
          'Fecha de Nacimiento',
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: D.bg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: D.border),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: D.slate800, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fechaNacimiento != null
                        ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}'
                        : 'Seleccionar fecha...',
                    style: TextStyle(
                      color: _fechaNacimiento != null
                          ? Colors.white
                          : D.slate800,
                      fontSize: 14,
                    ),
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

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: D.skyBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: D.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: maxLines == 1
                ? Icon(icon, color: D.slate800, size: 18)
                : null,
            filled: true,
            fillColor: D.bg.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.skyBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.rose),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.rose),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Este campo es obligatorio'
                    : null
              : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ClienteBloc, ClienteState>(
      builder: (context, state) {
        final isSaving = state is ClienteSaving;
        return GestureDetector(
          onTap: isSaving ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: D.royalBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'GUARDAR CLIENTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
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
