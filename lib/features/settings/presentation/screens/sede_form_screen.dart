import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/sede.dart';
import '../bloc/sede_bloc.dart';

class SedeFormScreen extends StatefulWidget {
  final Sede? sede;
  const SedeFormScreen({super.key, this.sede});

  @override
  State<SedeFormScreen> createState() => _SedeFormScreenState();
}

class _SedeFormScreenState extends State<SedeFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _mapsLinkCtrl;
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.sede != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sede?.nombreSede ?? '');
    _phoneCtrl = TextEditingController(text: widget.sede?.telefono ?? '');
    _addressCtrl = TextEditingController(text: widget.sede?.direccion ?? '');
    _mapsLinkCtrl = TextEditingController(text: widget.sede?.linkMap ?? '');
    _isActive = widget.sede?.isActive ?? true;

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _mapsLinkCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final id = _isEditing ? widget.sede!.id : DateTime.now().millisecondsSinceEpoch.toString();
    final sede = Sede(
      id: id,
      nombreSede: _nameCtrl.text.trim(),
      telefono: _phoneCtrl.text.trim(),
      direccion: _addressCtrl.text.trim(),
      linkMap: _mapsLinkCtrl.text.trim(),
      isActive: _isActive,
    );
    if (_isEditing) context.read<SedeBloc>().add(UpdateSede(sede));
    else context.read<SedeBloc>().add(CreateSede(sede));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SedeBloc>(),
      child: BlocListener<SedeBloc, SedeState>(
        listener: (context, state) {
          if (state is SedeSaved) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Sede actualizada' : 'Sede creada'), backgroundColor: D.emerald));
            Navigator.pop(context, true);
          } else if (state is SedeError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: D.rose));
          }
        },
        child: Scaffold(
          backgroundColor: D.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0, foregroundColor: Colors.white,
            title: Text(_isEditing ? 'Editar Punto de Atención' : 'Nueva Sede Oficial', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildFormCard(),
                              const SizedBox(height: 48),
                              Builder(
                                builder: (ctx) => _GlowSaveButton(onPressed: () => _save(ctx)),
                              ),
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
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: D.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: D.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('INFORMACIÓN GENERAL'),
          const SizedBox(height: 24),
          _buildField(controller: _nameCtrl, label: 'Nombre de la Sede *', icon: Icons.store_rounded),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildField(controller: _phoneCtrl, label: 'Teléfono Contacto *', icon: Icons.phone_rounded)),
              const SizedBox(width: 20),
              Expanded(child: _buildField(controller: _mapsLinkCtrl, label: 'Google Maps Link', icon: Icons.map_rounded)),
            ],
          ),
          const SizedBox(height: 20),
          _buildField(controller: _addressCtrl, label: 'Dirección Exacta *', icon: Icons.place_rounded),
          const SizedBox(height: 32),
          _sectionHeader('OPERATIVIDAD'),
          const SizedBox(height: 16),
          _buildSwitch(),
        ],
      ),
    );
  }

  Widget _buildSwitch() {
    return Container(
      decoration: BoxDecoration(color: D.bg.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: D.border)),
      child: SwitchListTile(
        title: const Text('Visibilidad Pública', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(_isActive ? 'La sede aparecerá en la aplicación para clientes.' : 'Sede oculta temporalmente.', style: TextStyle(color: D.slate400, fontSize: 12)),
        value: _isActive,
        activeColor: D.emerald,
        onChanged: (v) => setState(() => _isActive = v),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: D.slate400, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: D.slate600, size: 18),
            filled: true, fillColor: D.bg.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.skyBlue)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => (v == null || v.isEmpty) && label.contains('*') ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: D.skyBlue, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: D.slate600, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }
}

class _GlowSaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GlowSaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SedeBloc, SedeState>(
      builder: (context, state) {
        final isSaving = state is SedeSaving;
        return GestureDetector(
          onTap: isSaving ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56, width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isSaving ? [D.slate600, D.slate600] : [D.royalBlue, D.cyan]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSaving ? null : [BoxShadow(color: D.royalBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
