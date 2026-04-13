import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/faq.dart';
import '../bloc/faq_bloc.dart';
import '../bloc/faq_event.dart';
import '../bloc/faq_state.dart';

class FaqFormScreen extends StatefulWidget {
  final Faq? faq;
  const FaqFormScreen({super.key, this.faq});

  @override
  State<FaqFormScreen> createState() => _FaqFormScreenState();
}

class _FaqFormScreenState extends State<FaqFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionCtrl;
  late final TextEditingController _answerCtrl;
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.faq != null;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.faq?.question ?? '');
    _answerCtrl = TextEditingController(text: widget.faq?.answer ?? '');
    _isActive = widget.faq?.isActive ?? true;

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final faq = Faq(
      id: _isEditing ? widget.faq!.id : 0,
      question: _questionCtrl.text.trim(),
      answer: _answerCtrl.text.trim(),
      isActive: _isActive,
      createdAt: _isEditing ? widget.faq!.createdAt : DateTime.now(),
    );

    if (_isEditing) {
      context.read<FaqBloc>().add(UpdateFaq(faq));
    } else {
      context.read<FaqBloc>().add(CreateFaq(faq));
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
    return BlocListener<FaqBloc, FaqState>(
      listener: (context, state) {
        if (state is FaqSaved) {
          _showToast(_isEditing ? 'Pregunta actualizada' : 'Pregunta creada');
          Navigator.pop(context);
        } else if (state is FaqError) {
          _showToast(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(_isEditing ? 'Editar Pregunta' : 'Nueva Pregunta', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              _isEditing ? 'MODIFICAR FAQ' : 'INFORMACIÓN DE PREGUNTA',
                              style: TextStyle(color: D.skyBlue, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
                                    controller: _questionCtrl,
                                    label: 'Pregunta',
                                    hint: '¿Cómo funciona el servicio?',
                                    icon: Icons.help_outline_rounded,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildField(
                                    controller: _answerCtrl,
                                    label: 'Respuesta',
                                    hint: 'Detalla la respuesta completa aquí...',
                                    icon: Icons.question_answer_outlined,
                                    maxLines: 5,
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: D.bg.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: D.border),
                                    ),
                                    child: SwitchListTile(
                                      title: const Text('Visible públicamente', style: TextStyle(color: Colors.white, fontSize: 14)),
                                      subtitle: Text('Estado actual: ${_isActive ? 'Activo' : 'Oculto'}', style: TextStyle(color: D.slate400, fontSize: 12)),
                                      value: _isActive,
                                      activeColor: D.emerald,
                                      onChanged: (v) => setState(() => _isActive = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            _GlowSaveButton(onPressed: _save),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: D.slate600, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: D.slate400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: D.slate600, fontSize: 14),
            filled: true,
            fillColor: D.bg.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: D.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: D.skyBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: D.rose, width: 1)),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
        ),
      ],
    );
  }
}

class _GlowSaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GlowSaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaqBloc, FaqState>(
      builder: (context, state) {
        final isSaving = state is FaqSaving;
        return GestureDetector(
          onTap: isSaving ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isSaving ? [D.slate600, D.slate600] : [D.indigo, D.royalBlue]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSaving ? null : [
                BoxShadow(color: D.indigo.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Center(
              child: isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('GUARDAR PREGUNTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
    const spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
