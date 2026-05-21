import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/core/widgets/saas_ui_components.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:agente_viajes/core/widgets/phone_form_field.dart';
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
import '../../../reservas/domain/entities/integrante.dart';
import '../../../clientes/domain/entities/cliente.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../proveedores/presentation/bloc/proveedor_bloc.dart';
import '../../../proveedores/presentation/bloc/proveedor_event.dart';
import '../../../proveedores/presentation/bloc/proveedor_state.dart';
import '../../../proveedores/domain/entities/proveedor.dart';

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
  String _metodoPago = 'transferencia';
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _clienteNombreCtrl;
  late final TextEditingController _clienteIdentificacionCtrl;
  late final TextEditingController _conceptoCtrl;
  int? _selectedProveedorId;
  late final TextEditingController _fechaDocumentoCtrl;
  late final TextEditingController _urlImagenCtrl;
  DateTime? _fechaDocumento;
  String _tipoDocumento = 'Factura';
  String _entidadTipo = 'reserva';
  late bool _isValidated;
  bool _wasWhatsappSent = false;
  bool _waitingForUploadToSave = false;
  bool _showingLoadingDialog = false;
  bool _isResetting = false;
  bool _isDeleting = false;
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
    final parsedPhone = parsePhone(p?.chatId ?? '');
    _countryCode = parsedPhone.$1;
    _chatIdCtrl = TextEditingController(text: parsedPhone.$2);
    _montoCtrl = TextEditingController(text: p?.monto.toString() ?? '');
    _metodoPago = (p?.metodoPago != null && p!.metodoPago.isNotEmpty) ? p.metodoPago : 'transferencia';
    _referenciaCtrl = TextEditingController(text: p?.referencia ?? '');
    _clienteNombreCtrl = TextEditingController(text: p?.clienteNombre ?? '');
    _clienteIdentificacionCtrl = TextEditingController(text: p?.clienteIdentificacion ?? '');
    _conceptoCtrl = TextEditingController(text: p?.concepto ?? '');
    _selectedProveedorId = p?.proveedorId;
    _fechaDocumentoCtrl = TextEditingController(text: p?.fechaDocumento ?? '');
    _fechaDocumento = p?.fechaDocumento != null && p!.fechaDocumento.isNotEmpty
        ? DateTime.tryParse(p.fechaDocumento)
        : null;
    _urlImagenCtrl = TextEditingController(text: p?.urlImagen ?? '');
    _tipoDocumento = p?.tipoDocumento ?? 'Factura';
    _entidadTipo = p?.entidadTipo ?? 'reserva';
    _isValidated = p?.isValidated ?? false;
    // _isValidated solo se usa al crear un pago nuevo o al guardar cambios de detalle.
    _selectedReservaId = p?.reservaId;
    if (p?.reservaId != null) {
      _reservaSearchCtrl.text = 'Reserva #${p!.reservaId}';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedReservaId != null) {
        context.read<ReservaBloc>().add(
          LoadReservaById(_selectedReservaId.toString()),
        );
      }
      context.read<ReservaBloc>().add(const LoadReservas(limit: 20));
      context.read<ProveedorBloc>().add(const LoadProveedores());
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
    _referenciaCtrl.dispose();
    _clienteNombreCtrl.dispose();
    _clienteIdentificacionCtrl.dispose();
    _conceptoCtrl.dispose();
    _fechaDocumentoCtrl.dispose();
    _urlImagenCtrl.dispose();
    _reservaSearchCtrl.dispose();
    _reservaSearchFocus.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (_entidadTipo == 'reserva' && _selectedReservaId == null) {
      SaasSnackBar.showWarning(context, 'Debes seleccionar una reserva');
      return;
    }
    if (_entidadTipo == 'reserva' && _chatIdCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El número de WhatsApp es requerido');
      return;
    }
    if (_montoCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El monto es requerido');
      return;
    }
    if (_metodoPago != 'efectivo' && _referenciaCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'La referencia es requerida');
      return;
    }
    if (_fechaDocumento == null) {
      SaasSnackBar.showWarning(context, 'La fecha del documento es requerida');
      return;
    }
    if (_isValidated &&
        _entidadTipo == 'reserva' &&
        widget.pago?.conversationId != null &&
        (!_isEditing || !(widget.pago?.isValidated ?? false)) &&
        !_wasWhatsappSent) {
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
    if (_showingLoadingDialog) return;
    _showingLoadingDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => DialogLoadingNetwork(titel: message),
    ).then((_) {
      if (mounted) {
        setState(() {
          _showingLoadingDialog = false;
        });
      }
    });
  }

  void _closeLoadingDialog() {
    if (_showingLoadingDialog && mounted) {
      _showingLoadingDialog = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Número completo con indicativo (+XX...), ej: +573142266528
  String get _fullChatId => '$_countryCode${_chatIdCtrl.text.trim()}';

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
      chatId: _entidadTipo == 'reserva' ? _fullChatId : '',
      tipoDocumento: _tipoDocumento,
      monto: double.tryParse(_montoCtrl.text) ?? 0.0,
      proveedorComercio: '',
      nit: '',
      metodoPago: _metodoPago,
      referencia: _referenciaCtrl.text.trim(),
      fechaDocumento: _fechaDocumento != null
          ? DateFormat('yyyy-MM-dd').format(_fechaDocumento!)
          : '',
      isValidated: _isValidated,
      urlImagen: _urlImagenCtrl.text.trim(),
      reservaId: _entidadTipo == 'reserva' ? _selectedReservaId : null,
      createdAt: _isEditing ? widget.pago!.createdAt : DateTime.now(),
      entidadTipo: _entidadTipo,
      clienteNombre: _clienteNombreCtrl.text.trim().isEmpty
          ? null
          : _clienteNombreCtrl.text.trim(),
      clienteIdentificacion: _clienteIdentificacionCtrl.text.trim().isEmpty
          ? null
          : _clienteIdentificacionCtrl.text.trim(),
      concepto: _conceptoCtrl.text.trim().isEmpty
          ? null
          : _conceptoCtrl.text.trim(),
      proveedorId: _selectedProveedorId,
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
          bloc.add(
            SendMessage(
              conversationId: widget.pago!.conversationId!,
              content: msg,
            ),
          );
        },
        onSkip: () {
          Navigator.pop(ctx);
          _doSave();
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
              SaasSnackBar.showError(context, state.message);
              context.read<UploadBloc>().add(const ResetUpload());
              _waitingForUploadToSave = false;
            }
          },
        ),
        BlocListener<WhatsAppBloc, WhatsAppState>(
          listener: (context, state) {
            if (state is WhatsAppSending) {
              _showLoadingDialog('Enviando mensaje...');
            } else if (state is WhatsAppSent) {
              setState(() => _wasWhatsappSent = true);
              _closeLoadingDialog();
              _doSave();
            } else if (state is WhatsAppError) {
              _closeLoadingDialog();
              SaasSnackBar.showError(context, state.message);
            }
          },
        ),
        BlocListener<PagoRealizadoBloc, PagoRealizadoState>(
          listener: (context, state) {
            if (state is PagoRealizadoSaved) {
              _closeLoadingDialog();
              SaasSnackBar.showSuccess(
                context,
                _isDeleting
                    ? 'Pago eliminado exitosamente'
                    : _isResetting
                        ? 'Pago reseteado exitosamente'
                        : (_wasWhatsappSent
                              ? 'Validado y Notificado'
                              : 'Pago procesado'),
              );
              _wasWhatsappSent = false;
              _isDeleting = false;

              if (_isResetting) {
                _isResetting = false;
                setState(() {
                  _isValidated = false;
                  _selectedReservaId = null;
                  _reservaSearchCtrl.clear();
                });
              } else {
                // Esperamos un frame para que el diálogo se cierre completamente antes de cerrar la pantalla
                Future.delayed(Duration.zero, () {
                  if (mounted) Navigator.pop(context);
                });
              }
            } else if (state is PagosRealizadosLoaded && _isEditing) {
              _closeLoadingDialog();
            } else if (state is PagoRealizadoError) {
              _isResetting = false;
              _closeLoadingDialog();
              SaasSnackBar.showError(context, state.message);
            }
          },
        ),
      ],
      child: PopScope(
        canPop: !_showingLoadingDialog,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _showingLoadingDialog) {
            SaasSnackBar.showWarning(
              context,
              'Por favor espera a que termine el proceso actual',
            );
          }
        },
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
                                    title: 'TIPO DE PAGO',
                                    icon: Icons.receipt_long_rounded,
                                    children: [
                                      _buildEntidadTipoDropdown(canWrite: canWrite),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // ── Campos específicos por tipo ──────────
                                  if (_entidadTipo == 'reserva')
                                    PremiumSectionCard(
                                      title: 'DATOS DE LA RESERVA',
                                      icon: Icons.airplane_ticket_rounded,
                                      children: [
                                        _buildReservaSelector(canWrite: canWrite),
                                        const SizedBox(height: 20),
                                        PhoneFormField(
                                          controller: _chatIdCtrl,
                                          countryCode: _countryCode,
                                          onCountryCodeChanged: (v) =>
                                              setState(() => _countryCode = v),
                                          label: 'WhatsApp del cliente *',
                                          readOnly: !canWrite,
                                        ),
                                      ],
                                    ),

                                  if (_entidadTipo == 'servicio')
                                    PremiumSectionCard(
                                      title: 'DATOS DEL SERVICIO',
                                      icon: Icons.room_service_rounded,
                                      children: [
                                        PremiumTextField(
                                          controller: _conceptoCtrl,
                                          label: 'Concepto del servicio',
                                          icon: Icons.description_rounded,
                                          readOnly: !canWrite,
                                        ),
                                        const SizedBox(height: 20),
                                        PremiumTextField(
                                          controller: _clienteNombreCtrl,
                                          label: 'Nombre del cliente',
                                          icon: Icons.person_rounded,
                                          readOnly: !canWrite,
                                        ),
                                        const SizedBox(height: 20),
                                        PremiumTextField(
                                          controller: _clienteIdentificacionCtrl,
                                          label: 'Identificación del cliente',
                                          icon: Icons.badge_rounded,
                                          readOnly: !canWrite,
                                        ),
                                      ],
                                    ),

                                  if (_entidadTipo == 'proveedor')
                                    PremiumSectionCard(
                                      title: 'DATOS DEL PROVEEDOR',
                                      icon: Icons.store_rounded,
                                      children: [
                                        _buildProveedorSelector(canWrite: canWrite),
                                        const SizedBox(height: 20),
                                        PremiumTextField(
                                          controller: _conceptoCtrl,
                                          label: 'Concepto / descripción',
                                          icon: Icons.description_rounded,
                                          readOnly: !canWrite,
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 16),

                                  // ── Documento común ──────────────────────
                                  PremiumSectionCard(
                                    title: 'DOCUMENTO Y MONTO',
                                    icon: Icons.attach_money_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _montoCtrl,
                                        label: 'Monto *',
                                        icon: Icons.attach_money_rounded,
                                        isNumeric: true,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildMetodoPagoDropdown(canWrite: canWrite),
                                      const SizedBox(height: 20),
                                      _buildFechaDocumentoPicker(
                                        canWrite: canWrite,
                                      ),
                                      if (_metodoPago != 'efectivo') ...[
                                        const SizedBox(height: 20),
                                        PremiumTextField(
                                          controller: _referenciaCtrl,
                                          label: 'No. Referencia *',
                                          icon: Icons.tag_rounded,
                                          readOnly: !canWrite,
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
                                                    state
                                                        is PagoRealizadoSaving,
                                                onTap: () => _save(ctx),
                                              );
                                            },
                                          ),
                                    ),
                                  if (_isEditing) ...[
                                    const SizedBox(height: 16),
                                    BlocBuilder<PagoRealizadoBloc,
                                        PagoRealizadoState>(
                                      builder: (context, state) {
                                        return SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: state
                                                    is PagoRealizadoSaving
                                                ? null
                                                : _confirmDelete,
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: SaasPalette.danger,
                                            ),
                                            label: const Text(
                                              'ELIMINAR PAGO',
                                              style: TextStyle(
                                                color: SaasPalette.danger,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  SaasPalette.danger,
                                              side: const BorderSide(
                                                color: SaasPalette.danger,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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

        Reserva? selectedReserva;
        String lbl = _reservaSearchCtrl.text;

        if (state is ReservaLoaded && _selectedReservaId != null) {
          selectedReserva = reservas.firstWhere(
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
          if (selectedReserva.id?.isNotEmpty == true) {
            final responsable =
                selectedReserva.responsable ??
                (selectedReserva.integrantes.isNotEmpty
                    ? selectedReserva.integrantes.firstWhere(
                        (i) => i.esResponsable,
                        orElse: () => selectedReserva!.integrantes.first,
                      )
                    : null);
            String? respNombre;
            if (responsable is Integrante) {
              respNombre = responsable.nombre;
            } else if (responsable is Cliente) {
              respNombre = responsable.nombre;
            }

            lbl =
                '${selectedReserva.idReserva ?? 'Reserva #$_selectedReservaId'} - ${respNombre ?? selectedReserva.correo}';

            if (_reservaSearchCtrl.text != lbl &&
                !_reservaSearchCtrl.text.contains(' - ')) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => setState(() => _reservaSearchCtrl.text = lbl),
              );
            }
          } else {
            selectedReserva = null;
          }
        }

        final hasSelection = _selectedReservaId != null;

        Future<void> openPicker() async {
          final result = await showDialog<Reserva>(
            context: context,
            builder: (_) => const _ReservaPickerDialog(),
          );
          if (result != null) {
            final parsed = int.tryParse(result.id ?? '');
            final responsable = result.responsable;
            setState(() {
              _selectedReservaId = parsed;
              _reservaSearchCtrl.text =
                  '${result.idReserva ?? 'Reserva #${result.id}'} - ${responsable?.nombre ?? result.correo}';
              if (responsable != null && (responsable.telefono).isNotEmpty) {
                // Solo sobreescribimos si el campo de teléfono está vacío
                if (_chatIdCtrl.text.trim().isEmpty) {
                  final p = parsePhone(responsable.telefono);
                  _countryCode = p.$1;
                  _chatIdCtrl.text = p.$2;
                }
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
                            lbl,
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
                          if (selectedReserva?.responsable?.documento != null)
                            Text(
                              'Documento: ${selectedReserva!.responsable!.documento}',
                              style: const TextStyle(
                                color: SaasPalette.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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

  static const _kMetodosPago = [
    ('transferencia', 'Transferencia', Icons.swap_horiz_rounded),
    ('consignacion', 'Consignación', Icons.account_balance_rounded),
    ('cuenta_ahorro', 'Cuenta de ahorro', Icons.savings_rounded),
    ('efectivo', 'Efectivo', Icons.payments_rounded),
  ];

  Widget _buildMetodoPagoDropdown({required bool canWrite}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MÉTODO DE PAGO *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _metodosPagoValues.contains(_metodoPago) ? _metodoPago : 'transferencia',
          dropdownColor: SaasPalette.bgCanvas,
          isExpanded: true,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: SaasPalette.bgCanvas,
            
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.brand600, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _kMetodosPago
              .map((m) => DropdownMenuItem(
                    value: m.$1,
                    child: Row(
                      children: [
                        Icon(m.$3, size: 16, color: SaasPalette.brand600),
                        const SizedBox(width: 10),
                        Text(m.$2),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: canWrite ? (v) => setState(() => _metodoPago = v!) : null,
        ),
      ],
    );
  }

  static List<String> get _metodosPagoValues =>
      _kMetodosPago.map((m) => m.$1).toList();

  Widget _buildProveedorSelector({required bool canWrite}) {
    return BlocBuilder<ProveedorBloc, ProveedorState>(
      builder: (context, state) {
        final isLoading = state is ProveedorLoading;
        List<Proveedor> proveedores = [];
        if (state is ProveedorLoaded) proveedores = state.proveedores;

        Proveedor? selected;
        if (_selectedProveedorId != null && proveedores.isNotEmpty) {
          try {
            selected = proveedores.firstWhere((p) => p.id == _selectedProveedorId);
          } catch (_) {}
        }

        Future<void> openPicker() async {
          final result = await showDialog<Proveedor>(
            context: context,
            builder: (_) => const _ProveedorPickerDialog(),
          );
          if (result != null) {
            setState(() => _selectedProveedorId = result.id);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROVEEDOR *',
              style: TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedProveedorId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        Icons.store_rounded,
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
                            selected?.nombre ?? 'Proveedor #$_selectedProveedorId',
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (selected != null)
                            Text(
                              '${selected.tipo.toUpperCase()}${selected.nit != null ? ' · ${selected.nit}' : ''}',
                              style: const TextStyle(
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
                            horizontal: 8, vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedProveedorId = null),
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
              InkWell(
                onTap: (isLoading || !canWrite) ? null : openPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14,
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
                          'Buscar y seleccionar proveedor...',
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

  Widget _buildEntidadTipoDropdown({required bool canWrite}) {
    const options = [
      ('reserva', 'Reserva', Icons.airplane_ticket_rounded),
      ('proveedor', 'Proveedor', Icons.store_rounded),
      ('servicio', 'Servicio', Icons.room_service_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIPO DE PAGO *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final (value, label, icon) = opt;
            final selected = _entidadTipo == value;
            return Expanded(
              child: GestureDetector(
                onTap: canWrite
                    ? () => setState(() {
                          _entidadTipo = value;
                          if (value != 'reserva') {
                            _selectedReservaId = null;
                            _reservaSearchCtrl.clear();
                          }
                        })
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(
                    right: value != 'servicio' ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? SaasPalette.brand600
                        : SaasPalette.bgSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? SaasPalette.brand600
                          : SaasPalette.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected
                            ? Colors.white
                            : SaasPalette.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : SaasPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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

        // Botones de acción
        if (canWrite && pago != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (!pago.isValidated)
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
              if (pago.isValidated ||
                  pago.isRechazado ||
                  pago.reservaId != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmarResetear(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Resetear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SaasPalette.textSecondary,
                      side: const BorderSide(
                        color: SaasPalette.border,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _confirmarResetear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: SaasPalette.bgCanvas,
        title: const Text(
          'Resetear Pago',
          style: TextStyle(
            color: SaasPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas resetear este pago? Se desvinculará de la reserva actual y volverá a estado "Pendiente".',
          style: TextStyle(color: SaasPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: SaasPalette.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _isResetting = true;
              _showLoadingDialog('Reseteando pago...');
              context.read<PagoRealizadoBloc>().add(
                CambiarEstadoPago(idPago: widget.pago!.id, accion: 'resetear'),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SaasPalette.brand600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sí, Resetear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarValidar() {
    setState(() {
      _isValidated = true;
    });
    _save(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: 'Eliminar Pago',
        body:
            '¿Deseas eliminar este pago? Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar',
        onConfirm: () {
          Navigator.pop(ctx);
          _isDeleting = true;
          _showLoadingDialog('Eliminando pago...');
          context
              .read<PagoRealizadoBloc>()
              .add(DeletePago(widget.pago!.id));
        },
      ),
    );
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
        const docTypes = [
          'Factura',
          'Recibo',
          'Transferencia',
          'Ticket',
          'Otro',
        ];
        setState(() {
          if (data['monto'] != null) {
            _montoCtrl.text = data['monto'].toString();
          }
          if (data['tipo_documento'] != null) {
            final tipo = data['tipo_documento'].toString();
            _tipoDocumento = docTypes.contains(tipo) ? tipo : 'Otro';
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
        SaasSnackBar.showSuccess(context, 'Datos extraídos automáticamente');
      } else {
        //datos que se estan enviando
        print("MIME: ${mimeType}");
        print("Base64: ${base64Image}");

        print("ERROR: ${response.body}");
        String msg = 'No se pudieron extraer los datos del comprobante';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        SaasSnackBar.showError(context, msg);
      }
    } catch (_) {
      SaasSnackBar.showError(context, 'Error al analizar el documento');
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
          border: Border.all(
            color: SaasPalette.brand600.withValues(alpha: 0.3),
          ),
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
}

// ─── Proveedor Picker Dialog ─────────────────────────────────────────────────

class _ProveedorPickerDialog extends StatefulWidget {
  const _ProveedorPickerDialog();

  @override
  State<_ProveedorPickerDialog> createState() => _ProveedorPickerDialogState();
}

class _ProveedorPickerDialogState extends State<_ProveedorPickerDialog> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorBloc>().add(const LoadProveedores());
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ProveedorBloc>().add(
        LoadProveedores(search: _searchCtrl.text.trim()),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _tipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':
        return SaasPalette.brand600;
      case 'aerolinea':
        return const Color(0xFF6366F1);
      case 'seguro':
        return SaasPalette.success;
      case 'transporte':
      case 'transfer':
      case 'alquiler_vehiculo':
        return const Color(0xFFF59E0B);
      case 'restaurante':
        return const Color(0xFFEF4444);
      case 'agencia':
      case 'tours_operador':
        return const Color(0xFF8B5CF6);
      case 'crucero':
        return const Color(0xFF0EA5E9);
      case 'visa':
      case 'pasaporte':
        return const Color(0xFF10B981);
      case 'guia_turismo':
        return const Color(0xFFF97316);
      case 'parque_atraccion':
        return const Color(0xFFEC4899);
      default:
        return SaasPalette.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProveedorBloc, ProveedorState>(
      builder: (context, state) {
        List<Proveedor> proveedores = [];
        final isLoading = state is ProveedorLoading;
        if (state is ProveedorLoaded) proveedores = state.proveedores;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 580),
            decoration: BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SaasPalette.border),
            ),
            child: Column(
              children: [
                // Header
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
                      const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seleccionar Proveedor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              isLoading
                                  ? 'Buscando...'
                                  : '${proveedores.length} proveedores',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Search
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
                      hintText: 'Buscar por nombre, tipo o NIT...',
                      hintStyle: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: SaasPalette.textTertiary,
                        size: 18,
                      ),
                      suffixIcon: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SaasPalette.brand600,
                                ),
                              ),
                            )
                          : null,
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
                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${proveedores.length} resultado${proveedores.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: (proveedores.isEmpty && !isLoading)
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.store_rounded,
                                  color: SaasPalette.textTertiary, size: 40),
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
                            horizontal: 16, vertical: 4,
                          ),
                          itemCount: proveedores.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, index) {
                            final p = proveedores[index];
                            final tipoColor = _tipoColor(p.tipo);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => Navigator.pop(context, p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12,
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
                                          horizontal: 8, vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tipoColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.tipo.toUpperCase(),
                                          style: TextStyle(
                                            color: tipoColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.nombre,
                                              style: const TextStyle(
                                                color: SaasPalette.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (p.nit != null)
                                              Text(
                                                'NIT: ${p.nit}',
                                                style: const TextStyle(
                                                  color: SaasPalette.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (p.email != null)
                                        const Icon(
                                          Icons.email_rounded,
                                          size: 14,
                                          color: SaasPalette.textTertiary,
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
      },
    );
  }
}

// ─── Reserva Picker Dialog ───────────────────────────────────────────────────

class _ReservaPickerDialog extends StatefulWidget {
  const _ReservaPickerDialog();

  @override
  State<_ReservaPickerDialog> createState() => _ReservaPickerDialogState();
}

class _ReservaPickerDialogState extends State<_ReservaPickerDialog> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _scrollCtrl.addListener(_onScroll);

    // Al abrir el picker, reiniciamos la búsqueda para asegurarnos de tener datos frescos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaBloc>().add(const LoadReservas(page: 1, search: ''));
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      context.read<ReservaBloc>().add(
        LoadReservas(page: _currentPage, search: _searchCtrl.text.trim()),
      );
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final state = context.read<ReservaBloc>().state;
      if (state is ReservaLoaded &&
          !state.hasReachedMax &&
          state is! ReservaLoading) {
        _currentPage++;
        context.read<ReservaBloc>().add(
          LoadReservas(page: _currentPage, search: _searchCtrl.text.trim()),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
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
    return BlocBuilder<ReservaBloc, ReservaState>(
      builder: (context, state) {
        List<Reserva> reservas = [];
        bool isLoading = state is ReservaLoading;
        bool hasMore = false;

        if (state is ReservaLoaded) {
          reservas = state.reservas;
          hasMore = !state.hasReachedMax;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 660),
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                              isLoading
                                  ? 'Buscando...'
                                  : '${reservas.length} reservas encontradas',
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
                      suffixIcon: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SaasPalette.brand600,
                                ),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: SaasPalette.bgSubtle,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: SaasPalette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: SaasPalette.brand600,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${reservas.length} resultado${reservas.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: (reservas.isEmpty && !isLoading)
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
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount: reservas.length + (hasMore ? 1 : 0),
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, index) {
                            if (index >= reservas.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: SaasPalette.brand600,
                                  ),
                                ),
                              );
                            }
                            final r = reservas[index];
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
                                    border: Border.all(
                                      color: SaasPalette.border,
                                    ),
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            color: SaasPalette.brand600,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 13,
                                                  color: SaasPalette.brand600,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  responsable ??
                                                      'Sin responsable',
                                                  style: const TextStyle(
                                                    color:
                                                        SaasPalette.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.tour,
                                                  size: 13,
                                                  color: SaasPalette.brand600,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  r.tour?.name ?? 'Sin tour',
                                                  style: const TextStyle(
                                                    color:
                                                        SaasPalette.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.date_range,
                                                  size: 13,
                                                  color: SaasPalette.brand600,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  //ponemos la fecga en formato dd/MM/yyyy
                                                  DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(
                                                    r.tour?.startDate ??
                                                        DateTime.now(),
                                                  ),
                                                  style: const TextStyle(
                                                    color:
                                                        SaasPalette.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ],
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
      },
    );
  }
}

// ─── WhatsApp Dialog ──────────────────────────────────────────────────────────

class _PremiumWhatsAppDialog extends StatefulWidget {
  final TextEditingController messageCtrl;
  final Function(String) onConfirm;
  final VoidCallback onSkip;
  const _PremiumWhatsAppDialog({
    required this.messageCtrl,
    required this.onConfirm,
    required this.onSkip,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/whatsapp.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Enviar Mensaje',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.onSkip(),

              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: SaasPalette.brand600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: Colors.transparent),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Validar sin enviar mensaje',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
