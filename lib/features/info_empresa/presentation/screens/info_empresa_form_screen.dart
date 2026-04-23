import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        backgroundColor: isError ? SaasPalette.danger : SaasPalette.success,
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

  static const _socialPlatforms = [
    _SocialPlatform('Instagram', Icons.camera_alt_rounded, Color(0xFFE1306C)),
    _SocialPlatform('Facebook', Icons.facebook_rounded, Color(0xFF1877F2)),
    _SocialPlatform('TikTok', Icons.music_note_rounded, Color(0xFF010101)),
    _SocialPlatform('YouTube', Icons.play_circle_fill_rounded, Color(0xFFFF0000)),
    _SocialPlatform('LinkedIn', Icons.work_rounded, Color(0xFF0A66C2)),
    _SocialPlatform('Twitter / X', Icons.alternate_email_rounded, Color(0xFF1DA1F2)),
    _SocialPlatform('WhatsApp', Icons.chat_rounded, Color(0xFF25D366)),
    _SocialPlatform('Telegram', Icons.send_rounded, Color(0xFF2CA5E0)),
    _SocialPlatform('Otro', Icons.link_rounded, SaasPalette.brand600),
  ];

  void _addRedSocial() {
    final nCtrl = TextEditingController();
    final lCtrl = TextEditingController();
    String? urlError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selected = _socialPlatforms
              .where((p) => p.name == nCtrl.text)
              .firstOrNull;

          void selectPlatform(_SocialPlatform p) {
            setDialogState(() {
              nCtrl.text = p.name;
              urlError = null;
            });
          }

          void tryAdd() {
            if (lCtrl.text.trim().isEmpty) {
              setDialogState(() => urlError = 'Ingresa el enlace de la red social');
              return;
            }
            if (nCtrl.text.trim().isEmpty) {
              setDialogState(() => urlError = 'Selecciona o escribe el nombre');
              return;
            }
            setState(() => _redesSociales.add(
              RedSocial(nombre: nCtrl.text.trim(), link: lCtrl.text.trim()),
            ));
            Navigator.pop(ctx);
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: SaasPalette.bgCanvas,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SaasPalette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [SaasPalette.brand600, SaasPalette.brand900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nueva Red Social',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Selecciona la plataforma y pega el enlace',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Selector de plataforma ───────────────
                        const Text(
                          'PLATAFORMA',
                          style: TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _socialPlatforms.map((p) {
                            final isSelected = selected?.name == p.name;
                            return GestureDetector(
                              onTap: () => selectPlatform(p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? p.color.withValues(alpha: 0.1)
                                      : SaasPalette.bgSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? p.color.withValues(alpha: 0.5)
                                        : SaasPalette.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      p.icon,
                                      size: 14,
                                      color: isSelected
                                          ? p.color
                                          : SaasPalette.textTertiary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? p.color
                                            : SaasPalette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // ── Campo nombre (editable) ───────────────
                        PremiumTextField(
                          controller: nCtrl,
                          label: 'Nombre de la plataforma *',
                          icon: selected?.icon ?? Icons.label_rounded,
                        ),
                        const SizedBox(height: 16),

                        // ── Campo URL ────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PremiumTextField(
                              controller: lCtrl,
                              label: 'Enlace / URL *',
                              icon: Icons.link_rounded,
                            ),
                            if (urlError != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 13,
                                    color: SaasPalette.danger,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    urlError!,
                                    style: const TextStyle(
                                      color: SaasPalette.danger,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Botones ──────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(
                                    color: SaasPalette.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: SaasPalette.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: tryAdd,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selected?.color ??
                                      SaasPalette.brand600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  'Añadir',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('infoEmpresa')
        : false;

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
        body: Stack(
          children: [
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
                                    color: SaasPalette.brand50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: SaasPalette.brand600.withValues(alpha: 0.3),
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
                                        'PERFIL EMPRESARIAL',
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

                                _buildRedesSocialesSection(canWrite: canWrite),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  IconData _iconForPlatform(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('instagram')) return Icons.camera_alt_rounded;
    if (n.contains('facebook')) return Icons.facebook_rounded;
    if (n.contains('tiktok')) return Icons.music_note_rounded;
    if (n.contains('youtube')) return Icons.play_circle_fill_rounded;
    if (n.contains('linkedin')) return Icons.work_rounded;
    if (n.contains('twitter') || n.contains(' x')) {
      return Icons.alternate_email_rounded;
    }
    if (n.contains('whatsapp')) return Icons.chat_rounded;
    if (n.contains('telegram')) return Icons.send_rounded;
    return Icons.link_rounded;
  }

  Color _colorForPlatform(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('instagram')) return const Color(0xFFE1306C);
    if (n.contains('facebook')) return const Color(0xFF1877F2);
    if (n.contains('tiktok')) return const Color(0xFF010101);
    if (n.contains('youtube')) return const Color(0xFFFF0000);
    if (n.contains('linkedin')) return const Color(0xFF0A66C2);
    if (n.contains('twitter') || n.contains(' x')) {
      return const Color(0xFF1DA1F2);
    }
    if (n.contains('whatsapp')) return const Color(0xFF25D366);
    if (n.contains('telegram')) return const Color(0xFF2CA5E0);
    return SaasPalette.brand600;
  }

  Widget _buildRedesSocialesSection({required bool canWrite}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SaasPalette.brand50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: SaasPalette.brand600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'PRESENCIA DIGITAL',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (canWrite)
                TextButton.icon(
                  onPressed: _addRedSocial,
                  style: TextButton.styleFrom(
                    foregroundColor: SaasPalette.brand600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: SaasPalette.border),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Añadir',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: SaasPalette.border),
          const SizedBox(height: 12),
          if (_redesSociales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: SaasPalette.textTertiary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No hay redes sociales configuradas',
                    style: TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._redesSociales.asMap().entries.map((e) {
              final color = _colorForPlatform(e.value.nombre);
              final icon = _iconForPlatform(e.value.nombre);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SaasPalette.bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SaasPalette.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.nombre,
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.value.link,
                            style: const TextStyle(
                              color: SaasPalette.textTertiary,
                              fontSize: 12,
                            ),
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
                          color: SaasPalette.danger,
                          size: 18,
                        ),
                        tooltip: 'Eliminar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Modelo local para el selector de plataformas ─────────────────────────────
class _SocialPlatform {
  final String name;
  final IconData icon;
  final Color color;
  const _SocialPlatform(this.name, this.icon, this.color);
}
