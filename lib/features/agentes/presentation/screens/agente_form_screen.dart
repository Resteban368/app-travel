import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/agente.dart';
import '../bloc/agente_bloc.dart';
import '../bloc/agente_event.dart';
import '../bloc/agente_state.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

// ─── Definición de módulos disponibles ───────────────────────────────────────

class _Module {
  final String key;
  final String label;
  final IconData icon;
  const _Module({required this.key, required this.label, required this.icon});
}

const _modules = [
  //dashboard
  _Module(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
  _Module(key: 'tours', label: 'Tours y Promociones', icon: Icons.tour_rounded),
  _Module(key: 'sedes', label: 'Sedes', icon: Icons.store_rounded),
  _Module(
    key: 'paymentMethods',
    label: 'Métodos de Pago',
    icon: Icons.payment_rounded,
  ),
  _Module(
    key: 'catalogues',
    label: 'Catálogos',
    icon: Icons.picture_as_pdf_rounded,
  ),
  _Module(
    key: 'faqs',
    label: 'Preguntas Frecuentes',
    icon: Icons.help_outline_rounded,
  ),
  _Module(
    key: 'services',
    label: 'Servicios',
    icon: Icons.settings_suggest_rounded,
  ),
  _Module(
    key: 'politicasReserva',
    label: 'Políticas de Reserva',
    icon: Icons.policy_rounded,
  ),
  _Module(
    key: 'infoEmpresa',
    label: 'Información Empresa',
    icon: Icons.business_rounded,
  ),
  _Module(
    key: 'pagosRealizados',
    label: 'Pagos Realizados',
    icon: Icons.payments_rounded,
  ),
  _Module(
    key: 'agentes',
    label: 'Gestión de Agentes',
    icon: Icons.person_add_alt_1_rounded,
  ),
  _Module(
    key: 'reservas',
    label: 'Gestión de Reservas',
    icon: Icons.airplane_ticket_rounded,
  ),
  _Module(
    key: 'cotizacion',
    label: 'Cotizaciones',
    icon: Icons.request_quote_rounded,
  ),
  _Module(key: 'clientes', label: 'Clientes', icon: Icons.people_rounded),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class AgenteFormScreen extends StatefulWidget {
  final Agente? agente;
  const AgenteFormScreen({super.key, this.agente});

  @override
  State<AgenteFormScreen> createState() => _AgenteFormScreenState();
}

class _AgenteFormScreenState extends State<AgenteFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _passwordCtrl;

  late Map<String, String> _permisos;
  late bool _isActive;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.agente != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.agente?.nombre ?? '');
    _correoCtrl = TextEditingController(text: widget.agente?.correo ?? '');
    _passwordCtrl = TextEditingController();
    _permisos = Map.from(widget.agente?.permisos ?? {});
    _isActive = widget.agente?.isActive ?? true;

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
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? D.rose : D.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _save(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;

    final agente = Agente(
      id: _isEditing ? widget.agente!.id : 0,
      nombre: _nombreCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      permisos: _permisos,
      isActive: _isActive,
    );

    if (_isEditing) {
      ctx.read<AgenteBloc>().add(UpdateAgente(agente));
    } else {
      ctx.read<AgenteBloc>().add(CreateAgente(agente));
    }
  }

  static const Map<String, List<String>> _dependencias = {
    'reservas': ['tours', 'pagosRealizados'],
  };

  void _toggleModule(String key, bool enabled) {
    setState(() {
      if (enabled) {
        _permisos[key] = 'lectura';
        final deps = _dependencias[key] ?? [];
        for (final dep in deps) {
          _permisos.putIfAbsent(dep, () => 'lectura');
        }
      } else {
        _permisos.remove(key);
      }
    });
  }

  void _setLevel(String key, String level) {
    setState(() => _permisos[key] = level);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AgenteBloc, AgenteState>(
      listener: (context, state) {
        if (state is AgenteActionSuccess) {
          _showMsg(
            _isEditing
                ? 'Agente actualizado con éxito'
                : 'Nuevo agente registrado',
          );
          Navigator.pop(context);
        } else if (state is AgenteError) {
          _showMsg(state.message, isError: true);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing ? 'Editar Agente' : 'Nuevo Agente',
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
                                // ── Badge de Ruta ───────────────────────────
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SaasPalette.brand600.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: SaasPalette.brand600
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.admin_panel_settings_rounded,
                                            color: SaasPalette.brand600,
                                            size: 14,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'ADMINISTRACIÓN / AGENTES',
                                            style: TextStyle(
                                              color: SaasPalette.brand600,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'DATOS PERSONALES',
                                  icon: Icons.person_outline_rounded,
                                  children: [
                                    PremiumTextField(
                                      controller: _nombreCtrl,
                                      label: 'Nombre Completo *',
                                      icon: Icons.person_rounded,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _correoCtrl,
                                      label: 'Correo Electrónico *',
                                      icon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 20),
                                    if (!_isEditing) ...[
                                      PremiumTextField(
                                        controller: _passwordCtrl,
                                        label: 'Contraseña *',
                                        icon: Icons.lock_rounded,
                                        isPassword: true,
                                        validator: (v) {
                                          if (!_isEditing &&
                                              (v == null || v.isEmpty)) {
                                            return 'La contraseña es obligatoria';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    _buildActiveToggle(),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'PERMISOS DE ACCESO',
                                  icon: Icons.security_rounded,
                                  children: [
                                    Text(
                                      'Define a qué módulos podrá acceder y qué acciones podrá realizar.',
                                      style: TextStyle(
                                        color: SaasPalette.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        _LegendBadge(
                                          icon: Icons.visibility_rounded,
                                          label: 'Ver solo',
                                          color: SaasPalette.brand600,
                                        ),
                                        const SizedBox(width: 16),
                                        _LegendBadge(
                                          icon: Icons.edit_rounded,
                                          label: 'Ver y Editar',
                                          color: SaasPalette.success,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    ..._modules.map((m) => _buildModuleRow(m)),
                                  ],
                                ),
                                const SizedBox(height: 48),

                                Builder(
                                  builder: (ctx) =>
                                      BlocBuilder<AgenteBloc, AgenteState>(
                                        builder: (context, state) {
                                          return PremiumActionButton(
                                            label: _isEditing
                                                ? 'ACTUALIZAR AGENTE'
                                                : 'GUARDAR AGENTE',
                                            icon: Icons.save_rounded,
                                            isLoading: state is AgenteSaving,
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

  Widget _buildActiveToggle() {
    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado de Acceso',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isActive ? 'Habilitado' : 'Bloqueado',
                    style: TextStyle(
                      color: _isActive
                          ? SaasPalette.success
                          : SaasPalette.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isActive,
              activeThumbColor: SaasPalette.success,
              activeTrackColor: SaasPalette.success.withOpacity(0.2),
              inactiveThumbColor: SaasPalette.danger,
              inactiveTrackColor: SaasPalette.danger.withOpacity(0.2),
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleRow(_Module module) {
    final enabled = _permisos.containsKey(module.key);
    final level = _permisos[module.key] ?? 'lectura';
    final isCompleto = level == 'completo';

    // Colores dinámicos basados en el estado
    final activeColor = isCompleto ? SaasPalette.success : SaasPalette.brand600;
    final rowBg = enabled
        ? (isCompleto
              ? SaasPalette.success.withOpacity(0.05)
              : SaasPalette.brand50)
        : SaasPalette.bgCanvas;
    final rowBorder = enabled
        ? activeColor.withOpacity(0.15)
        : SaasPalette.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rowBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: enabled
                        ? activeColor.withOpacity(0.1)
                        : SaasPalette.bgSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    module.icon,
                    color: enabled ? activeColor : SaasPalette.textTertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    module.label,
                    style: TextStyle(
                      color: enabled
                          ? SaasPalette.textPrimary
                          : SaasPalette.textSecondary,
                      fontSize: 14,
                      fontWeight: enabled ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: activeColor,
                  activeTrackColor: activeColor.withOpacity(0.2),
                  onChanged: (v) => _toggleModule(module.key, v),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 12),
              Divider(color: activeColor.withOpacity(0.1)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LevelChip(
                    label: 'Lectura',
                    icon: Icons.visibility_rounded,
                    active: level == 'lectura',
                    color: SaasPalette.brand600,
                    onTap: () => _setLevel(module.key, 'lectura'),
                  ),
                  const SizedBox(width: 8),
                  _LevelChip(
                    label: 'Completo',
                    icon: Icons.edit_rounded,
                    active: level == 'completo',
                    color: SaasPalette.success,
                    onTap: () => _setLevel(module.key, 'completo'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _LevelChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color.withOpacity(0.3) : SaasPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? color : SaasPalette.textTertiary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : SaasPalette.textTertiary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _LegendBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
