import 'dart:typed_data';
import 'dart:ui';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:agente_viajes/core/widgets/premium_form_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/premium_palette.dart';
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
  late final TextEditingController _montoCtrl;
  late final TextEditingController _proveedorCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _metodoPagoCtrl;
  late final TextEditingController _referenciaCtrl;
  late final TextEditingController _fechaDocumentoCtrl;
  late final TextEditingController _urlImagenCtrl;
  String _tipoDocumento = 'Factura';
  late bool _isValidated;
  bool _wasWhatsappSent = false;
  bool _waitingForUploadToSave = false;
  bool _showingLoadingDialog = false;
  // Imagen pendiente (seleccionada pero aún no subida)
  Uint8List? _pendingImageBytes;
  String? _pendingImageMimeType;
  String? _pendingImageOriginalName;

  int? _selectedReservaId;

  static const _pagosFolderId = '1eKuJ_dBJkYUJrISlBxDm2d20L_Glxuz_';

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
    _showLoadingDialog(_pendingImageBytes != null ? 'Subiendo imagen...' : 'Procesando pago...');

    if (_pendingImageBytes != null) {
      final phone = _chatIdCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = _mimeToExt(_pendingImageMimeType ?? 'image/jpeg');
      final filename = 'pago_${phone}_$ts.$ext';

      _waitingForUploadToSave = true;
      context.read<UploadBloc>().add(UploadFile(
        folderId: _pagosFolderId,
        filename: filename,
        bytes: _pendingImageBytes!,
        mimeType: _pendingImageMimeType ?? 'image/jpeg',
      ));
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

  String _mimeToExt(String mime) {
    switch (mime) {
      case 'image/png':  return 'png';
      case 'image/webp': return 'webp';
      case 'image/gif':  return 'gif';
      default:           return 'jpg';
    }
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
              _showToast('Error al subir imagen: ${state.message}', isError: true);
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
              Navigator.pop(context); // close WA loading
              _doSave();
            } else if (state is WhatsAppError) {
              Navigator.pop(context); // close loading
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
        backgroundColor: D.bg,
        body: Stack(
          children: [
            const PremiumBackground(),
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing ? 'Detalle de Pago' : 'Nuevo Pago Manual',
                  actions: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: D.white),
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
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
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
                                      PremiumTextField(
                                        controller: _chatIdCtrl,
                                        label: 'Chat - WhatsApp *',
                                        icon: Icons.person_outline_rounded,
                                        readOnly: !canWrite,
                                      ),
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
                                        label: 'NIT / ID Fiscal',
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
                                        icon: Icons
                                            .account_balance_wallet_outlined,
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
                                      PremiumTextField(
                                        controller: _fechaDocumentoCtrl,
                                        label: 'Fecha Documento (DD-MM-YYYY) *',
                                        icon: Icons.event_note_rounded,
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
                                  const SizedBox(height: 100),
                                ],
                              ),
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
        color: D.surfaceHigh.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [D.skyBlue.withOpacity(0.15), Colors.transparent],
                stops: const [0, 0.8],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: D.skyBlue, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'COMPROBANTE ADJUNTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (!kIsWeb)
                  Text(
                    'Toque para ampliar',
                    style: TextStyle(color: D.slate400, fontSize: 11),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Reserva Vinculada *',
                style: TextStyle(color: D.slate400, fontSize: 13),
              ),
            ),
            InkWell(
              onTap: (isLoading || !canWrite)
                  ? null
                  : () async {
                      final result = await showDialog<Reserva>(
                        context: context,
                        builder: (_) =>
                            _ReservaPickerDialog(reservas: reservas),
                      );
                      if (result != null) {
                        final parsed = int.tryParse(result.id ?? '');
                        final responsable = result.integrantes.isNotEmpty
                            ? result.integrantes.firstWhere(
                                (i) => i.esResponsable,
                                orElse: () => result.integrantes.first,
                              )
                            : null;
                        setState(() {
                          _selectedReservaId = parsed;
                          _reservaSearchCtrl.text =
                              '${result.idReserva ?? 'Reserva #${result.id}'} - ${responsable?.nombre ?? result.correo}';
                          if (_chatIdCtrl.text.isEmpty && responsable != null) {
                            _chatIdCtrl.text = responsable.telefono;
                          }
                        });
                      }
                    },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: D.surfaceHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasSelection ? D.skyBlue : D.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.airplane_ticket_rounded,
                      color: hasSelection ? D.skyBlue : D.slate400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasSelection
                            ? _reservaSearchCtrl.text
                            : 'Seleccionar reserva...',
                        style: TextStyle(
                          color: hasSelection ? Colors.white : D.slate400,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    else if (hasSelection && canWrite)
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedReservaId = null;
                          _reservaSearchCtrl.clear();
                        }),
                        child: const Icon(
                          Icons.close_rounded,
                          color: D.slate400,
                          size: 20,
                        ),
                      )
                    else
                      const Icon(
                        Icons.search_rounded,
                        color: D.slate400,
                        size: 20,
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Tipo Documento *',
            style: TextStyle(color: D.slate400, fontSize: 13),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _tipoDocumento,
          dropdownColor: D.surfaceHigh,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: D.surfaceHigh.withOpacity(0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: D.skyBlue),
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
    if (pago == null) return D.slate400;
    if (pago.isValidated) return D.emerald;
    if (pago.isRechazado) return D.rose;
    return const Color(0xFFF59E0B);
  }

  Widget _buildEstadoSection({required bool canWrite}) {
    final pago = widget.pago;
    final estadoLabel = _getEstadoLabel(pago);
    final estadoColor = _getEstadoColor(pago);
    final isPendiente = pago != null && !pago.isValidated && !pago.isRechazado;

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
              color: D.rose.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: D.rose.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: D.rose, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pago!.motivoRechazo!,
                    style: TextStyle(color: D.slate400, fontSize: 13),
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
                      backgroundColor: D.emerald,
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
                      backgroundColor: D.rose,
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
    _showWhatsAppConfirmationForValidar();
  }

  void _showWhatsAppConfirmationForValidar() {
    final messageCtrl = TextEditingController(
      text: 'Tu pago ya fue validado con éxito. Muchas gracias por preferirnos ✅🙏✨',
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
          _wasWhatsappSent = true;
          context.read<PagoRealizadoBloc>().add(
            CambiarEstadoPago(idPago: widget.pago!.id, accion: 'validar'),
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
            color: D.surfaceHigh,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: D.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Motivo de Rechazo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Indica el motivo por el que se rechaza este pago.',
                style: TextStyle(color: D.slate400, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ej: Comprobante ilegible, monto incorrecto...',
                  hintStyle: TextStyle(color: D.slate600, fontSize: 13),
                  filled: true,
                  fillColor: D.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
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
                        style: TextStyle(color: D.slate400, fontWeight: FontWeight.bold),
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
                        backgroundColor: D.rose,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
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
            activeColor: D.emerald,
            activeTrackColor: D.emerald.withOpacity(0.3),
            inactiveThumbColor: D.slate400,
            inactiveTrackColor: D.bg.withOpacity(0.5),
            onChanged: canWrite
                ? (v) => setState(() => _isValidated = v)
                : null,
          ),
        ),
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
  }

  Widget _buildUploadBtn() {
    final hasFile = _pendingImageBytes != null;
    if (hasFile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: D.emerald.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: D.emerald.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: D.emerald, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _pendingImageOriginalName ?? 'Imagen seleccionada',
                style: const TextStyle(color: D.emerald, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _pendingImageBytes = null;
                _pendingImageMimeType = null;
                _pendingImageOriginalName = null;
              }),
              child: const Icon(Icons.close_rounded, color: D.slate400, size: 18),
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
          foregroundColor: D.skyBlue,
          side: const BorderSide(color: D.skyBlue),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        decoration: BoxDecoration(
          color: D.surfaceHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: D.border),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.airplane_ticket_rounded,
                    color: D.skyBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seleccionar Reserva',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: D.slate400,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por ID, correo o responsable...',
                  hintStyle: TextStyle(color: D.slate400, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: D.slate400,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: D.surface.withOpacity(0.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: D.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: D.skyBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: D.slate600, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _filtered.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 4),
                      itemBuilder: (_, index) {
                        final r = _filtered[index];
                        final responsable = r.integrantes.isNotEmpty
                            ? r.integrantes
                                  .firstWhere(
                                    (i) => i.esResponsable,
                                    orElse: () => r.integrantes.first,
                                  )
                                  .nombre
                            : r.correo;
                        final label = r.idReserva ?? 'Reserva #${r.id}';
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context, r),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: D.surface.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: D.skyBlue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: D.skyBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      responsable,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    r.estado,
                                    style: TextStyle(
                                      color: D.slate400,
                                      fontSize: 11,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── WhatsApp Dialog ──────────────────────────────────────────────────────────

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
          color: D.surfaceHigh,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: D.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: D.emerald.withOpacity(0.1),
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
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notificaremos al cliente sobre su validación por WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: D.slate400, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: widget.messageCtrl,
              maxLines: 4,
              minLines: 2,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: D.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Escribe el mensaje...',
                hintStyle: TextStyle(color: D.slate600),
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
                        color: D.slate400,
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
                      backgroundColor: D.emerald,
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
        border: Border.all(color: D.emerald.withOpacity(0.2)),
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
                  color: D.emerald.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.done_all_rounded, color: D.skyBlue, size: 14),
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
      color: D.surfaceHigh.withOpacity(0.5),
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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: D.surfaceHigh,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: D.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: D.rose, size: 64),
            const SizedBox(height: 24),
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
                      style: TextStyle(
                        color: D.slate400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: D.rose,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
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
}
