import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/agente.dart';
import '../bloc/agente_bloc.dart';
import '../bloc/agente_event.dart';
import '../bloc/agente_state.dart';

// ─── Definición de módulos disponibles ───────────────────────────────────────

class _Module {
  final String key;
  final String label;
  final IconData icon;
  const _Module({required this.key, required this.label, required this.icon});
}

const _modules = [
  // _Module(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
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
  _Module(
    key: 'clientes',
    label: 'Clientes',
    icon: Icons.people_rounded,
  ),
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

  // Permisos: key = module key, value = 'lectura' | 'completo'
  late Map<String, String> _permisos;
  late bool _isActive;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;

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
    _passwordCtrl.dispose();
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

    final agente = Agente(
      id: _isEditing ? widget.agente!.id : 0,
      nombre: _nombreCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      permisos: _permisos,
      isActive: _isActive,
    );

    if (_isEditing) {
      context.read<AgenteBloc>().add(UpdateAgente(agente));
    } else {
      context.read<AgenteBloc>().add(CreateAgente(agente));
    }
  }

  // Dependencias: al activar una clave, estas claves también se activan automáticamente
  static const Map<String, List<String>> _dependencias = {
    'reservas': ['tours', 'pagosRealizados'],
  };

  void _toggleModule(String key, bool enabled) {
    setState(() {
      if (enabled) {
        _permisos[key] = 'lectura';
        // Activar módulos dependientes si aún no están activos
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
            D.emerald,
          );
          Navigator.pop(context);
        } else if (state is AgenteError) {
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
            _isEditing ? 'Editar Agente' : 'Nuevo Agente',
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
                          // ── Datos del agente ──────────────────────────
                          _buildSectionCard('DATOS DEL AGENTE', [
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
                            _buildActiveToggle(),
                            const SizedBox(height: 24),
                            if (!_isEditing)
                              _buildField(
                                controller: _passwordCtrl,
                                label: _isEditing
                                    ? 'Nueva Contraseña (Opcional)'
                                    : 'Contraseña *',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                validator: (v) {
                                  if (!_isEditing && (v == null || v.isEmpty)) {
                                    return 'La contraseña es obligatoria para nuevos agentes';
                                  }
                                  return null;
                                },
                              ),
                          ]),
                          const SizedBox(height: 32),

                          // ── Permisos por módulo ───────────────────────
                          _buildPermissionsCard(),
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

  Widget _buildActiveToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isActive
            ? D.emerald.withValues(alpha: 0.06)
            : D.rose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isActive
              ? D.emerald.withValues(alpha: 0.3)
              : D.rose.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isActive ? D.emerald : D.rose,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTADO DEL AGENTE',
                  style: TextStyle(
                    color: D.slate600,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isActive
                      ? 'Activo — puede iniciar sesión'
                      : 'Inactivo — acceso bloqueado',
                  style: TextStyle(
                    color: _isActive ? D.emerald : D.rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeThumbColor: D.emerald,
            inactiveThumbColor: D.rose,
            inactiveTrackColor: D.rose.withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }

  // ─── Sección de permisos ──────────────────────────────────────────────────

  Widget _buildPermissionsCard() {
    final assignedCount = _permisos.length;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                'PERMISOS DE ACCESO',
                style: TextStyle(
                  color: D.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: D.skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: D.skyBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$assignedCount módulo${assignedCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: D.skyBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Activa los módulos a los que tendrá acceso y define su nivel.',
            style: TextStyle(color: D.slate600, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Leyenda
          Row(
            children: [
              _LegendBadge(
                icon: Icons.visibility_rounded,
                label: 'Lectura: solo ver',
                color: D.skyBlue,
              ),
              const SizedBox(width: 16),
              _LegendBadge(
                icon: Icons.edit_rounded,
                label: 'Completo: ver y editar',
                color: D.emerald,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Filas de módulos
          ...(_modules.map((m) => _buildModuleRow(m))),
        ],
      ),
    );
  }

  Widget _buildModuleRow(_Module module) {
    final enabled = _permisos.containsKey(module.key);
    final level = _permisos[module.key] ?? 'lectura';
    final activeColor = level == 'completo' ? D.emerald : D.skyBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? activeColor.withValues(alpha: 0.06)
              : D.bg.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? activeColor.withValues(alpha: 0.3) : D.border,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                module.label,
                style: TextStyle(
                  color: enabled ? Colors.white : D.slate400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              children: [
                // Ícono del módulo
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (enabled ? activeColor : D.slate600).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    module.icon,
                    color: enabled ? activeColor : D.slate600,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                // Nombre del módulo
                // Expanded(
                //   child: Text(
                //     module.label,
                //     style: TextStyle(
                //       color: enabled ? Colors.white : D.slate400,
                //       fontSize: 13,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
                // Selector lectura / completo (solo si está activo)
                if (enabled) ...[
                  _LevelSelector(
                    level: level,
                    onChanged: (v) => _setLevel(module.key, v),
                  ),
                  const SizedBox(width: 8),
                ],
                // Switch activar/desactivar módulo
                Switch(
                  value: enabled,
                  activeColor: activeColor,
                  onChanged: (v) => _toggleModule(module.key, v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

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
    bool isPassword = false,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        StatefulBuilder(
          builder: (context, setLocal) {
            return TextFormField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: D.slate800, size: 18),
                hintText: hint,
                hintStyle: TextStyle(color: D.slate800, fontSize: 13),
                filled: true,
                fillColor: D.bg.withValues(alpha: 0.3),
                suffixIcon: isPassword || controller == _passwordCtrl
                    ? IconButton(
                        icon: Icon(
                          isPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: D.slate800,
                        ),
                        onPressed: () => setLocal(() => isPassword = !isPassword),
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: D.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: D.skyBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator:
                  validator ??
                  (v) =>
                      (v == null || v.isEmpty) ? 'Este campo es obligatorio' : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AgenteBloc, AgenteState>(
      builder: (context, state) {
        final isSaving = state is AgenteSaving;
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
                  color: D.royalBlue.withValues(alpha: 0.3),
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
                          'GUARDAR AGENTE',
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

// ─── Widget selector de nivel ─────────────────────────────────────────────────

class _LevelSelector extends StatelessWidget {
  final String level;
  final ValueChanged<String> onChanged;
  const _LevelSelector({required this.level, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LevelChip(
          label: 'Lectura',
          icon: Icons.visibility_rounded,
          active: level == 'lectura',
          color: D.skyBlue,
          onTap: () => onChanged('lectura'),
        ),
        const SizedBox(width: 4),
        _LevelChip(
          label: 'Completo',
          icon: Icons.edit_rounded,
          active: level == 'completo',
          color: D.emerald,
          onTap: () => onChanged('completo'),
        ),
      ],
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : D.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? color : D.slate600, size: 11),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? color : D.slate600,
                fontSize: 10,
                fontWeight: FontWeight.w700,
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
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Painter de fondo ─────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withValues(alpha: 0.2);
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
