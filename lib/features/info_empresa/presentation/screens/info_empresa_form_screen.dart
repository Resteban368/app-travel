import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/info_empresa.dart';
import '../bloc/info_empresa_bloc.dart';
import '../bloc/info_empresa_event.dart';
import '../bloc/info_empresa_state.dart';

class InfoEmpresaFormScreen extends StatefulWidget {
  final InfoEmpresa? info;
  const InfoEmpresaFormScreen({super.key, this.info});

  @override
  State<InfoEmpresaFormScreen> createState() => _InfoEmpresaFormScreenState();
}

class _InfoEmpresaFormScreenState extends State<InfoEmpresaFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _bgCtrl;

  late TextEditingController _nombreCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _misionCtrl;
  late TextEditingController _visionCtrl;
  late TextEditingController _detallesCtrl;
  late TextEditingController _horarioPCtrl;
  late TextEditingController _horarioVCtrl;
  late TextEditingController _gerenteCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _webCtrl;

  List<RedSocial> _redesSociales = [];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _nombreCtrl = TextEditingController(text: widget.info?.nombre);
    _direccionCtrl = TextEditingController(text: widget.info?.direccion);
    _misionCtrl = TextEditingController(text: widget.info?.mision);
    _visionCtrl = TextEditingController(text: widget.info?.vision);
    _detallesCtrl = TextEditingController(text: widget.info?.detalles);
    _horarioPCtrl = TextEditingController(text: widget.info?.horarioPresencial);
    _horarioVCtrl = TextEditingController(text: widget.info?.horarioVirtual);
    _gerenteCtrl = TextEditingController(text: widget.info?.nombreGerente);
    _telefonoCtrl = TextEditingController(text: widget.info?.telefono);
    _correoCtrl = TextEditingController(text: widget.info?.correo);
    _webCtrl = TextEditingController(text: widget.info?.sitioWeb);

    _redesSociales = widget.info?.redesSociales != null ? List.from(widget.info!.redesSociales) : [];
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _misionCtrl.dispose();
    _visionCtrl.dispose();
    _detallesCtrl.dispose();
    _horarioPCtrl.dispose();
    _horarioVCtrl.dispose();
    _gerenteCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(IconData icon, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: D.slate400, fontSize: 13),
      prefixIcon: Icon(icon, color: D.skyBlue, size: 20),
      filled: true,
      fillColor: D.surfaceHigh.withOpacity(0.5),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.royalBlue)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: D.rose.withOpacity(0.5))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.rose)),
      floatingLabelStyle: const TextStyle(color: D.skyBlue),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final info = InfoEmpresa(
      id: widget.info?.id ?? 0,
      nombre: _nombreCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      mision: _misionCtrl.text.trim(),
      vision: _visionCtrl.text.trim(),
      detalles: _detallesCtrl.text.trim(),
      horarioPresencial: _horarioPCtrl.text.trim(),
      horarioVirtual: _horarioVCtrl.text.trim(),
      redesSociales: _redesSociales,
      nombreGerente: _gerenteCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      sitioWeb: _webCtrl.text.trim(),
    );

    if (widget.info == null) {
      context.read<InfoEmpresaBloc>().add(CreateInfo(info));
    } else {
      context.read<InfoEmpresaBloc>().add(UpdateInfo(info));
    }
  }

  void _addRedSocial() {
    final nCtrl = TextEditingController();
    final lCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: D.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: D.border)),
        title: const Text('Añadir Red Social', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(Icons.label_rounded, 'Nombre (ej: Instagram)')),
            const SizedBox(height: 16),
            TextField(
                controller: lCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(Icons.link_rounded, 'Link / URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: D.slate400))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: D.royalBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (nCtrl.text.isNotEmpty && lCtrl.text.isNotEmpty) {
                setState(() => _redesSociales.add(RedSocial(nombre: nCtrl.text.trim(), link: lCtrl.text.trim())));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Añadir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.role == 'admin';

    return BlocListener<InfoEmpresaBloc, InfoEmpresaState>(
      listener: (context, state) {
        if (state is InfoSaved) Navigator.pop(context);
        if (state is InfoError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: D.rose));
        }
      },
      child: BlocBuilder<InfoEmpresaBloc, InfoEmpresaState>(
        builder: (context, state) {
          final isSaving = state is InfoSaving;

          return Scaffold(
            backgroundColor: D.bg,
            body: Stack(
              children: [
                AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (context, _) => Stack(
                    children: [
                      Positioned(
                        top: -100 + math.cos(_bgCtrl.value * math.pi * 2) * 40,
                        left: -50 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                        child: Container(
                          width: 400,
                          height: 400,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [D.royalBlue.withOpacity(0.08), Colors.transparent])),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      title: Text(widget.info == null ? 'Nueva Configuración' : 'Editar Información',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AbsorbPointer(
                          absorbing: isSaving,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _PremiumCard(
                                  title: 'Datos Generales',
                                  icon: Icons.business_rounded,
                                  children: [
                                    _buildField(_nombreCtrl, 'Nombre Empresa', Icons.business_rounded, required: true),
                                    _buildField(_gerenteCtrl, 'Gerente General', Icons.person_rounded),
                                    _buildField(_detallesCtrl, 'Sobre nosotros', Icons.info_outline_rounded, maxLines: 4),
                                  ],
                                ),
                                _PremiumCard(
                                  title: 'Filosofía Corporativa',
                                  icon: Icons.auto_awesome_rounded,
                                  children: [
                                    _buildField(_misionCtrl, 'Misión', Icons.flag_rounded, maxLines: 3),
                                    _buildField(_visionCtrl, 'Visión', Icons.visibility_rounded, maxLines: 3),
                                  ],
                                ),
                                _PremiumCard(
                                  title: 'Contacto y Canales',
                                  icon: Icons.contact_emergency_rounded,
                                  children: [
                                    _buildField(_direccionCtrl, 'Dirección Principal', Icons.location_on_rounded),
                                    _buildField(_telefonoCtrl, 'Teléfono WhatsApp', Icons.phone_android_rounded),
                                    _buildField(_correoCtrl, 'Correo Institucional', Icons.email_rounded),
                                    _buildField(_webCtrl, 'Sitio Web', Icons.language_rounded),
                                  ],
                                ),
                                _PremiumCard(
                                  title: 'Horarios de Operación',
                                  icon: Icons.more_time_rounded,
                                  children: [
                                    _buildField(_horarioPCtrl, 'Atención Presencial', Icons.access_time_rounded),
                                    _buildField(_horarioVCtrl, 'Soporte Virtual / AI Agent', Icons.smart_toy_rounded),
                                  ],
                                ),
                                _buildRedesSocialesSection(),
                                const SizedBox(height: 32),
                                if (isAdmin) _buildSubmitButton(isSaving),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: _inputDecoration(icon, label),
        validator: (v) => required && (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null,
      ),
    );
  }

  Widget _buildRedesSocialesSection() {
    return _PremiumCard(
      title: 'Presencia Digital',
      icon: Icons.share_rounded,
      action: IconButton(onPressed: _addRedSocial, icon: const Icon(Icons.add_circle_outline_rounded, color: D.skyBlue)),
      children: [
        if (_redesSociales.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No hay redes sociales configuradas', style: TextStyle(color: D.slate600, fontStyle: FontStyle.italic)),
          )
        else
          ..._redesSociales.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: D.surfaceHigh, borderRadius: BorderRadius.circular(14), border: Border.all(color: D.border)),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: D.skyBlue, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(e.value.link, style: TextStyle(color: D.slate400, fontSize: 11)),
                      ],
                    )),
                    IconButton(
                        onPressed: () => setState(() => _redesSociales.removeAt(e.key)),
                        icon: const Icon(Icons.delete_outline_rounded, color: D.rose, size: 18))
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildSubmitButton(bool isSaving) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [D.royalBlue, D.skyBlue]),
        boxShadow: [BoxShadow(color: D.royalBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        onPressed: isSaving ? null : _onSave,
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(widget.info == null ? 'CREAR PERFIL EMPRESA' : 'GUARDAR CAMBIOS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                ],
              ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? action;

  const _PremiumCard({required this.title, required this.icon, required this.children, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: D.surface.withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(color: D.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: D.skyBlue, size: 18),
                  const SizedBox(width: 12),
                  Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ],
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: D.border.withOpacity(0.5)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
