import 'dart:ui';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/info_empresa.dart';
import '../bloc/info_empresa_bloc.dart';
import '../bloc/info_empresa_event.dart';
import '../bloc/info_empresa_state.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

class InfoEmpresaFormScreen extends StatefulWidget {
  final InfoEmpresa? info;
  const InfoEmpresaFormScreen({super.key, this.info});

  @override
  State<InfoEmpresaFormScreen> createState() => _InfoEmpresaFormScreenState();
}

class _InfoEmpresaFormScreenState extends State<InfoEmpresaFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

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

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.info != null;

  @override
  void initState() {
    super.initState();
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

    _redesSociales = widget.info?.redesSociales != null
        ? List.from(widget.info!.redesSociales)
        : [];

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

  void _showMsg(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? D.rose : D.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSave(BuildContext context) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: D.border),
        ),
        title: const Text(
          'Añadir Red Social',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumTextField(
              controller: nCtrl,
              label: 'Nombre (ej: Instagram) *',
              icon: Icons.label_rounded,
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: lCtrl,
              label: 'Enlace / URL *',
              icon: Icons.link_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: D.slate400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: D.royalBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (nCtrl.text.isNotEmpty && lCtrl.text.isNotEmpty) {
                setState(
                  () => _redesSociales.add(
                    RedSocial(
                      nombre: nCtrl.text.trim(),
                      link: lCtrl.text.trim(),
                    ),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Añadir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';

    // Para la info de la empresa, asumimos que solo los admins pueden modificarla
    final canWrite = isAdmin;

    return BlocListener<InfoEmpresaBloc, InfoEmpresaState>(
      listener: (context, state) {
        if (state is InfoSaved) {
          _showMsg(
            context,
            _isEditing
                ? 'Información actualizada con éxito'
                : 'Perfil de empresa creado',
          );
          Navigator.pop(context);
        } else if (state is InfoError) {
          _showMsg(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            const PremiumBackground(),
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing && !canWrite
                      ? 'Ver Información'
                      : (_isEditing
                            ? 'Editar Información'
                            : 'Nueva Configuración'),
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
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Etiqueta
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
                                          Icons.business_rounded,
                                          color: D.skyBlue,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'PERFIL EMPRESARIAL',
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
                                    title: 'DATOS GENERALES',
                                    icon: Icons.domain_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _nombreCtrl,
                                        label: 'Nombre Empresa *',
                                        icon: Icons.business_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _gerenteCtrl,
                                        label: 'Gerente General',
                                        icon: Icons.person_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _detallesCtrl,
                                        label: 'Sobre nosotros *',
                                        icon: Icons.info_outline_rounded,
                                        maxLines: 4,
                                        readOnly: !canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  PremiumSectionCard(
                                    title: 'FILOSOFÍA CORPORATIVA',
                                    icon: Icons.auto_awesome_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _misionCtrl,
                                        label: 'Misión *',
                                        icon: Icons.flag_rounded,
                                        maxLines: 3,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _visionCtrl,
                                        label: 'Visión *',
                                        icon: Icons.visibility_rounded,
                                        maxLines: 3,
                                        readOnly: !canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  PremiumSectionCard(
                                    title: 'CONTACTO Y CANALES',
                                    icon: Icons.contact_emergency_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _direccionCtrl,
                                        label: 'Dirección Principal *',
                                        icon: Icons.location_on_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _telefonoCtrl,
                                        label: 'Teléfono WhatsApp *',
                                        icon: Icons.phone_android_rounded,
                                        isNumeric: true,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _correoCtrl,
                                        label: 'Correo Institucional *',
                                        icon: Icons.email_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _webCtrl,
                                        label: 'Sitio Web',
                                        icon: Icons.language_rounded,
                                        readOnly: !canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  PremiumSectionCard(
                                    title: 'HORARIOS DE OPERACIÓN',
                                    icon: Icons.more_time_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _horarioPCtrl,
                                        label: 'Atención Presencial *',
                                        icon: Icons.access_time_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _horarioVCtrl,
                                        label: 'Soporte Virtual / AI Agent *',
                                        icon: Icons.smart_toy_rounded,
                                        readOnly: !canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  _buildRedesSocialesSection(
                                    canWrite: canWrite,
                                  ),
                                  const SizedBox(height: 48),

                                  if (canWrite)
                                    Builder(
                                      builder: (ctx) =>
                                          BlocBuilder<
                                            InfoEmpresaBloc,
                                            InfoEmpresaState
                                          >(
                                            builder: (context, state) {
                                              return PremiumActionButton(
                                                label: _isEditing
                                                    ? 'GUARDAR CAMBIOS'
                                                    : 'CREAR PERFIL EMPRESA',
                                                icon: Icons.save_rounded,
                                                isLoading: state is InfoSaving,
                                                onTap: () => _onSave(ctx),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedesSocialesSection({required bool canWrite}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: D.surfaceHigh.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.share_rounded, color: D.skyBlue, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'PRESENCIA DIGITAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (canWrite)
                Material(
                  color: D.skyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _addRedSocial,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.add_rounded,
                        color: D.skyBlue,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: D.border.withOpacity(0.5)),
          const SizedBox(height: 16),
          if (_redesSociales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No hay redes sociales configuradas',
                style: TextStyle(
                  color: D.slate600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._redesSociales.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: D.surfaceHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: D.royalBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.link_rounded,
                        color: D.skyBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value.link,
                            style: TextStyle(color: D.slate400, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (canWrite)
                      IconButton(
                        onPressed: () =>
                            setState(() => _redesSociales.removeAt(e.key)),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: D.rose,
                          size: 20,
                        ),
                        tooltip: 'Eliminar Red Social',
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
