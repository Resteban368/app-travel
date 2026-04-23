import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:agente_viajes/core/widgets/premium_form_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/di/injection_container.dart';
import '../../../uploads/presentation/bloc/upload_bloc.dart';
import '../../../uploads/presentation/bloc/upload_event.dart';
import '../../../uploads/presentation/bloc/upload_state.dart';
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
  String _countryCode = '+57';
  late final TextEditingController _montoCtrl;
  late final TextEditingController _proveedorCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _metodoPagoCtrl;
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _fechaDocumentoCtrl;
  late final TextEditingController _urlImagenCtrl;
  DateTime? _fechaDocumento;
  String _tipoDocumento = 'Factura';
  late bool _isValidated;
  bool _wasWhatsappSent = false;
  bool _waitingForUploadToSave = false;
  bool _showingLoadingDialog = false;
  // true cuando el usuario confirmó "Validar" vía WA: el CambiarEstadoPago
  // debe dispararse DESPUÉS de que el mensaje WA sea enviado, no antes.
  bool _pendingCambiarEstadoAfterWA = false;
  // Imagen pendiente (seleccionada pero aún no subida)
  Uint8List? _pendingImageBytes;
  String? _pendingImageMimeType;
  String? _pendingImageOriginalName;
  bool _isAnalyzing = false;

  int? _selectedReservaId;

  static const _pagosFolderId = '1hTu072yWKHrxTA0g2p_M6qrkzxt2OqCM';

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Reserva search
  final _reservaSearchCtrl = TextEditingController();
  final _reservaSearchFocus = FocusNode();

  bool get _isEditing => widget.pago != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pago;
    final parsedPhone = _parsePhone(p?.chatId ?? '');
    _countryCode = parsedPhone.$1;
    _chatIdCtrl = TextEditingController(text: parsedPhone.$2);
    _montoCtrl = TextEditingController(text: p?.monto.toString() ?? '');
    _proveedorCtrl = TextEditingController(text: p?.proveedorComercio ?? '');
    _nitCtrl = TextEditingController(text: p?.nit ?? '');
    _metodoPagoCtrl = TextEditingController(text: p?.metodoPago ?? '');
    _referenciaCtrl = TextEditingController(text: p?.referencia ?? '');
    _fechaDocumentoCtrl = TextEditingController(text: p?.fechaDocumento ?? '');
    _fechaDocumento = p?.fechaDocumento != null && p!.fechaDocumento.isNotEmpty
        ? DateTime.tryParse(p.fechaDocumento)
        : null;
    _urlImagenCtrl = TextEditingController(text: p?.urlImagen ?? '');
    _tipoDocumento = p?.tipoDocumento ?? 'Factura';
    _isValidated = p?.isValidated ?? false;
    // _isValidated solo se usa al crear un pago nuevo o al guardar cambios de detalle.
    _selectedReservaId = p?.reservaId;
    if (p?.reservaId != null) {
      _reservaSearchCtrl.text = 'Reserva #${p!.reservaId}';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaBloc>().add(const LoadReservas(limit: 200));
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
    _reservaSearchCtrl.dispose();
    _reservaSearchFocus.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReservaId == null) {
      _showToast('Debes seleccionar una reserva', isError: true);
      return;
    }

    if (_chatIdCtrl.text.trim().isEmpty) {
      _showToast('El número de WhatsApp es requerido', isError: true);
      return;
    }

    if (_isValidated && (!_isEditing || !(widget.pago?.isValidated ?? false))) {
      _showWhatsAppConfirmation();
      return;
    }
    _doSave();
  }

  /// Muestra diálogo de carga, sube imagen si hay pendiente y luego guarda.
  void _doSave() {
    _showLoadingDialog(
      _pendingImageBytes != null ? 'Subiendo imagen...' : 'Procesando pago...',
    );

    if (_pendingImageBytes != null) {
      final phone = _fullChatId;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _mimeToExt(_pendingImageMimeType ?? 'image/jpeg');
      final filename = 'pago_${phone}_$ts.$ext';

      _waitingForUploadToSave = true;
      context.read<UploadBloc>().add(
        UploadFile(
          folderId: _pagosFolderId,
          filename: filename,
          bytes: _pendingImageBytes!,
          mimeType: _pendingImageMimeType ?? 'image/jpeg',
        ),
      );
    } else {
      _executeSave();
    }
  }

  void _showLoadingDialog(String message) {
    _showingLoadingDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogLoadingNetwork(titel: message),
    );
  }

  void _closeLoadingDialog() {
    if (_showingLoadingDialog) {
      _showingLoadingDialog = false;
      Navigator.of(context).pop();
    }
  }

  // Número completo con indicativo (+XX...), ej: +573142266528
  String get _fullChatId => '$_countryCode${_chatIdCtrl.text.trim()}';

  // Intenta detectar el indicativo al cargar un chatId existente.
  // Retorna (countryCode, localNumber).
  static (String, String) _parsePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    // Buscar de más largo a más corto
    final sorted = _kCountryCodes.toList()
      ..sort((a, b) => b.code.length.compareTo(a.code.length));
    for (final cc in sorted) {
      final dial = cc.code.replaceAll('+', '');
      if (digits.startsWith(dial) && digits.length > dial.length) {
        return (cc.code, digits.substring(dial.length));
      }
    }
    return ('+57', digits);
  }

  Widget _buildPhoneField({required bool canWrite}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chat - WhatsApp *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SaasPalette.border),
          ),
          child: Row(
            children: [
              // Selector de indicativo
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _countryCode,
                  dropdownColor: SaasPalette.bgCanvas,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: SaasPalette.textTertiary,
                    size: 18,
                  ),
                  onChanged: canWrite
                      ? (v) => setState(() => _countryCode = v!)
                      : null,
                  items: _kCountryCodes
                      .map(
                        (cc) => DropdownMenuItem(
                          value: cc.code,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${cc.flag} ${cc.code}',
                              style: const TextStyle(
                                color: SaasPalette.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Container(width: 1, height: 24, color: SaasPalette.border),
              // Campo numérico
              Expanded(
                child: TextFormField(
                  controller: _chatIdCtrl,
                  readOnly: !canWrite,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Número sin indicativo',
                    hintStyle: TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFechaDocumento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaDocumento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: SaasPalette.brand600,
            onPrimary: Colors.white,
            surface: SaasPalette.bgCanvas,
            onSurface: SaasPalette.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fechaDocumento = picked);
    }
  }

  Widget _buildFechaDocumentoPicker({required bool canWrite}) {
    return GestureDetector(
      onTap: canWrite ? _pickFechaDocumento : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SaasPalette.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_note_rounded,
              color: SaasPalette.brand600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _fechaDocumento != null
                    ? DateFormat('dd/MM/yyyy').format(_fechaDocumento!)
                    : 'Fecha del Documento *',
                style: TextStyle(
                  color: _fechaDocumento != null
                      ? SaasPalette.textPrimary
                      : SaasPalette.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
            if (canWrite)
              const Icon(
                Icons.calendar_today_rounded,
                color: SaasPalette.textTertiary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  String _mimeToExt(String mime) {
    switch (mime) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }

  void _executeSave() {
    final pago = PagoRealizado(
      id: _isEditing ? widget.pago!.id : 0,
      chatId: _fullChatId,
      tipoDocumento: _tipoDocumento,
      monto: double.tryParse(_montoCtrl.text) ?? 0.0,
      proveedorComercio: _proveedorCtrl.text.trim(),
      nit: _nitCtrl.text.trim(),
      metodoPago: _metodoPagoCtrl.text.trim(),
      referencia: _referenciaCtrl.text.trim(),
      fechaDocumento: _fechaDocumento != null
          ? DateFormat('yyyy-MM-dd').format(_fechaDocumento!)
          : '',
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
          bloc.add(SendMessage(to: _fullChatId, body: msg));
        },
      ),
    ).then((_) => messageCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('pagosRealizados')
        : true;

    return MultiBlocListener(
      listeners: [
        BlocListener<UploadBloc, UploadState>(
          listener: (context, state) {
            if (state is UploadSuccess) {
              setState(() {
                _urlImagenCtrl.text = state.result.url;
                _pendingImageBytes = null;
                _pendingImageMimeType = null;
                _pendingImageOriginalName = null;
              });
              context.read<UploadBloc>().add(const ResetUpload());
              if (_waitingForUploadToSave) {
                _waitingForUploadToSave = false;
                _executeSave();
              }
            } else if (state is UploadError) {
              _closeLoadingDialog();
              _showToast(
                'Error al subir imagen: ${state.message}',
                isError: true,
              );
              context.read<UploadBloc>().add(const ResetUpload());
              _waitingForUploadToSave = false;
            }
          },
        ),
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
              Navigator.pop(context); // cierra diálogo "Enviando mensaje..."
              if (_pendingCambiarEstadoAfterWA) {
                // Flujo: validar pago existente — ahora sí cambiamos estado en BD
                _pendingCambiarEstadoAfterWA = false;
                _showLoadingDialog('Procesando pago...');
                context.read<PagoRealizadoBloc>().add(
                  CambiarEstadoPago(idPago: widget.pago!.id, accion: 'validar'),
                );
              } else {
                // Flujo: crear pago nuevo con validación marcada
                _doSave();
              }
            } else if (state is WhatsAppError) {
              _pendingCambiarEstadoAfterWA = false;
              Navigator.pop(context); // cierra diálogo de carga
              _showToast(state.message, isError: true);
            }
          },
        ),
        BlocListener<PagoRealizadoBloc, PagoRealizadoState>(
          listener: (context, state) {
            if (state is PagoRealizadoSaved) {
              _closeLoadingDialog();
              _showToast(
                _wasWhatsappSent ? 'Validado y Notificado' : 'Pago procesado',
              );
              _wasWhatsappSent = false;
              Navigator.pop(context);
            } else if (state is PagosRealizadosLoaded && _isEditing) {
              // Actualización de estado (validar/rechazar) exitosa — solo cerramos
            } else if (state is PagoRealizadoError) {
              _closeLoadingDialog();
              _showToast(state.message, isError: true);
            }
          },
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing ? 'Detalle de Pago' : 'Nuevo Pago Manual',
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
                                if (_urlImagenCtrl.text.isNotEmpty)
                                  _buildImagePreview(),
                                if (_urlImagenCtrl.text.isNotEmpty)
                                  const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'INFORMACIÓN DEL PAGO',
                                  icon: Icons.receipt_long_rounded,
                                  children: [
                                    _buildReservaSelector(canWrite: canWrite),
                                    const SizedBox(height: 20),
                                    _buildPhoneField(canWrite: canWrite),
                                    const SizedBox(height: 20),
                                    _buildTypeDropdown(canWrite: canWrite),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _proveedorCtrl,
                                      label: 'Comercio / Proveedor *',
                                      icon: Icons.store_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _nitCtrl,
                                      label: 'NIT / ID Fiscal (opcional)',
                                      icon: Icons.badge_outlined,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _montoCtrl,
                                      label: 'Monto Recibido *',
                                      icon: Icons.attach_money_rounded,
                                      isNumeric: true,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _metodoPagoCtrl,
                                      label: 'Método de Pago *',
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _referenciaCtrl,
                                      label: 'No. Referencia *',
                                      icon: Icons.tag_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildFechaDocumentoPicker(
                                      canWrite: canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _urlImagenCtrl,
                                      label: 'URL del Comprobante',
                                      icon: Icons.link_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    if (canWrite && kIsWeb) ...[
                                      const SizedBox(height: 8),
                                      _buildUploadBtn(),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'ESTADO DEL PAGO',
                                  icon: Icons.verified_user_rounded,
                                  children: [
                                    if (_isEditing)
                                      _buildEstadoSection(canWrite: canWrite)
                                    else
                                      _buildSwitch(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 48),

                                if (canWrite)
                                  Builder(
                                    builder: (ctx) =>
                                        BlocBuilder<
                                          PagoRealizadoBloc,
                                          PagoRealizadoState
                                        >(
                                          builder: (context, state) {
                                            return PremiumActionButton(
                                              label: 'PROCESAR PAGO',
                                              icon: Icons.verified_rounded,
                                              isLoading:
                                                  state is PagoRealizadoSaving,
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

  Widget _buildImagePreview() {
    final directUrl = _getDirectImageUrl(_urlImagenCtrl.text);
    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: SaasPalette.brand50,
              border: Border(bottom: BorderSide(color: SaasPalette.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: SaasPalette.brand600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'COMPROBANTE ADJUNTO',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (!kIsWeb)
                  const Text(
                    'Toque para ampliar',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 11,
                    ),
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
                          child: CircularProgressIndicator(
                            color: SaasPalette.brand600,
                          ),
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
          const Icon(
            Icons.image_rounded,
            size: 64,
            color: SaasPalette.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Visualización en Web',
            style: TextStyle(
              color: SaasPalette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Debido a políticas de seguridad, abre el enlace original.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SaasPalette.textSecondary, fontSize: 13),
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

  Widget _buildReservaSelector({required bool canWrite}) {
    return BlocBuilder<ReservaBloc, ReservaState>(
      builder: (context, state) {
        final isLoading = state is ReservaLoading;
        List<Reserva> reservas = [];
        if (state is ReservaLoaded) reservas = state.reservas;

        if (state is ReservaLoaded &&
            _selectedReservaId != null &&
            _reservaSearchCtrl.text.startsWith('Reserva #')) {
          final match = reservas.firstWhere(
            (r) => int.tryParse(r.id ?? '') == _selectedReservaId,
            orElse: () => Reserva(
              id: '',
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
          if (match.id?.isNotEmpty == true) {
            final responsable = match.integrantes.isNotEmpty
                ? match.integrantes.firstWhere(
                    (i) => i.esResponsable,
                    orElse: () => match.integrantes.first,
                  )
                : null;
            final lbl =
                '${match.idReserva ?? 'Reserva #$_selectedReservaId'} - ${responsable?.nombre ?? match.correo}';
            if (_reservaSearchCtrl.text != lbl) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => setState(() => _reservaSearchCtrl.text = lbl),
              );
            }
          }
        }

        final hasSelection = _selectedReservaId != null;

        Future<void> openPicker() async {
          final result = await showDialog<Reserva>(
            context: context,
            builder: (_) => _ReservaPickerDialog(reservas: reservas),
          );
          if (result != null) {
            final parsed = int.tryParse(result.id ?? '');
            final responsable = result.responsable;
            setState(() {
              _selectedReservaId = parsed;
              _reservaSearchCtrl.text =
                  '${result.idReserva ?? 'Reserva #${result.id}'} - ${responsable?.nombre ?? result.correo}';
              if (responsable != null && (responsable.telefono).isNotEmpty) {
                final p = _parsePhone(responsable.telefono);
                _countryCode = p.$1;
                _chatIdCtrl.text = p.$2;
              }
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESERVA VINCULADA *',
              style: TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),

            if (hasSelection)
              // Selected state card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SaasPalette.brand50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SaasPalette.brand600.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SaasPalette.brand600.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.airplane_ticket_rounded,
                        color: SaasPalette.brand600,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _reservaSearchCtrl.text,
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Reserva vinculada',
                            style: TextStyle(
                              color: SaasPalette.brand600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canWrite) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: openPicker,
                        style: TextButton.styleFrom(
                          foregroundColor: SaasPalette.brand600,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _selectedReservaId = null;
                          _reservaSearchCtrl.clear();
                        }),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: SaasPalette.textTertiary,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              )
            else
              // Empty state button
              InkWell(
                onTap: (isLoading || !canWrite) ? null : openPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: SaasPalette.bgCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SaasPalette.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: SaasPalette.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Buscar y seleccionar reserva...',
                          style: TextStyle(
                            color: SaasPalette.textTertiary,
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
                            color: SaasPalette.brand600,
                          ),
                        )
                      else
                        const Icon(
                          Icons.unfold_more_rounded,
                          color: SaasPalette.textTertiary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTypeDropdown({required bool canWrite}) {
    final docTypes = ['Factura', 'Recibo', 'Transferencia', 'Ticket', 'Otro'];
    if (!docTypes.contains(_tipoDocumento)) docTypes.add(_tipoDocumento);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIPO DOCUMENTO *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _tipoDocumento,
          dropdownColor: SaasPalette.bgCanvas,
          isExpanded: true,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: SaasPalette.bgCanvas,
            prefixIcon: const Icon(
              Icons.description_rounded,
              color: SaasPalette.brand600,
              size: 18,
            ),
            hintStyle: const TextStyle(color: SaasPalette.textTertiary),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: docTypes
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: canWrite
              ? (v) => setState(() => _tipoDocumento = v!)
              : null,
        ),
      ],
    );
  }

  String _getEstadoLabel(PagoRealizado? pago) {
    if (pago == null) return 'Pendiente';
    if (pago.isValidated) return 'Validado';
    if (pago.isRechazado) return 'Rechazado';
    return 'Pendiente';
  }

  Color _getEstadoColor(PagoRealizado? pago) {
    if (pago == null) return SaasPalette.textSecondary;
    if (pago.isValidated) return SaasPalette.success;
    if (pago.isRechazado) return SaasPalette.danger;
    return const Color(0xFFF59E0B);
  }

  Widget _buildEstadoSection({required bool canWrite}) {
    final pago = widget.pago;
    final estadoLabel = _getEstadoLabel(pago);
    final estadoColor = _getEstadoColor(pago);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pago?.isValidated == true
                    ? Icons.check_circle_rounded
                    : pago?.isRechazado == true
                    ? Icons.cancel_rounded
                    : Icons.hourglass_empty_rounded,
                color: estadoColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                estadoLabel,
                style: TextStyle(
                  color: estadoColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Motivo de rechazo
        if (pago?.isRechazado == true && pago?.motivoRechazo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SaasPalette.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SaasPalette.danger.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: SaasPalette.danger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pago!.motivoRechazo!,
                    style: const TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Botones de acción (visibles para cualquier usuario autenticado)
        if (true) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (!pago!.isValidated)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarValidar(),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Validar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SaasPalette.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (!pago.isValidated && !pago.isRechazado)
                const SizedBox(width: 12),
              if (!pago.isRechazado)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectionDialog(),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SaasPalette.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _confirmarValidar() {
    if (_selectedReservaId == null) {
      _showToast(
        'Debes asignar una reserva antes de validar el pago',
        isError: true,
      );
      return;
    }
    _showWhatsAppConfirmationForValidar();
  }

  void _showWhatsAppConfirmationForValidar() {
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
          Navigator.pop(ctx);
          // Marcar que al recibir WhatsAppSent debemos cambiar estado en BD.
          // NO disparamos CambiarEstadoPago aquí para evitar la llamada duplicada.
          _pendingCambiarEstadoAfterWA = true;
          _wasWhatsappSent = true;
          context.read<WhatsAppBloc>().add(
            SendMessage(to: _fullChatId, body: msg),
          );
        },
      ),
    ).then((_) => messageCtrl.dispose());
  }

  void _showRejectionDialog() {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SaasPalette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Motivo de Rechazo',
                style: TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Indica el motivo por el que se rechaza este pago.',
                style: TextStyle(
                  color: SaasPalette.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej: Comprobante ilegible, monto incorrecto...',
                  hintStyle: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: SaasPalette.bgSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: SaasPalette.brand600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: SaasPalette.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final motivo = motivoCtrl.text.trim();
                        Navigator.pop(ctx);
                        context.read<PagoRealizadoBloc>().add(
                          CambiarEstadoPago(
                            idPago: widget.pago!.id,
                            accion: 'rechazar',
                            motivoRechazo: motivo.isEmpty ? null : motivo,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SaasPalette.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => motivoCtrl.dispose());
  }

  Widget _buildSwitch({required bool canWrite}) {
    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: SwitchListTile(
        title: const Text(
          'Validar Pago',
          style: TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Confirma el recibo y envía comprobante por WhatsApp',
          style: TextStyle(color: SaasPalette.textTertiary, fontSize: 12),
        ),
        value: _isValidated,
        activeThumbColor: SaasPalette.success,
        activeTrackColor: SaasPalette.success.withValues(alpha: 0.25),
        inactiveThumbColor: SaasPalette.textTertiary,
        inactiveTrackColor: SaasPalette.bgSubtle,
        onChanged: canWrite ? (v) => setState(() => _isValidated = v) : null,
      ),
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

  Future<void> _analyzeDocument(Uint8List bytes, String mimeType) async {
    setState(() => _isAnalyzing = true);
    try {
      final base64Image = base64Encode(bytes);
      final client = sl<http.Client>();
      final response = await client.post(
        Uri.parse('${ApiConstants.kBaseUrl}/v1/analisis-ia/analizar-documento'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: json.encode({
          'imagen_base64': base64Image,
          'mime_type': mimeType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        const docTypes = ['Factura', 'Recibo', 'Transferencia', 'Ticket', 'Otro'];
        setState(() {
          if (data['monto'] != null) {
            _montoCtrl.text = data['monto'].toString();
          }
          if (data['tipo_documento'] != null) {
            final tipo = data['tipo_documento'].toString();
            _tipoDocumento = docTypes.contains(tipo) ? tipo : 'Otro';
          }
          if (data['proveedor_comercio'] != null) {
            _proveedorCtrl.text = data['proveedor_comercio'].toString();
          }
          if (data['nit'] != null) {
            _nitCtrl.text = data['nit'].toString();
          }
          if (data['metodo_pago'] != null) {
            _metodoPagoCtrl.text = data['metodo_pago'].toString();
          }
          if (data['referencia'] != null) {
            _referenciaCtrl.text = data['referencia'].toString();
          }
          if (data['fecha_documento'] != null) {
            final fecha = DateTime.tryParse(data['fecha_documento'].toString());
            if (fecha != null) {
              _fechaDocumento = fecha;
            }
          }
        });
        _showToast('✅ Datos extraídos automáticamente');
      } else {
        String msg = 'No se pudieron extraer los datos del comprobante';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        _showToast(msg, isError: true);
      }
    } catch (_) {
      _showToast('Error al analizar el documento', isError: true);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickFile() async {
    if (!kIsWeb) return;
    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp,image/gif';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;

    final file = input.files![0];
    final mimeType = file.type.isNotEmpty ? file.type : 'image/jpeg';

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final result = reader.result;
    final Uint8List bytes;
    if (result is Uint8List) {
      bytes = result;
    } else if (result is ByteBuffer) {
      bytes = result.asUint8List();
    } else {
      bytes = Uint8List.fromList((result as List).cast<int>());
    }

    if (!mounted) return;
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageMimeType = mimeType;
      _pendingImageOriginalName = file.name;
      // Limpia URL manual si se selecciona un archivo
      _urlImagenCtrl.clear();
    });

    // Analizar automáticamente con IA
    _analyzeDocument(bytes, mimeType);
  }

  Widget _buildUploadBtn() {
    final hasFile = _pendingImageBytes != null;

    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SaasPalette.brand50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaasPalette.brand600.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SaasPalette.brand600,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Analizando comprobante con IA...',
              style: TextStyle(
                color: SaasPalette.brand600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (hasFile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SaasPalette.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SaasPalette.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: SaasPalette.success,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _pendingImageOriginalName ?? 'Imagen seleccionada',
                style: const TextStyle(
                  color: SaasPalette.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _pendingImageBytes = null;
                _pendingImageMimeType = null;
                _pendingImageOriginalName = null;
              }),
              child: const Icon(
                Icons.close_rounded,
                color: SaasPalette.textTertiary,
                size: 18,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _pickFile,
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: const Text('Seleccionar imagen / comprobante'),
        style: OutlinedButton.styleFrom(
          foregroundColor: SaasPalette.brand600,
          side: const BorderSide(color: SaasPalette.brand600),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? SaasPalette.danger : SaasPalette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Reserva Picker Dialog ───────────────────────────────────────────────────

class _ReservaPickerDialog extends StatefulWidget {
  final List<Reserva> reservas;
  const _ReservaPickerDialog({required this.reservas});

  @override
  State<_ReservaPickerDialog> createState() => _ReservaPickerDialogState();
}

class _ReservaPickerDialogState extends State<_ReservaPickerDialog> {
  final _searchCtrl = TextEditingController();
  List<Reserva> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.reservas;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.reservas
          : widget.reservas.where((r) {
              final id = (r.idReserva ?? r.id ?? '').toLowerCase();
              final correo = r.correo.toLowerCase();
              final responsable = r.integrantes.isNotEmpty
                  ? r.integrantes
                        .firstWhere(
                          (i) => i.esResponsable,
                          orElse: () => r.integrantes.first,
                        )
                        .nombre
                        .toLowerCase()
                  : '';
              return id.contains(q) ||
                  correo.contains(q) ||
                  responsable.contains(q);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _estadoColor(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('al dia') || e.contains('al día')) {
      return SaasPalette.success;
    }
    if (e.contains('pendiente')) return SaasPalette.warning;
    if (e.contains('cancelado')) return SaasPalette.danger;
    return SaasPalette.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SaasPalette.border),
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [SaasPalette.brand600, SaasPalette.brand900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.airplane_ticket_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seleccionar Reserva',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${widget.reservas.length} reservas disponibles',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por ID, correo o responsable...',
                  hintStyle: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SaasPalette.textTertiary,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: SaasPalette.bgSubtle,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: SaasPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: SaasPalette.brand600),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtered.length} resultado${_filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            color: SaasPalette.textTertiary,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sin resultados',
                            style: TextStyle(
                              color: SaasPalette.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _filtered.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final r = _filtered[index];
                        final responsable = r.responsable?.nombre;
                        final label = r.idReserva ?? 'Reserva #${r.id}';
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.pop(context, r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: SaasPalette.bgSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: SaasPalette.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SaasPalette.brand50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: SaasPalette.brand600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      responsable ?? 'Sin responsable',
                                      style: const TextStyle(
                                        color: SaasPalette.textPrimary,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    r.estado,
                                    style: TextStyle(
                                      color: _estadoColor(r.estado),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── WhatsApp Dialog ──────────────────────────────────────────────────────────

// ─── Country Code ─────────────────────────────────────────────────────────────

class _CountryCode {
  final String code;
  final String name;
  final String flag;
  const _CountryCode({
    required this.code,
    required this.name,
    required this.flag,
  });
}

const _kCountryCodes = [
  _CountryCode(code: '+57', name: 'Colombia', flag: '🇨🇴'),
  _CountryCode(code: '+1', name: 'EE.UU./Canadá', flag: '🇺🇸'),
  _CountryCode(code: '+34', name: 'España', flag: '🇪🇸'),
  _CountryCode(code: '+52', name: 'México', flag: '🇲🇽'),
  _CountryCode(code: '+54', name: 'Argentina', flag: '🇦🇷'),
  _CountryCode(code: '+55', name: 'Brasil', flag: '🇧🇷'),
  _CountryCode(code: '+56', name: 'Chile', flag: '🇨🇱'),
  _CountryCode(code: '+51', name: 'Perú', flag: '🇵🇪'),
  _CountryCode(code: '+58', name: 'Venezuela', flag: '🇻🇪'),
  _CountryCode(code: '+593', name: 'Ecuador', flag: '🇪🇨'),
  _CountryCode(code: '+507', name: 'Panamá', flag: '🇵🇦'),
  _CountryCode(code: '+506', name: 'Costa Rica', flag: '🇨🇷'),
  _CountryCode(code: '+591', name: 'Bolivia', flag: '🇧🇴'),
  _CountryCode(code: '+595', name: 'Paraguay', flag: '🇵🇾'),
  _CountryCode(code: '+598', name: 'Uruguay', flag: '🇺🇾'),
  _CountryCode(code: '+44', name: 'Reino Unido', flag: '🇬🇧'),
  _CountryCode(code: '+49', name: 'Alemania', flag: '🇩🇪'),
  _CountryCode(code: '+33', name: 'Francia', flag: '🇫🇷'),
];

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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SaasPalette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SaasPalette.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/whatsapp.png',
                width: 48,
                height: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirmación de Pago',
              style: TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notificaremos al cliente sobre su validación por WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SaasPalette.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.messageCtrl,
              maxLines: 4,
              minLines: 2,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: SaasPalette.bgSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: SaasPalette.brand600),
                ),
                hintText: 'Escribe el mensaje...',
                hintStyle: const TextStyle(color: SaasPalette.textTertiary),
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
                      style: TextStyle(
                        color: SaasPalette.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onConfirm(widget.messageCtrl.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: SaasPalette.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Enviar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildWPPreview(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff152d24),
        borderRadius: BorderRadius.circular(16).copyWith(topRight: Radius.zero),
        border: Border.all(color: SaasPalette.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.isEmpty ? '...' : text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ahora',
                style: TextStyle(
                  color: SaasPalette.success.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.done_all_rounded,
                color: SaasPalette.brand600,
                size: 14,
              ),
            ],
          ),
        ],
      ),
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
        foregroundColor: SaasPalette.brand600,
        side: const BorderSide(color: SaasPalette.brand600),
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
      color: SaasPalette.bgSubtle,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: SaasPalette.danger, size: 48),
          SizedBox(height: 12),
          Text(
            'Error al cargar comprobante',
            style: TextStyle(color: SaasPalette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
