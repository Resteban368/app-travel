import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/service.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import '../../../settings/presentation/bloc/sede_bloc.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service? service;
  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _descriptionCtrl;
  int? _selectedSedeId;
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _costCtrl = TextEditingController(
      text: widget.service?.cost?.toString() ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _selectedSedeId = widget.service?.idSede;
    _isActive = widget.service?.isActive ?? true;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SedeBloc>().add(LoadSedes());
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final service = Service(
      id: _isEditing ? widget.service!.id : 0,
      name: _nameCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text.trim()),
      description: _descriptionCtrl.text.trim(),
      idSede: _selectedSedeId ?? 0,
      isActive: _isActive,
      createdAt: _isEditing ? widget.service!.createdAt : DateTime.now(),
    );

    if (_isEditing) {
      context.read<ServiceBloc>().add(UpdateService(service));
    } else {
      context.read<ServiceBloc>().add(CreateService(service));
    }
  }

  void _showToast(String msg, {bool isError = false}) {
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
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';

    return BlocListener<ServiceBloc, ServiceState>(
      listener: (context, state) {
        if (state is ServiceSaved) {
          _showToast(_isEditing ? 'Servicio actualizado' : 'Servicio creado');
          Navigator.pop(context);
        } else if (state is ServiceError) {
          _showToast(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            _isEditing ? 'Editar Servicio' : 'Nuevo Servicio',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'MODIFICAR SERVICIO'
                                  : 'DEFINICIÓN DE SERVICIO',
                              style: TextStyle(
                                color: D.skyBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: D.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: D.border),
                              ),
                              child: Column(
                                children: [
                                  _buildField(
                                    controller: _nameCtrl,
                                    label: 'Nombre del Servicio',
                                    hint:
                                        'Ej: Guía bilingüe, Almuerzo típico...',
                                    icon: Icons.label_important_outline_rounded,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSedeDropdown(),
                                  const SizedBox(height: 20),
                                  _buildField(
                                    controller: _costCtrl,
                                    label: 'Costo (Opcional)',
                                    hint: 'Ej: 50000',
                                    icon: Icons.attach_money_rounded,
                                    isNumeric: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildField(
                                    controller: _descriptionCtrl,
                                    label: 'Descripción Detallada',
                                    hint:
                                        'Describe qué incluye este servicio...',
                                    icon: Icons.description_outlined,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: D.bg.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: D.border),
                                    ),
                                    child: SwitchListTile(
                                      title: const Text(
                                        'Servicio Activo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _isActive
                                            ? 'Visible en el sistema'
                                            : 'Oculto actualmente',
                                        style: TextStyle(
                                          color: D.slate400,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: _isActive,
                                      activeColor: D.emerald,
                                      onChanged: (v) =>
                                          setState(() => _isActive = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            _GlowSaveButton(
                              onPressed: _save,
                              isDisabled: !isAdmin,
                            ),
                            const SizedBox(height: 40),
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

  Widget _buildSedeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.store_rounded, color: D.slate600, size: 16),
            const SizedBox(width: 8),
            Text(
              'Sede Asociada',
              style: TextStyle(
                color: D.slate400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        BlocBuilder<SedeBloc, SedeState>(
          builder: (context, state) {
            final isLoading = state is SedeLoading;
            final sedes = state is SedesLoaded ? state.sedes : [];
            return DropdownButtonFormField<int>(
              value: _selectedSedeId,
              dropdownColor: D.surfaceHigh,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: D.bg.withOpacity(0.5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: D.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: D.skyBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                hintText: isLoading
                    ? 'Cargando sedes...'
                    : 'Selecciona una sede',
                hintStyle: TextStyle(color: D.slate600),
              ),
              items: sedes
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: int.tryParse(s.id) ?? 0,
                      child: Text(s.nombreSede),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedSedeId = v),
              validator: (v) =>
                  v == null ? 'Por favor selecciona una sede' : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: D.slate600, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: D.slate400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: D.slate600, fontSize: 14),
            filled: true,
            fillColor: D.bg.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: D.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: D.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: D.skyBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) => (!isNumeric && (v == null || v.isEmpty))
              ? 'Campo requerido'
              : null,
        ),
      ],
    );
  }
}

class _GlowSaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDisabled;
  const _GlowSaveButton({required this.onPressed, this.isDisabled = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceBloc, ServiceState>(
      builder: (context, state) {
        final isSaving = state is ServiceSaving;
        final actualDisabled = isDisabled || isSaving;
        return GestureDetector(
          onTap: actualDisabled ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: actualDisabled
                    ? [D.slate600, D.slate600]
                    : [D.indigo, D.royalBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: actualDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: D.indigo.withOpacity(0.4),
                        blurRadius: 20,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'GUARDAR SERVICIO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
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
