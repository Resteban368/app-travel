import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/faq.dart';
import '../bloc/faq_bloc.dart';
import '../bloc/faq_event.dart';
import '../bloc/faq_state.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';

class FaqFormScreen extends StatefulWidget {
  final Faq? faq;
  const FaqFormScreen({super.key, this.faq});

  @override
  State<FaqFormScreen> createState() => _FaqFormScreenState();
}

class _FaqFormScreenState extends State<FaqFormScreen>
    with SingleTickerProviderStateMixin {
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
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
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
        ? authState.user.canWrite('faqs')
        : false;

    return BlocListener<FaqBloc, FaqState>(
      listener: (context, state) {
        if (state is FaqSaved) {
          _showToast(
            context,
            _isEditing ? 'Pregunta actualizada' : 'Pregunta creada',
          );
          Navigator.pop(context);
        } else if (state is FaqError) {
          _showToast(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing && !canWrite
                      ? 'Ver Pregunta'
                      : (_isEditing ? 'Editar Pregunta' : 'Nueva Pregunta'),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Etiqueta de información
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: D.skyBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: D.skyBlue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.help_outline_rounded,
                                        color: D.skyBlue,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'PREGUNTAS FRECUENTES',
                                        style: TextStyle(
                                          color: D.skyBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'INFORMACIÓN DE LA PREGUNTA',
                                  icon: Icons.question_answer_rounded,
                                  children: [
                                    PremiumTextField(
                                      controller: _questionCtrl,
                                      label: 'Pregunta *',
                                      icon: Icons.help_outline_rounded,
                                      maxLines: 2,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _answerCtrl,
                                      label: 'Respuesta *',
                                      icon: Icons.notes_rounded,
                                      maxLines: 5,
                                      readOnly: !canWrite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'VISIBILIDAD',
                                  icon: Icons.visibility_rounded,
                                  children: [
                                    _buildVisibilitySwitch(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 48),

                                if (canWrite)
                                  Builder(
                                    builder: (ctx) =>
                                        BlocBuilder<FaqBloc, FaqState>(
                                          builder: (context, state) {
                                            return PremiumActionButton(
                                              label: _isEditing
                                                  ? 'ACTUALIZAR PREGUNTA'
                                                  : 'GUARDAR PREGUNTA',
                                              icon: Icons.save_rounded,
                                              isLoading: state is FaqSaving,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySwitch({required bool canWrite}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: D.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: SwitchListTile(
            title: const Text(
              'Estado de Visibilidad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isActive ? 'Públicamente visible' : 'Oculto para los usuarios',
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
