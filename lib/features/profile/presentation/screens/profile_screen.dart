import 'dart:convert';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../../config/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../core/theme/theme_cubit.dart';

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
              backgroundColor: context.saas.danger,
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
              backgroundColor: context.saas.success,
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
        backgroundColor: context.saas.bgApp,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                const SaasBreadcrumbs(items: ['Inicio', 'Mi Perfil']),
                const SizedBox(height: 16),
                Text(
                  'Configuración de Perfil',
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tu información personal y niveles de acceso.',
                  style: TextStyle(
                    color: context.saas.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                if (user != null) ...[
                  _AvatarCard(user: user),
                  const SizedBox(height: 16),
                  _InfoCard(user: user),
                  const SizedBox(height: 16),
                  _CotizacionLinkCard(userId: user.id),
                  const SizedBox(height: 16),
                  _PermissionsCard(user: user),
                  const SizedBox(height: 16),
                  if (user.role == 'admin') ...[
                    const _AiAgentCard(),
                    const SizedBox(height: 16),
                  ],
                  const _ThemeCard(),
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
              color: context.saas.brand600,
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
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.username,
                  style: TextStyle(
                    color: context.saas.textSecondary,
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
    final color = isAdmin ? context.saas.warning : context.saas.brand600;
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
          Divider(color: context.saas.border, height: 24),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Correo electrónico',
            value: user.username,
          ),
          Divider(color: context.saas.border, height: 24),
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
            color: context.saas.brand600.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.saas.brand600, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: context.saas.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: context.saas.textPrimary,
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
                  color: context.saas.brand50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${permisos.length} módulo${permisos.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: context.saas.brand600,
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
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sin permisos asignados',
                  style: TextStyle(
                    color: context.saas.textTertiary,
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
    final badgeColor = isCompleto ? context.saas.success : context.saas.brand600;
    final badgeLabel = isCompleto ? 'Completo' : 'Lectura';
    final badgeIcon = isCompleto
        ? Icons.edit_rounded
        : Icons.visibility_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
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
              style: TextStyle(
                color: context.saas.textPrimary,
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
    if (_currentCtrl.text.isEmpty) {
      SaasSnackBar.showWarning(context, 'Debe ingresar su contraseña actual');
      return;
    }
    if (_newCtrl.text.isEmpty) {
      SaasSnackBar.showWarning(context, 'Debe ingresar su nueva contraseña');
      return;
    }
    if (_confirmCtrl.text.isEmpty) {
      SaasSnackBar.showWarning(context, 'Debe confirmar su nueva contraseña');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      SaasSnackBar.showWarning(context, 'Las contraseñas no coinciden');
      return;
    }
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
                  backgroundColor: context.saas.brand600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.saas.bgSubtle,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.saas.brand600,
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
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !visible,
          style: TextStyle(color: context.saas.textPrimary, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.saas.textTertiary,
              fontSize: 13,
            ),
            filled: true,
            fillColor: context.saas.bgApp,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.saas.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.saas.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: context.saas.brand600,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.saas.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.saas.danger),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: context.saas.textTertiary,
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
//  COTIZACIÓN LINK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CotizacionLinkCard extends StatelessWidget {
  final String userId;
  const _CotizacionLinkCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final link = ApiConstants.cotizacionAsesorUrl(userId);

    return _SaasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'MI LINK DE COTIZACIÓN'),
          const SizedBox(height: 8),
          Text(
            'Comparte este enlace con tus clientes para que soliciten una cotización directamente contigo.',
            style: TextStyle(
              color: context.saas.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.saas.bgApp,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.saas.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: context.saas.brand600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    link,
                    style: TextStyle(
                      color: context.saas.brand600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CopyButton(link: link),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String link;
  const _CopyButton({required this.link});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (!mounted) return;
    setState(() => _copied = true);
    SaasSnackBar.showSuccess(context, 'Link copiado al portapapeles');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _copied
          ? Container(
              key: const ValueKey('check'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: context.saas.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.saas.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: context.saas.success),
                  SizedBox(width: 5),
                  Text(
                    'Copiado',
                    style: TextStyle(
                      color: context.saas.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              key: const ValueKey('copy'),
              onTap: _copy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: context.saas.brand600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.saas.brand600.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: context.saas.brand600),
                    SizedBox(width: 5),
                    Text(
                      'Copiar',
                      style: TextStyle(
                        color: context.saas.brand600,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AI AGENT CARD  (solo admin)
// ─────────────────────────────────────────────────────────────────────────────
class _AiAgentCard extends StatefulWidget {
  const _AiAgentCard();

  @override
  State<_AiAgentCard> createState() => _AiAgentCardState();
}

class _AiAgentCardState extends State<_AiAgentCard> {
  static const _aiColor = Color(0xFF7C3AED);
  static const _adminKey = 'agente_trave_baneste_codes';

  bool _active = false;
  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/n8n/workflow/status');
      final response = await http.get(
        uri,
        headers: {'x-admin-key': _adminKey},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _active = (data['active'] as bool?) ?? false;
            _initialized = true;
          });
        }
      }
    } catch (_) {
      // Estado desconocido — el usuario puede togglear manualmente
    }
  }

  Future<void> _toggle(bool value) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/n8n/workflow/toggle');
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': _adminKey,
        },
        body: jsonEncode({'active': value}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          setState(() {
            _active = (data['active'] as bool?) ?? value;
            _initialized = true;
          });
          if (mounted) {
            SaasSnackBar.showSuccess(
              context,
              _active ? 'Agente IA activado' : 'Agente IA desactivado',
            );
          }
          return;
        }
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (_) {
      if (mounted) {
        SaasSnackBar.showError(context, 'Error al cambiar el estado del agente IA');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SaasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'AGENTE IA'),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _active
                  ? _aiColor.withValues(alpha: 0.05)
                  : context.saas.bgSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _active
                    ? _aiColor.withValues(alpha: 0.35)
                    : context.saas.border,
                width: _active ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _aiColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: _aiColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agente de IA',
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _initialized
                            ? (_active
                                ? 'Activo — respondiendo consultas'
                                : 'Inactivo — sin responder')
                            : 'Activa o desactiva el workflow de n8n',
                        style: TextStyle(
                          color: _active && _initialized
                              ? _aiColor
                              : context.saas.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _aiColor,
                    ),
                  )
                else
                  Switch(
                    value: _active,
                    onChanged: _toggle,
                    activeThumbColor: _aiColor,
                    activeTrackColor: _aiColor.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Controla si el agente de IA responde automáticamente a las consultas de clientes vía WhatsApp.',
            style: TextStyle(
              color: context.saas.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
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

// ─────────────────────────────────────────────────────────────────────────────
//  THEME CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    return _SaasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'APARIENCIA'),
          const SizedBox(height: 16),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Column(
                children: [
                  _ThemeOption(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Claro',
                    subtitle: 'Interfaz con fondo blanco',
                    isSelected: themeMode == ThemeMode.light,
                    onTap: () => context.read<ThemeCubit>().setLight(),
                  ),
                  const SizedBox(height: 10),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    label: 'Oscuro',
                    subtitle: 'Interfaz con fondo oscuro',
                    isSelected: themeMode == ThemeMode.dark,
                    onTap: () => context.read<ThemeCubit>().setDark(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.saas.brand600 : context.saas.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.saas.brand50 : context.saas.bgSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.saas.brand600.withValues(alpha: 0.4)
                : context.saas.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? context.saas.brand600
                          : context.saas.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.saas.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.saas.brand600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
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
            color: context.saas.brand600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: context.saas.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
