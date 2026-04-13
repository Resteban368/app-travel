import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/pago_realizado.dart';
import '../bloc/pago_realizado_bloc.dart';
import '../../../whatsapp/presentation/bloc/whatsapp_bloc.dart';
import '../../../whatsapp/presentation/bloc/whatsapp_event.dart';
import '../../../whatsapp/presentation/bloc/whatsapp_state.dart';
import '../../../reservas/presentation/bloc/reserva_bloc.dart';
import '../../../reservas/presentation/bloc/reserva_event.dart';
import '../../../reservas/presentation/bloc/reserva_state.dart';
import '../../../reservas/domain/entities/reserva.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class PagoRealizadoFormScreen extends StatefulWidget {
  final PagoRealizado? pago;
  const PagoRealizadoFormScreen({super.key, this.pago});

  @override
  State<PagoRealizadoFormScreen> createState() =>
      _PagoRealizadoFormScreenState();
}

class _PagoRealizadoFormScreenState extends State<PagoRealizadoFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _chatIdCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _proveedorCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _metodoPagoCtrl;
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _fechaDocumentoCtrl;
  late final TextEditingController _urlImagenCtrl;
  String _tipoDocumento = 'Factura';
  bool _isValidated = false;
  bool _wasWhatsappSent = false;
  int? _selectedReservaId;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.pago != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pago;
    _chatIdCtrl = TextEditingController(text: p?.chatId ?? '');
    _montoCtrl = TextEditingController(text: p?.monto.toString() ?? '');
    _proveedorCtrl = TextEditingController(text: p?.proveedorComercio ?? '');
    _nitCtrl = TextEditingController(text: p?.nit ?? '');
    _metodoPagoCtrl = TextEditingController(text: p?.metodoPago ?? '');
    _referenciaCtrl = TextEditingController(text: p?.referencia ?? '');
    _fechaDocumentoCtrl = TextEditingController(text: p?.fechaDocumento ?? '');
    _urlImagenCtrl = TextEditingController(text: p?.urlImagen ?? '');
    _tipoDocumento = p?.tipoDocumento ?? 'Factura';
    _isValidated = p?.isValidated ?? false;
    _selectedReservaId = p?.reservaId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaBloc>().add(const LoadReservas());
    });

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

    _urlImagenCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _chatIdCtrl.dispose();
    _montoCtrl.dispose();
    _proveedorCtrl.dispose();
    _nitCtrl.dispose();
    _metodoPagoCtrl.dispose();
    _referenciaCtrl.dispose();
    _fechaDocumentoCtrl.dispose();
    _urlImagenCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReservaId == null) {
      _showToast('Debes seleccionar una reserva', isError: true);
      return;
    }

    if (_isValidated && (!_isEditing || !(widget.pago?.isValidated ?? false))) {
      _showWhatsAppConfirmation();
      return;
    }
    _executeSave();
  }

  void _executeSave() {
    final pago = PagoRealizado(
      id: _isEditing ? widget.pago!.id : 0,
      chatId: _chatIdCtrl.text.trim(),
      tipoDocumento: _tipoDocumento,
      monto: double.tryParse(_montoCtrl.text) ?? 0.0,
      proveedorComercio: _proveedorCtrl.text.trim(),
      nit: _nitCtrl.text.trim(),
      metodoPago: _metodoPagoCtrl.text.trim(),
      referencia: _referenciaCtrl.text.trim(),
      fechaDocumento: _fechaDocumentoCtrl.text.trim(),
      isValidated: _isValidated,
      urlImagen: _urlImagenCtrl.text.trim(),
      reservaId: _selectedReservaId,
      createdAt: _isEditing ? widget.pago!.createdAt : DateTime.now(),
    );
    if (_isEditing) {
      context.read<PagoRealizadoBloc>().add(UpdatePago(pago));
    } else {
      context.read<PagoRealizadoBloc>().add(CreatePago(pago));
    }
  }

  void _showWhatsAppConfirmation() {
    final messageCtrl = TextEditingController(
      text:
          'Tu pago ya fue validado con éxito. Muchas gracias por preferirnos ✅🙏✨',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PremiumWhatsAppDialog(
        messageCtrl: messageCtrl,
        onConfirm: (msg) {
          final bloc = context.read<WhatsAppBloc>();
          Navigator.pop(ctx);
          bloc.add(SendMessage(to: _chatIdCtrl.text.trim(), body: msg));
        },
      ),
    ).then((_) => messageCtrl.dispose());
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Registro?',
        content:
            'Esta acción es irreversible y eliminará el historial del pago.',
        onConfirm: () {
          context.read<PagoRealizadoBloc>().add(DeletePago(widget.pago!.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('pagosRealizados')
        : true;

    return MultiBlocListener(
      listeners: [
        BlocListener<WhatsAppBloc, WhatsAppState>(
          listener: (context, state) {
            if (state is WhatsAppSending) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const DialogLoadingNetwork(titel: 'Enviando mensaje...'),
              );
            } else if (state is WhatsAppSent) {
              setState(() => _wasWhatsappSent = true);
              Navigator.pop(context);
              _executeSave();
            } else if (state is WhatsAppError) {
              Navigator.pop(context);
              _showToast(state.message, isError: true);
            }
          },
        ),
        BlocListener<PagoRealizadoBloc, PagoRealizadoState>(
          listener: (context, state) {
            if (state is PagoRealizadoSaved) {
              _showToast(
                _wasWhatsappSent ? 'Validado y Notificado' : 'Pago procesado',
              );
              _wasWhatsappSent = false;
              Navigator.pop(context);
            } else if (state is PagoRealizadoError) {
              _showToast(state.message, isError: true);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            _isEditing ? 'Detalle de Pago' : 'Nuevo Pago Manual',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_isEditing && canWrite)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: D.rose),
                onPressed: () => _confirmDelete(context),
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_urlImagenCtrl.text.isNotEmpty)
                              _buildImagePreview(),
                            const SizedBox(height: 24),
                            _buildFormCard(canWrite: canWrite),
                            const SizedBox(height: 40),
                            if (canWrite) _GlowSaveButton(onPressed: _save),
                            const SizedBox(height: 40),
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
      ),
    );
  }

  Widget _buildImagePreview() {
    final directUrl = _getDirectImageUrl(_urlImagenCtrl.text);
    return Container(
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: D.royalBlue.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: D.skyBlue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'COMPROBANTE ADJUNTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (!kIsWeb)
                  Text(
                    'Toque para ampliar',
                    style: TextStyle(color: D.slate600, fontSize: 10),
                  ),
              ],
            ),
          ),
          if (kIsWeb)
            _buildWebImageStub()
          else
            GestureDetector(
              onTap: () => _showFullScreenImage(context),
              child: Image.network(
                directUrl,
                height: 400,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _ImageError(),
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: D.skyBlue),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebImageStub() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.image_rounded, size: 64, color: D.slate600),
          const SizedBox(height: 16),
          const Text(
            'Visualización en Web',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Debido a políticas de seguridad, abre el enlace original.',
            textAlign: TextAlign.center,
            style: TextStyle(color: D.slate400, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionBtn(
                icon: Icons.open_in_new_rounded,
                label: 'Ver Pago',
                onTap: () => _openOriginal(),
              ),
              const SizedBox(width: 12),
              _ActionBtn(
                icon: Icons.download_rounded,
                label: 'Descargar',
                onTap: () => _downloadImage(_urlImagenCtrl.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required bool canWrite}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('INFORMACIÓN DEL PAGO'),
          const SizedBox(height: 20),
          _buildReservaSelector(canWrite: canWrite),
          const SizedBox(height: 10),
          _buildField(
            controller: _chatIdCtrl,
            label: 'Chat - WhatsApp',
            icon: Icons.person_outline_rounded,
            readOnly: !canWrite,
          ),
          const SizedBox(height: 10),
          _buildTypeDropdown(canWrite: canWrite),
          const SizedBox(height: 10),
          _buildField(
            controller: _proveedorCtrl,
            label: 'Comercio / Proveedor',
            icon: Icons.store_rounded,
            readOnly: !canWrite,
          ),
          const SizedBox(height: 20),
          _buildField(
            controller: _nitCtrl,
            label: 'NIT / ID Fiscal',
            icon: Icons.badge_outlined,
            readOnly: !canWrite,
          ),
          const SizedBox(height: 10),
          _buildField(
            controller: _montoCtrl,
            label: 'Monto Recibido',
            icon: Icons.attach_money_rounded,
            isNumeric: true,
            readOnly: !canWrite,
          ),

          const SizedBox(height: 20),
          _buildField(
            controller: _metodoPagoCtrl,
            label: 'Método de Pago',
            icon: Icons.account_balance_wallet_outlined,
            readOnly: !canWrite,
          ),
          const SizedBox(height: 10),
          _buildField(
            controller: _referenciaCtrl,
            label: 'No. Referencia',
            icon: Icons.tag_rounded,
            readOnly: !canWrite,
          ),

          const SizedBox(height: 20),
          _buildField(
            controller: _fechaDocumentoCtrl,
            label: 'Fecha Documento (DD-MM-YYYY)',
            icon: Icons.event_note_rounded,
            readOnly: !canWrite,
          ),
          const SizedBox(height: 20),
          _buildField(
            controller: _urlImagenCtrl,
            label: 'URL del Comprobante',
            icon: Icons.link_rounded,
            readOnly: !canWrite,
          ),
          const SizedBox(height: 32),
          _sectionHeader('VALIDACIÓN Y NOTIFICACIÓN'),
          const SizedBox(height: 16),
          _buildSwitch(canWrite: canWrite),
        ],
      ),
    );
  }

  Widget _buildReservaSelector({required bool canWrite}) {
    return BlocBuilder<ReservaBloc, ReservaState>(
      builder: (context, state) {
        String label = 'Seleccionar Reserva *';
        bool isLoading = state is ReservaLoading;

        if (_selectedReservaId != null) {
          if (state is ReservaLoaded) {
            final r = state.reservas.firstWhere(
              (r) => (int.tryParse(r.id ?? '') == _selectedReservaId),
              orElse: () => Reserva(
                id: _selectedReservaId?.toString(), // Fix: convert int? to String?
                correo: '',
                estado: '',
                fechaCreacion: DateTime.now(),
                fechaActualizacion: DateTime.now(),
                notas: '',
                integrantes: const [],
                idTour: '',
                serviciosIds: [],
              ),
            );
            if (r.idReserva != null || r.id != null) {
              final responsable = r.integrantes.isNotEmpty
                  ? r.integrantes.firstWhere(
                      (i) => i.esResponsable,
                      orElse: () => r.integrantes.first,
                    )
                  : null;
              label = '${r.idReserva ?? 'Reserva #${_selectedReservaId}'} - ${responsable?.nombre ?? r.correo}';
            }
          } else if (_isEditing && widget.pago?.reservaId != null) {
            label = 'Reserva: ${widget.pago!.reservaId}';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reserva Vinculada',
              style: TextStyle(
                color: D.slate400,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: (isLoading || !canWrite) ? null : () => _showReservaPicker(state),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: D.bg.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedReservaId == null ? D.border : D.skyBlue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.airplane_ticket_rounded,
                      color: _selectedReservaId == null
                          ? D.slate600
                          : D.skyBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _selectedReservaId == null
                              ? D.slate400
                              : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: D.skyBlue,
                        ),
                      )
                    else
                      Icon(Icons.arrow_drop_down_rounded, color: D.slate600),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReservaPicker(ReservaState state) {
    if (state is! ReservaLoaded) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: D.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _ReservaSearchPicker(
        reservas: state.reservas,
        onSelected: (r) {
          final parsed = int.tryParse(r.id ?? '');
          debugPrint('[PagoForm] Reserva seleccionada → id: "${r.id}", idReserva: "${r.idReserva}", parsed int: $parsed');
          setState(() {
            _selectedReservaId = parsed;
            if (_chatIdCtrl.text.isEmpty && r.responsableTelefono != null) {
              _chatIdCtrl.text = r.responsableTelefono!;
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildTypeDropdown({required bool canWrite}) {
    final docTypes = ['Factura', 'Recibo', 'Transferencia', 'Ticket', 'Otro'];
    if (!docTypes.contains(_tipoDocumento)) docTypes.add(_tipoDocumento);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo Documento',
          style: TextStyle(
            color: D.slate400,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tipoDocumento,
          dropdownColor: D.surfaceHigh,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(null),
          items: docTypes
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: canWrite ? (v) => setState(() => _tipoDocumento = v!) : null,
        ),
      ],
    );
  }

  Widget _buildSwitch({required bool canWrite}) {
    return Container(
      decoration: BoxDecoration(
        color: D.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: D.border),
      ),
      child: SwitchListTile(
        title: const Text(
          'Validar Pago',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Confirma el recibo y envía comprobante por WhatsApp',
          style: TextStyle(color: D.slate400, fontSize: 12),
        ),
        value: _isValidated,
        activeThumbColor: D.emerald,
        onChanged: canWrite ? (v) => setState(() => _isValidated = v) : null,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: D.slate400,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: isNumeric ? TextInputType.number : null,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(icon),
          validator: (v) => (v == null || v.isEmpty) && label.contains('*')
              ? 'Requerido'
              : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData? icon) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, color: D.slate600, size: 18) : null,
      filled: true,
      fillColor: D.bg.withValues(alpha: 0.3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: D.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: D.skyBlue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
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
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _getDirectImageUrl(String url) {
    if (url.isEmpty) return '';
    final driveRegex = RegExp(r'(?:d\/|id=|uc\?id=)([a-zA-Z0-9_-]{25,})');
    final match = driveRegex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1)!;
      return kIsWeb
          ? 'https://drive.google.com/thumbnail?id=$fileId&sz=w2000-h2000'
          : 'https://lh3.googleusercontent.com/d/$fileId';
    }
    return url;
  }

  Future<void> _openOriginal() async {
    final uri = Uri.parse(_urlImagenCtrl.text.trim());
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _downloadImage(String url) async {
    final driveRegex = RegExp(r'(?:d\/|id=|uc\?id=)([a-zA-Z0-9_-]{25,})');
    final match = driveRegex.firstMatch(url);
    final link = match != null
        ? 'https://drive.google.com/uc?export=download&id=${match.group(1)}'
        : url;
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    }
  }

  void _showFullScreenImage(BuildContext ctx) {
    final url = _getDirectImageUrl(_urlImagenCtrl.text);
    showDialog(
      context: ctx,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? D.rose : D.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PremiumWhatsAppDialog extends StatefulWidget {
  final TextEditingController messageCtrl;
  final Function(String) onConfirm;
  const _PremiumWhatsAppDialog({
    required this.messageCtrl,
    required this.onConfirm,
  });
  @override
  State<_PremiumWhatsAppDialog> createState() => _PremiumWhatsAppDialogState();
}

class _PremiumWhatsAppDialogState extends State<_PremiumWhatsAppDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: D.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: D.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: //agrega la imagen de whatsapp
              Image.asset(
                'assets/images/whatsapp.png',
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirmación de Pago',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notificaremos al cliente sobre su validación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.messageCtrl,
              maxLines: null,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: D.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                hintText: 'Escribe el mensaje...',
              ),
            ),
            const SizedBox(height: 24),
            _buildWPPreview(widget.messageCtrl.text),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: D.slate400),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onConfirm(widget.messageCtrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: D.emerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enviar Notificación',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildWPPreview(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff152d24),
        borderRadius: BorderRadius.circular(12).copyWith(topRight: Radius.zero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.isEmpty ? '...' : text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ahora',
                style: TextStyle(
                  color: D.emerald.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.done_all_rounded, color: D.skyBlue, size: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowSaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GlowSaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagoRealizadoBloc, PagoRealizadoState>(
      builder: (context, state) {
        final isSaving = state is PagoRealizadoSaving;
        return GestureDetector(
          onTap: isSaving ? null : onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSaving
                    ? [D.slate600, D.slate600]
                    : [D.indigo, D.royalBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSaving
                  ? null
                  : [
                      BoxShadow(
                        color: D.indigo.withValues(alpha: 0.4),
                        blurRadius: 20,
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
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'PROCESAR PAGO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: D.skyBlue,
        side: const BorderSide(color: D.skyBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: D.surfaceHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_rounded, color: D.rose, size: 48),
          const SizedBox(height: 12),
          Text(
            'Error al cargar comprobante',
            style: TextStyle(color: D.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

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

class _PremiumConfirmDialog extends StatelessWidget {
  final String title, content;
  final VoidCallback onConfirm;
  const _PremiumConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: D.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: D.rose, size: 54),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(color: D.slate400, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: D.slate400),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: D.rose,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}

class _ReservaSearchPicker extends StatefulWidget {
  final List<Reserva> reservas;
  final Function(Reserva) onSelected;

  const _ReservaSearchPicker({
    required this.reservas,
    required this.onSelected,
  });

  @override
  State<_ReservaSearchPicker> createState() => _ReservaSearchPickerState();
}

class _ReservaSearchPickerState extends State<_ReservaSearchPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.reservas.where((r) {
      final q = _query.toLowerCase();
      final idMatch = (r.idReserva ?? '').toLowerCase().contains(q);
      final correoMatch = r.correo.toLowerCase().contains(q);
      final responsable = r.integrantes.isNotEmpty
          ? r.integrantes.firstWhere(
              (i) => i.esResponsable,
              orElse: () => r.integrantes.first,
            )
          : null;
      final nameMatch = responsable?.nombre.toLowerCase().contains(q) ?? false;
      return idMatch || correoMatch || nameMatch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: D.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: D.slate800,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Seleccionar Reserva',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar id, correo o nombre...',
              hintStyle: TextStyle(color: D.slate600),
              prefixIcon: Icon(Icons.search_rounded, color: D.slate600),
              filled: true,
              fillColor: D.surfaceHigh.withValues(alpha: 0.5),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: D.skyBlue),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron reservas',
                      style: TextStyle(color: D.slate600),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final r = filtered[i];
                      final responsable = r.integrantes.isNotEmpty
                          ? r.integrantes.firstWhere(
                              (i) => i.esResponsable,
                              orElse: () => r.integrantes.first,
                            )
                          : null;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: D.royalBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.airplane_ticket_rounded,
                            color: D.skyBlue,
                          ),
                        ),
                        title: Text(
                          r.idReserva ?? 'Sin ID',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          responsable?.nombre ?? r.correo,
                          style: TextStyle(color: D.slate400, fontSize: 13),
                        ),
                        onTap: () => widget.onSelected(r),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: D.slate800,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
