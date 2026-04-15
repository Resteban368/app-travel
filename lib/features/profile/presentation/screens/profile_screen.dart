import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: -1, child: _ProfileBody());
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(const RefreshProfile());
    });

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    User? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    } else if (authState is ChangePasswordLoading) {
      user = authState.user;
    } else if (authState is ChangePasswordFailed) {
      user = authState.user;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (_) => false,
          );
        } else if (state is ChangePasswordFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: D.rose,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: D.bg,
      body: Stack(
        children: [
          // Background orbs
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context2, child2) => Stack(
              children: [
                Positioned(
                  top: -80 + math.sin(_bgCtrl.value * math.pi * 2) * 40,
                  right: -60 + math.cos(_bgCtrl.value * math.pi * 2) * 30,
                  child: _Orb(
                    color: D.royalBlue.withValues(alpha: 0.08),
                    size: 420,
                  ),
                ),
                Positioned(
                  bottom: -40 + math.cos(_bgCtrl.value * math.pi * 2) * 35,
                  left: -80 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                  child: _Orb(
                    color: D.indigo.withValues(alpha: 0.06),
                    size: 320,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    FadeTransition(
                      opacity: _headerOpacity,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildHeader(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (user != null)
                      FadeTransition(
                        opacity: _contentOpacity,
                        child: Column(
                          children: [
                            _AvatarCard(user: user),
                            const SizedBox(height: 16),
                            _InfoCard(user: user),
                            const SizedBox(height: 16),
                            _PermissionsCard(user: user),
                            const SizedBox(height: 16),
                            const _ChangePasswordCard(),
                          ],
                        ),
                      )
                    else
                      const Center(
                        child: Text(
                          'No se pudo cargar la información del usuario.',
                          style: TextStyle(color: D.slate400),
                        ),
                      ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_rounded,
                color: Colors.white,
                size: 10,
              ),
              SizedBox(width: 6),
              Text(
                'MI CUENTA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Configuración de Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona tu información y niveles de acceso.',
          style: TextStyle(color: D.slate400, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Avatar + nombre card ────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  final User user;
  const _AvatarCard({required this.user});

  String get _initials {
    final parts = user.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Row(
        children: [
          // Avatar con iniciales
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [D.royalBlue, D.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: D.royalBlue.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.username,
                  style: TextStyle(color: D.slate400, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final label = isAdmin ? 'Administrador' : 'Agente';
    final color = isAdmin ? D.gold : D.skyBlue;
    final icon = isAdmin ? Icons.shield_rounded : Icons.badge_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info card ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final User user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('INFORMACIÓN DE CUENTA'),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nombre',
            value: user.name,
          ),
          const Divider(color: D.border, height: 24),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Correo',
            value: user.username,
          ),
          // const Divider(color: D.border, height: 24),
          // _InfoRow(
          //   icon: Icons.badge_outlined,
          //   label: 'ID de usuario',
          //   value: '#${user.id}',
          // ),
          const Divider(color: D.border, height: 24),
          _InfoRow(
            icon: Icons.manage_accounts_outlined,
            label: 'Rol',
            value: user.role == 'admin' ? 'Administrador' : 'Agente',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: D.royalBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: D.skyBlue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: D.slate600,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Permisos card ───────────────────────────────────────────────────────────

class _PermissionsCard extends StatelessWidget {
  final User user;
  const _PermissionsCard({required this.user});

  static const _moduleLabels = <String, String>{
    'dashboard': 'Dashboard',
    'tours': 'Tours y Promociones',
    'sedes': 'Sedes',
    'paymentMethods': 'Métodos de Pago',
    'catalogues': 'Catálogos',
    'faqs': 'Preguntas Frecuentes',
    'services': 'Servicios',
    'politicasReserva': 'Políticas de Reserva',
    'infoEmpresa': 'Información Empresa',
    'pagosRealizados': 'Pagos Realizados',
    'agentes': 'Gestión de Agentes',
    'reservas': 'Gestión de Reservas',
  };

  static const _moduleIcons = <String, IconData>{
    'dashboard': Icons.dashboard_rounded,
    'tours': Icons.tour_rounded,
    'sedes': Icons.store_rounded,
    'paymentMethods': Icons.payment_rounded,
    'catalogues': Icons.picture_as_pdf_rounded,
    'faqs': Icons.help_outline_rounded,
    'services': Icons.settings_suggest_rounded,
    'politicasReserva': Icons.policy_rounded,
    'infoEmpresa': Icons.business_rounded,
    'pagosRealizados': Icons.payments_rounded,
    'agentes': Icons.person_add_alt_1_rounded,
    'reservas': Icons.airplane_ticket_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final permisos = user.permisos;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('PERMISOS ASIGNADOS'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: D.skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${permisos.length} módulo${permisos.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: D.skyBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (permisos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin permisos asignados',
                  style: TextStyle(
                    color: D.slate400,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...permisos.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final label = _moduleLabels[key] ?? key;
              final icon = _moduleIcons[key] ?? Icons.lock_outline_rounded;
              final isCompleto = value == 'completo';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PermissionRow(
                  icon: icon,
                  label: label,
                  level: value,
                  isCompleto: isCompleto,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String level;
  final bool isCompleto;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.level,
    required this.isCompleto,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCompleto ? D.emerald : D.skyBlue;
    final badgeLabel = isCompleto ? 'Completo' : 'Lectura';
    final badgeIcon = isCompleto
        ? Icons.edit_rounded
        : Icons.visibility_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: D.bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: D.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: badgeColor, size: 11),
                const SizedBox(width: 4),
                Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Change Password card ─────────────────────────────────────────────────────

class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard();

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(ChangePasswordRequested(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthBloc>().state is ChangePasswordLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('CAMBIAR CONTRASEÑA'),
            const SizedBox(height: 20),
            _PasswordField(
              controller: _currentCtrl,
              label: 'Contraseña actual',
              hint: 'Ingresa tu contraseña actual',
              visible: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _newCtrl,
              label: 'Nueva contraseña',
              hint: 'Mínimo 8 caracteres',
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _confirmCtrl,
              label: 'Confirmar nueva contraseña',
              hint: 'Repite la nueva contraseña',
              visible: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirma la nueva contraseña';
                if (v != _newCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isLoading
                      ? null
                      : const LinearGradient(
                          colors: [D.royalBlue, D.cyan],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: isLoading ? D.surfaceHigh : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  onPressed: isLoading ? null : _submit,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: D.skyBlue,
                          ),
                        )
                      : const Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.visible,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: D.slate400,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: D.slate600, fontSize: 13),
            filled: true,
            fillColor: D.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: D.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: D.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: D.skyBlue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: D.rose),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: D.rose),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: D.slate400,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _sectionLabel(String text) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 13,
        decoration: BoxDecoration(
          color: D.skyBlue,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          color: D.slate400,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
