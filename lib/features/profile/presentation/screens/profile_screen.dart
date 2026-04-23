import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../../config/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _ProfileBody());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BODY
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(const RefreshProfile());
    });
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
      listenWhen: (previous, current) {
        if (current is AuthInitial) return true;
        if (current is ChangePasswordFailed) return true;
        if (current is AuthAuthenticated && previous is ChangePasswordLoading) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
        } else if (state is ChangePasswordFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: SaasPalette.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Contraseña actualizada correctamente'),
              backgroundColor: SaasPalette.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: SaasPalette.bgApp,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                const SaasBreadcrumbs(items: ['Inicio', 'Mi Perfil']),
                const SizedBox(height: 16),
                const Text(
                  'Configuración de Perfil',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gestiona tu información personal y niveles de acceso.',
                  style: TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                if (user != null) ...[
                  _AvatarCard(user: user),
                  const SizedBox(height: 16),
                  _InfoCard(user: user),
                  const SizedBox(height: 16),
                  _PermissionsCard(user: user),
                  const SizedBox(height: 16),
                  const _ChangePasswordCard(),
                ] else
                  const SaasEmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Usuario no disponible',
                    subtitle: 'No se pudo cargar la información del usuario.',
                  ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AVATAR CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarCard extends StatelessWidget {
  final User user;
  const _AvatarCard({required this.user});

  String get _initials {
    final parts = user.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return _SaasCard(
      child: Row(
        children: [
          // Avatar con iniciales
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SaasPalette.brand600,
              borderRadius: BorderRadius.circular(20),
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
                    color: SaasPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.username,
                  style: const TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 13,
                  ),
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
    final color = isAdmin ? SaasPalette.warning : SaasPalette.brand600;
    final icon = isAdmin ? Icons.shield_rounded : Icons.badge_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
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

// ─────────────────────────────────────────────────────────────────────────────
//  INFO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final User user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SaasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'INFORMACIÓN DE CUENTA'),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nombre',
            value: user.name,
          ),
          const Divider(color: SaasPalette.border, height: 24),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Correo electrónico',
            value: user.username,
          ),
          const Divider(color: SaasPalette.border, height: 24),
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
            color: SaasPalette.brand600.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: SaasPalette.brand600, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: SaasPalette.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
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

// ─────────────────────────────────────────────────────────────────────────────
//  PERMISSIONS CARD
// ─────────────────────────────────────────────────────────────────────────────
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

    return _SaasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel(text: 'PERMISOS ASIGNADOS'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SaasPalette.brand50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${permisos.length} módulo${permisos.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: SaasPalette.brand600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (permisos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin permisos asignados',
                  style: TextStyle(
                    color: SaasPalette.textTertiary,
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
  final bool isCompleto;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.isCompleto,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCompleto ? SaasPalette.success : SaasPalette.brand600;
    final badgeLabel = isCompleto ? 'Completo' : 'Lectura';
    final badgeIcon = isCompleto
        ? Icons.edit_rounded
        : Icons.visibility_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withOpacity(0.25)),
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

// ─────────────────────────────────────────────────────────────────────────────
//  CHANGE PASSWORD CARD
// ─────────────────────────────────────────────────────────────────────────────
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
    context.read<AuthBloc>().add(
      ChangePasswordRequested(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthBloc>().state is ChangePasswordLoading;

    return _SaasCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(text: 'CAMBIAR CONTRASEÑA'),
            const SizedBox(height: 20),
            _PasswordField(
              controller: _currentCtrl,
              label: 'Contraseña actual',
              hint: 'Ingresa tu contraseña actual',
              visible: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Ingresa tu contraseña actual'
                  : null,
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _newCtrl,
              label: 'Nueva contraseña',
              hint: 'Mínimo 8 caracteres',
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Ingresa la nueva contraseña';
                }
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
                if (v == null || v.isEmpty) {
                  return 'Confirma la nueva contraseña';
                }
                if (v != _newCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SaasPalette.brand600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: SaasPalette.bgSubtle,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SaasPalette.brand600,
                        ),
                      )
                    : const Text(
                        'Cambiar contraseña',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
            color: SaasPalette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: SaasPalette.textTertiary,
              fontSize: 13,
            ),
            filled: true,
            fillColor: SaasPalette.bgApp,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: SaasPalette.brand600,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.danger),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: SaasPalette.textTertiary,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOCAL HELPERS  (específicos de esta pantalla)
// ─────────────────────────────────────────────────────────────────────────────

/// Card contenedor estándar del diseño SaaS (blanco, borde sutil, redondeo 16)
class _SaasCard extends StatelessWidget {
  final Widget child;
  const _SaasCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Etiqueta de sección con barra izquierda de acento
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: SaasPalette.brand600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: SaasPalette.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
