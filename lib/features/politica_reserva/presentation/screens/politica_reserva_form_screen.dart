import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/politica_reserva.dart';
import '../bloc/politica_reserva_bloc.dart';
import '../bloc/politica_reserva_event.dart';
import '../bloc/politica_reserva_state.dart';

class PoliticaReservaFormScreen extends StatefulWidget {
  final PoliticaReserva? politica;
  const PoliticaReservaFormScreen({super.key, this.politica});

  @override
  State<PoliticaReservaFormScreen> createState() => _PoliticaReservaFormScreenState();
}

class _PoliticaReservaFormScreenState extends State<PoliticaReservaFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _tipoCtrl;
  bool _activo = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;

  bool get _isEditing => widget.politica != null;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.politica?.titulo ?? '');
    _descripcionCtrl = TextEditingController(text: widget.politica?.descripcion ?? '');
    _tipoCtrl = TextEditingController(text: widget.politica?.tipoPolitica ?? '');
    _activo = widget.politica?.activo ?? true;

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _tipoCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final politica = PoliticaReserva(
      id: _isEditing ? widget.politica!.id : 0,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      tipoPolitica: _tipoCtrl.text.trim(),
      activo: _activo,
      fechaCreacion: _isEditing ? widget.politica!.fechaCreacion : null,
    );

    if (_isEditing) {
      context.read<PoliticaReservaBloc>().add(UpdatePolitica(politica));
    } else {
      context.read<PoliticaReservaBloc>().add(CreatePolitica(politica));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == 'admin';

    return BlocListener<PoliticaReservaBloc, PoliticaReservaState>(
      listener: (context, state) {
        if (state is PoliticaSaved) {
          _showMsg(_isEditing ? 'Política actualizada con éxito' : 'Nueva política registrada', D.emerald);
          Navigator.pop(context);
        } else if (state is PoliticaError) {
          _showMsg(state.message, D.rose);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
          title: Text(_isEditing ? 'Configurar Política' : 'Nueva Política', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildSectionCard('DETALLES DE LA POLÍTICA', [
                            _buildField(controller: _tituloCtrl, label: 'Título Principal *', icon: Icons.title_rounded),
                            const SizedBox(height: 24),
                            _buildField(controller: _tipoCtrl, label: 'Tipo de Política (Categoría) *', icon: Icons.category_rounded, hint: 'Ej: Reserva, Cancelación, Privacidad'),
                            const SizedBox(height: 24),
                            _buildField(controller: _descripcionCtrl, label: 'Descripción Detallada *', icon: Icons.description_outlined, maxLines: 6),
                          ]),
                          const SizedBox(height: 32),
                          _buildStatusCard(),
                          const SizedBox(height: 48),
                          if (isAdmin) _buildSubmitButton(),
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

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: D.surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: D.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 14, decoration: BoxDecoration(color: D.skyBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: D.slate400, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ]),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: D.slate600, fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: D.slate800, size: 18),
            hintText: hint,
            hintStyle: TextStyle(color: D.slate800, fontSize: 13),
            filled: true, fillColor: D.bg.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.skyBlue)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Este campo es obligatorio' : null,
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: D.bg.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: D.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estado de la Política', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 4),
              Text('Habilitar para que sea visible en el sistema', style: TextStyle(color: D.slate600, fontSize: 12)),
            ],
          ),
          Switch(
            value: _activo,
            activeThumbColor: D.emerald,
            onChanged: (v) => setState(() => _activo = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<PoliticaReservaBloc, PoliticaReservaState>(
      builder: (context, state) {
        final isSaving = state is PoliticaSaving;
        return GestureDetector(
          onTap: isSaving ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: D.royalBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_rounded, color: Colors.white), SizedBox(width: 12), Text('GUARDAR POLÍTICA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1))]),
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
