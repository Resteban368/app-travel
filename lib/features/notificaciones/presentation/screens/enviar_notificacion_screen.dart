import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/features/agentes/domain/entities/agente.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_bloc.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_event.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_state.dart';
import '../bloc/notificacion_bloc.dart';

class EnviarNotificacionScreen extends StatefulWidget {
  const EnviarNotificacionScreen({super.key});

  @override
  State<EnviarNotificacionScreen> createState() =>
      _EnviarNotificacionScreenState();
}

class _EnviarNotificacionScreenState extends State<EnviarNotificacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();

  String _tipo = 'general';
  bool _paraUsuarioEspecifico = false;
  bool _enviando = false;
  Agente? _selectedAgente;

  static const _tipos = [
    ('general', 'General', Icons.campaign_rounded, Color(0xFFD97706)),
    ('sistema', 'Sistema', Icons.settings_rounded, Color(0xFF6B7280)),
    ('cotizacion', 'Cotización', Icons.request_quote_rounded, Color(0xFF7C3AED)),
    ('pago', 'Pago', Icons.payments_rounded, Color(0xFF059669)),
    ('reserva', 'Reserva', Icons.airplane_ticket_rounded, SaasPalette.brand600), // TODO: dark mode
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paraUsuarioEspecifico && _selectedAgente == null) {
      SaasSnackBar.showError(context, 'Selecciona un agente destinatario');
      return;
    }

    final int? usuarioId = _paraUsuarioEspecifico ? _selectedAgente?.id : null;

    setState(() => _enviando = true);
    context.read<NotificacionBloc>().add(
      CrearNotificacion(
        titulo: _tituloCtrl.text.trim(),
        mensaje: _mensajeCtrl.text.trim(),
        tipo: _tipo,
        usuarioId: usuarioId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificacionBloc, NotificacionState>(
      listener: (context, state) {
        if (state is NotificacionCreada) {
          setState(() => _enviando = false);
          SaasSnackBar.showSuccess(context, 'Notificación enviada correctamente');
          _tituloCtrl.clear();
          _mensajeCtrl.clear();
          setState(() {
            _tipo = 'general';
            _paraUsuarioEspecifico = false;
            _selectedAgente = null;
          });
        } else if (state is NotificacionError) {
          setState(() => _enviando = false);
          SaasSnackBar.showError(context, state.mensaje);
        }
      },
      child: Scaffold(
        backgroundColor: context.saas.bgApp,
        appBar: AppBar(
          backgroundColor: context.saas.bgCanvas,
          foregroundColor: context.saas.textPrimary,
          elevation: 0,
          shape: Border(bottom: BorderSide(color: context.saas.border)),
          title: Text(
            'Enviar Notificación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.saas.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Contenido',
                      icon: Icons.edit_rounded,
                      children: [
                        _buildLabel('Título'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _tituloCtrl,
                          style: TextStyle(
                            color: context.saas.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration('Ej. Nueva actualización disponible'),
                          maxLength: 150,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa un título'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Mensaje'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _mensajeCtrl,
                          style: TextStyle(
                            color: context.saas.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _inputDecoration(
                            'Describe el detalle de la notificación...',
                          ),
                          maxLines: 4,
                          maxLength: 500,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Ingresa un mensaje'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Tipo',
                      icon: Icons.label_rounded,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tipos.map((t) {
                            final (value, label, icon, color) = t;
                            final selected = _tipo == value;
                            return GestureDetector(
                              onTap: () => setState(() => _tipo = value),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? color.withValues(alpha: 0.12)
                                      : context.saas.bgApp,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected ? color : context.saas.border,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 15, color: selected ? color : context.saas.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: selected
                                            ? color
                                            : context.saas.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Destinatario',
                      icon: Icons.people_rounded,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DestinatarioOption(
                                label: 'Todos los usuarios',
                                sublabel: 'Notificación general',
                                icon: Icons.groups_rounded,
                                selected: !_paraUsuarioEspecifico,
                                onTap: () => setState(
                                    () => _paraUsuarioEspecifico = false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DestinatarioOption(
                                label: 'Usuario específico',
                                sublabel: 'Por ID de usuario',
                                icon: Icons.person_rounded,
                                selected: _paraUsuarioEspecifico,
                                onTap: () => setState(
                                    () => _paraUsuarioEspecifico = true),
                              ),
                            ),
                          ],
                        ),
                        if (_paraUsuarioEspecifico) ...[
                          const SizedBox(height: 16),
                          _buildLabel('Agente destinatario'),
                          const SizedBox(height: 6),
                          _AgenteSelectorField(
                            selected: _selectedAgente,
                            onTap: () => _openAgentePicker(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _enviando ? null : _enviar,
                        icon: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _enviando ? 'Enviando...' : 'Enviar notificación',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.saas.brand600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              context.saas.brand600.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAgentePicker() async {
    final agenteBloc = context.read<AgenteBloc>();
    if (agenteBloc.state is! AgenteLoaded) {
      agenteBloc.add(LoadAgentes());
    }

    final result = await showDialog<Agente>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: agenteBloc,
        child: const _AgentePickerDialog(),
      ),
    );

    if (result != null) {
      setState(() => _selectedAgente = result);
    }
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: TextStyle(
      color: context.saas.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.saas.textTertiary, fontSize: 13),
    filled: true,
    fillColor: context.saas.bgApp,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      borderSide: BorderSide(color: context.saas.brand600),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.saas.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.saas.danger),
    ),
    counterStyle: TextStyle(color: context.saas.textTertiary, fontSize: 11),
  );
}

// ─── Widgets privados ─────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.saas.brand600),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DestinatarioOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DestinatarioOption({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? context.saas.brand600.withValues(alpha: 0.08)
              : context.saas.bgApp,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? context.saas.brand600 : context.saas.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? context.saas.brand600 : context.saas.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? context.saas.brand600 : context.saas.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                color: context.saas.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campo selector de agente ─────────────────────────────

class _AgenteSelectorField extends StatelessWidget {
  final Agente? selected;
  final VoidCallback onTap;

  const _AgenteSelectorField({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.saas.bgApp,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null ? context.saas.brand600 : context.saas.border,
          ),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: context.saas.brand600.withValues(alpha: 0.15),
                child: Text(
                  selected!.nombre.isNotEmpty
                      ? selected!.nombre[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: context.saas.brand600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected!.nombre,
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      selected!.correo,
                      style: TextStyle(
                        color: context.saas.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Expanded(
                child: Text(
                  'Seleccionar agente...',
                  style: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: context.saas.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diálogo picker de agentes ────────────────────────────

class _AgentePickerDialog extends StatefulWidget {
  const _AgentePickerDialog();

  @override
  State<_AgentePickerDialog> createState() => _AgentePickerDialogState();
}

class _AgentePickerDialogState extends State<_AgentePickerDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.saas.bgCanvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 18,
                    color: context.saas.brand600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Seleccionar agente',
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: context.saas.textSecondary,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o correo...',
                  hintStyle: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: context.saas.textSecondary,
                  ),
                  filled: true,
                  fillColor: context.saas.bgApp,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                    borderSide: BorderSide(color: context.saas.brand600),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: context.saas.border),
            // Lista
            Flexible(
              child: BlocBuilder<AgenteBloc, AgenteState>(
                builder: (context, state) {
                  if (state is AgenteLoading) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.saas.brand600,
                        ),
                      ),
                    );
                  }

                  List<Agente> agentes = [];
                  if (state is AgenteLoaded) agentes = state.agentes;
                  if (state is AgenteSaving) agentes = state.agentes ?? [];
                  if (state is AgenteActionSuccess) agentes = state.agentes;

                  final filtered = _query.isEmpty
                      ? agentes
                      : agentes.where((a) =>
                          a.nombre.toLowerCase().contains(_query) ||
                          a.correo.toLowerCase().contains(_query)).toList();

                  if (filtered.isEmpty) {
                    return SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Sin resultados',
                          style: TextStyle(
                            color: context.saas.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: context.saas.border),
                    itemBuilder: (ctx, i) {
                      final agente = filtered[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, agente),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    context.saas.brand600.withValues(alpha: 0.12),
                                child: Text(
                                  agente.nombre.isNotEmpty
                                      ? agente.nombre[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: context.saas.brand600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      agente.nombre,
                                      style: TextStyle(
                                        color: context.saas.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      agente.correo,
                                      style: TextStyle(
                                        color: context.saas.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!agente.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.saas.danger
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Inactivo',
                                    style: TextStyle(
                                      color: context.saas.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
