import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/phone_form_field.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/auth_network_image.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/hotel.dart';
import '../bloc/hotel_bloc.dart';
import '../bloc/hotel_event.dart';
import '../bloc/hotel_state.dart';
import '../../../gallery/presentation/widgets/gallery_picker_dialog.dart';

class HotelFormScreen extends StatefulWidget {
  final Hotel? hotel;
  const HotelFormScreen({super.key, this.hotel});

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _telefonoCtrl;
  String _countryCode = '+57';
  late final TextEditingController _direccionCtrl;
  final _imagenHotelCtrl = TextEditingController();
  late bool _isActive;
  bool _loadingDetail = false;

  List<String> _imagenesHotel = [];
  List<Habitacion> _habitaciones = [];

  // Formulario inline de habitación (nueva o editando)
  bool _showHabitacionForm = false;
  int? _editingIndex;
  String? _habTipoCama;
  final _habCantidadCtrl = TextEditingController();
  final _habPrecioCtrl = TextEditingController();
  final _habImagenCtrl = TextEditingController();
  final _habServicioCtrl = TextEditingController();
  List<String> _habImagenes = [];
  List<String> _habServicios = [];
  final _habObservacionesCtrl = TextEditingController();

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.hotel != null;

  static const _tiposCama = [
    ('sencilla', 'Sencilla'),
    ('doble', 'Doble'),
    ('matrimonial', 'Matrimonial'),
    ('triple', 'Triple'),
    ('suite', 'Suite'),
    ('familiar', 'Familiar'),
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.hotel?.nombre ?? '');
    _ciudadCtrl = TextEditingController(text: widget.hotel?.ciudad ?? '');
    final rawPhone = widget.hotel?.telefono ?? '';
    if (rawPhone.isNotEmpty) {
      final parsed = parsePhone(rawPhone);
      _countryCode = parsed.$1;
      _telefonoCtrl = TextEditingController(text: parsed.$2);
    } else {
      _telefonoCtrl = TextEditingController();
    }
    _direccionCtrl = TextEditingController(text: widget.hotel?.direccion ?? '');
    _isActive = widget.hotel?.isActive ?? true;
    _imagenesHotel = List.from(widget.hotel?.imagenes ?? []);
    _habitaciones = List.from(widget.hotel?.habitaciones ?? []);

    if (_isEditing) {
      _loadingDetail = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HotelBloc>().add(LoadHotelById(widget.hotel!.id!));
      });
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
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
    _ciudadCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _imagenHotelCtrl.dispose();
    _habCantidadCtrl.dispose();
    _habPrecioCtrl.dispose();
    _habImagenCtrl.dispose();
    _habServicioCtrl.dispose();
    _habObservacionesCtrl.dispose();
    super.dispose();
  }

  void _applyHotelDetail(Hotel hotel) {
    if (!mounted) return;
    setState(() {
      _nombreCtrl.text = hotel.nombre;
      _ciudadCtrl.text = hotel.ciudad;
      _direccionCtrl.text = hotel.direccion;
      if (hotel.telefono.isNotEmpty) {
        final parsed = parsePhone(hotel.telefono);
        _countryCode = parsed.$1;
        _telefonoCtrl.text = parsed.$2;
      }
      _isActive = hotel.isActive;
      _imagenesHotel = List.from(hotel.imagenes);
      _habitaciones = List.from(hotel.habitaciones);
      _loadingDetail = false;
    });
  }

  void _addImagenHotel() {
    final url = _imagenHotelCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() => _imagenesHotel.add(url));
      _imagenHotelCtrl.clear();
    }
  }

  void _onSave(BuildContext context) {
    if (_nombreCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'Debe ingresar el nombre del hotel');
      return;
    }
    if (_ciudadCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'Debe ingresar la ciudad');
      return;
    }

    final hotel = Hotel(
      id: widget.hotel?.id,
      nombre: _nombreCtrl.text.trim(),
      ciudad: _ciudadCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim().isEmpty
          ? ''
          : '$_countryCode${_telefonoCtrl.text.trim()}',
      direccion: _direccionCtrl.text.trim(),
      isActive: _isActive,
      imagenes: _imagenesHotel,
      habitaciones: _habitaciones,
    );

    if (_isEditing) {
      context.read<HotelBloc>().add(UpdateHotel(hotel));
    } else {
      context.read<HotelBloc>().add(CreateHotel(hotel));
    }
  }

  void _resetHabitacionForm() {
    _habTipoCama = null;
    _habCantidadCtrl.clear();
    _habPrecioCtrl.clear();
    _habImagenCtrl.clear();
    _habServicioCtrl.clear();
    _habImagenes = [];
    _habServicios = [];
    _habObservacionesCtrl.clear();
    _showHabitacionForm = false;
    _editingIndex = null;
  }

  void _startEditHabitacion(int index) {
    final h = _habitaciones[index];
    setState(() {
      _editingIndex = index;
      _habTipoCama = h.tipoCama;
      _habCantidadCtrl.text = h.cantidad.toString();
      _habPrecioCtrl.text = h.precio.toInt().toString();
      _habImagenes = List.from(h.imagenes);
      _habServicios = List.from(h.servicios);
      _habObservacionesCtrl.text = h.observaciones ?? '';
      _habImagenCtrl.clear();
      _habServicioCtrl.clear();
      _showHabitacionForm = true;
    });
  }

  void _confirmDeleteHabitacion(int index) {
    final label = _HabitacionCard._label(_habitaciones[index].tipoCama);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar habitación?',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Se eliminará la habitación "$label" de la lista.',
          style: TextStyle(color: context.saas.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.saas.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _habitaciones.removeAt(index));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.saas.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _submitHabitacion() {
    if (_habTipoCama == null) {
      SaasSnackBar.showWarning(context, 'Selecciona el tipo de cama');
      return;
    }
    final cant = int.tryParse(_habCantidadCtrl.text.trim());
    if (cant == null || cant <= 0) {
      SaasSnackBar.showWarning(context, 'Ingresa una cantidad válida');
      return;
    }
    final precio = double.tryParse(
      _habPrecioCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (precio == null || precio <= 0) {
      SaasSnackBar.showWarning(context, 'Ingresa un precio válido');
      return;
    }
    setState(() {
      final hab = Habitacion(
        tipoCama: _habTipoCama!,
        cantidad: cant,
        precio: precio,
        imagenes: List.from(_habImagenes),
        servicios: List.from(_habServicios),
        observaciones: _habObservacionesCtrl.text.trim().isEmpty
            ? null
            : _habObservacionesCtrl.text.trim(),
      );
      if (_editingIndex != null) {
        _habitaciones[_editingIndex!] = hab;
      } else {
        _habitaciones.add(hab);
      }
      _resetHabitacionForm();
    });
  }

  Widget _buildImagenesHotelSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'IMÁGENES DEL HOTEL',
            icon: Icons.photo_library_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: _imagenHotelCtrl,
                  label: 'URL de imagen (opcional)',
                  icon: Icons.link_rounded,
                ),
              ),
              const SizedBox(width: 8),
              _GaleriaBtn(
                onPressed: () async {
                  final url = await GalleryPickerDialog.show(
                    context,
                    isAdmin: true,
                  );
                  if (url != null && mounted) {
                    setState(() {
                      if (!_imagenesHotel.contains(url)) {
                        _imagenesHotel.add(url);
                      }
                      _imagenHotelCtrl.clear();
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: TextButton.icon(
                  onPressed: _addImagenHotel,
                  style: TextButton.styleFrom(
                    foregroundColor: context.saas.brand600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'AGREGAR',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_imagenesHotel.isEmpty)
            const PremiumEmptyIndicator(
              msg: 'Sin imágenes — campo opcional.',
              icon: Icons.image_not_supported_rounded,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imagenesHotel
                  .asMap()
                  .entries
                  .map(
                    (e) => _ImagePreviewCard(
                      url: e.value,
                      onRemove: () =>
                          setState(() => _imagenesHotel.removeAt(e.key)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitacionesSection() {
    final fmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'HABITACIONES',
                  icon: Icons.bed_rounded,
                ),
              ),
              if (!_showHabitacionForm)
                TextButton.icon(
                  onPressed: () => setState(() => _showHabitacionForm = true),
                  style: TextButton.styleFrom(foregroundColor: context.saas.brand600),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'AGREGAR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de habitaciones existentes
          if (_habitaciones.isEmpty && !_showHabitacionForm)
            const PremiumEmptyIndicator(
              msg: 'Opcional — agrega los tipos de habitación disponibles.',
              icon: Icons.meeting_room_rounded,
            )
          else
            ..._habitaciones
                .asMap()
                .entries
                .map(
                  (e) => _HabitacionCard(
                    habitacion: e.value,
                    fmt: fmt,
                    onEdit: () => _startEditHabitacion(e.key),
                    onRemove: () => _confirmDeleteHabitacion(e.key),
                  ),
                ),

          // Formulario inline nueva habitación
          if (_showHabitacionForm) ...[
            if (_habitaciones.isNotEmpty) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.saas.bgSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.saas.brand600.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      Icon(
                        Icons.add_home_rounded,
                        color: context.saas.brand600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _editingIndex != null
                              ? 'Editar habitación'
                              : 'Nueva habitación',
                          style: TextStyle(
                            color: context.saas.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _resetHabitacionForm()),
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.saas.textTertiary,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tipo de cama
                  Text(
                    'TIPO DE CAMA *',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _habTipoCama,
                    dropdownColor: context.saas.bgCanvas,
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.bed_rounded,
                        color: context.saas.brand600,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: context.saas.bgCanvas,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    hint: Text(
                      'Selecciona tipo',
                      style: TextStyle(
                        color: context.saas.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                    items: _tiposCama
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.$1,
                            child: Text(o.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _habTipoCama = val),
                  ),
                  const SizedBox(height: 14),

                  // Cantidad y precio
                  Row(
                    children: [
                      Expanded(
                        child: PremiumTextField(
                          controller: _habCantidadCtrl,
                          label: 'Cantidad *',
                          icon: Icons.format_list_numbered_rounded,
                          isNumeric: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumTextField(
                          controller: _habPrecioCtrl,
                          label: 'Precio/noche (COP) *',
                          icon: Icons.attach_money_rounded,
                          isNumeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Imágenes habitación
                  Text(
                    'IMÁGENES (opcional)',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: PremiumTextField(
                          controller: _habImagenCtrl,
                          label: 'URL de imagen',
                          icon: Icons.link_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _GaleriaBtn(
                        onPressed: () async {
                          final url = await GalleryPickerDialog.show(
                            context,
                            isAdmin: true,
                          );
                          if (url != null && mounted) {
                            setState(() {
                              if (!_habImagenes.contains(url)) {
                                _habImagenes.add(url);
                              }
                              _habImagenCtrl.clear();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: IconButton(
                          onPressed: () {
                            final url = _habImagenCtrl.text.trim();
                            if (url.isNotEmpty) {
                              setState(() {
                                _habImagenes.add(url);
                                _habImagenCtrl.clear();
                              });
                            }
                          },
                          icon: Icon(
                            Icons.add_circle_rounded,
                            color: context.saas.brand600,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_habImagenes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _habImagenes
                          .asMap()
                          .entries
                          .map(
                            (e) => _ImagePreviewCard(
                              url: e.value,
                              onRemove: () =>
                                  setState(() => _habImagenes.removeAt(e.key)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Servicios
                  Text(
                    'SERVICIOS (opcional)',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumTextField(
                          controller: _habServicioCtrl,
                          label: 'Ej: wifi, piscina, TV...',
                          icon: Icons.room_service_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: IconButton(
                          onPressed: () {
                            final s = _habServicioCtrl.text.trim();
                            if (s.isNotEmpty) {
                              setState(() {
                                _habServicios.add(s);
                                _habServicioCtrl.clear();
                              });
                            }
                          },
                          icon: Icon(
                            Icons.add_circle_rounded,
                            color: context.saas.brand600,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_habServicios.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _habServicios
                          .asMap()
                          .entries
                          .map(
                            (e) => Chip(
                              label: Text(
                                e.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: context.saas.brand50,
                              side: BorderSide(color: context.saas.border),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => setState(
                                () => _habServicios.removeAt(e.key),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Observaciones
                  PremiumTextField(
                    controller: _habObservacionesCtrl,
                    label: 'Observaciones (opcional)',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _resetHabitacionForm()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.saas.textSecondary,
                            side: BorderSide(color: context.saas.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submitHabitacion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.saas.brand600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _editingIndex != null
                                ? 'GUARDAR CAMBIOS'
                                : 'AGREGAR HABITACIÓN',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HotelBloc, HotelState>(
      listener: (context, state) {
        if (state is HotelDetailLoaded) {
          _applyHotelDetail(state.hotel);
        } else if (state is HotelSaved) {
          SaasSnackBar.showSuccess(
            context,
            _isEditing ? 'Hotel actualizado' : 'Hotel creado',
          );
          Navigator.pop(context);
        } else if (state is HotelError) {
          if (_loadingDetail) setState(() => _loadingDetail = false);
          SaasSnackBar.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            PremiumSliverAppBar(
              title: _isEditing ? 'Editar Hotel' : 'Nuevo Hotel',
              actions: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (_loadingDetail)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: context.saas.brand600),
                      SizedBox(height: 16),
                      Text(
                        'Cargando datos del hotel...',
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.saas.brand50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: context.saas.brand600.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hotel_rounded,
                                    color: context.saas.brand600,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'DATOS DEL HOTEL',
                                    style: TextStyle(
                                      color: context.saas.brand600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            PremiumSectionCard(
                              title: 'INFORMACIÓN GENERAL',
                              icon: Icons.hotel_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _nombreCtrl,
                                  label: 'Nombre del Hotel *',
                                  icon: Icons.hotel_rounded,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'El nombre es requerido'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _ciudadCtrl,
                                  label: 'Ciudad *',
                                  icon: Icons.location_city_rounded,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'La ciudad es requerida'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                PhoneFormField(
                                  controller: _telefonoCtrl,
                                  countryCode: _countryCode,
                                  onCountryCodeChanged: (v) =>
                                      setState(() => _countryCode = v),
                                  label: 'Teléfono (opcional)',
                                  required: false,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _direccionCtrl,
                                  label: 'Dirección (opcional)',
                                  icon: Icons.location_on_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            _buildImagenesHotelSection(),
                            const SizedBox(height: 24),

                            _buildHabitacionesSection(),
                            const SizedBox(height: 24),

                            if (_isEditing) ...[
                              PremiumSectionCard(
                                title: 'ESTADO',
                                icon: Icons.toggle_on_rounded,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: context.saas.bgSubtle,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: context.saas.border,
                                      ),
                                    ),
                                    child: SwitchListTile(
                                      title: Text(
                                        'Hotel Activo',
                                        style: TextStyle(
                                          color: context.saas.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Disponible para asignar a reservas',
                                        style: TextStyle(
                                          color: context.saas.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: _isActive,
                                      activeThumbColor: context.saas.success,
                                      activeTrackColor: context.saas.success
                                          .withValues(alpha: 0.25),
                                      inactiveThumbColor:
                                          context.saas.textTertiary,
                                      inactiveTrackColor: context.saas.bgSubtle,
                                      onChanged: (v) =>
                                          setState(() => _isActive = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            Builder(
                              builder: (ctx) =>
                                  BlocBuilder<HotelBloc, HotelState>(
                                    builder: (context, state) =>
                                        PremiumActionButton(
                                          label: _isEditing
                                              ? 'GUARDAR CAMBIOS'
                                              : 'CREAR HOTEL',
                                          icon: Icons.save_rounded,
                                          isLoading: state is HotelSaving,
                                          onTap: () => _onSave(ctx),
                                        ),
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
      ),
    );
  }
}

// ─── Widgets locales ──────────────────────────────────────────────────────────

class _GaleriaBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _GaleriaBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.saas.brand600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_rounded,
                color: context.saas.brand600, size: 16),
            SizedBox(width: 5),
            Text(
              'Galería',
              style: TextStyle(
                color: context.saas.brand600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _ImagePreviewCard({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.saas.border),
            color: context.saas.bgSubtle,
          ),
          clipBehavior: Clip.antiAlias,
          child: AuthNetworkImage(url: url, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.saas.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageThumbnailReadOnly extends StatelessWidget {
  final String url;
  const _ImageThumbnailReadOnly({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.saas.border),
        color: context.saas.bgSubtle,
      ),
      clipBehavior: Clip.antiAlias,
      child: AuthNetworkImage(url: url, fit: BoxFit.cover),
    );
  }
}

class _HabitacionCard extends StatelessWidget {
  final Habitacion habitacion;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _HabitacionCard({
    required this.habitacion,
    required this.fmt,
    required this.onEdit,
    required this.onRemove,
  });

  static String _label(String tipo) {
    const labels = {
      'sencilla': 'Sencilla',
      'doble': 'Doble',
      'matrimonial': 'Matrimonial',
      'triple': 'Triple',
      'suite': 'Suite',
      'familiar': 'Familiar',
    };
    return labels[tipo] ?? tipo;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bed_rounded,
                      color: context.saas.brand600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _label(habitacion.tipoCama),
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.saas.bgCanvas,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.saas.border),
                      ),
                      child: Text(
                        '${habitacion.cantidad} cupo${habitacion.cantidad != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (habitacion.servicios.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: habitacion.servicios
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.saas.brand600.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: context.saas.brand600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (habitacion.imagenes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: habitacion.imagenes
                        .map((url) => _ImageThumbnailReadOnly(url: url))
                        .toList(),
                  ),
                ],
                if (habitacion.observaciones != null &&
                    habitacion.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 13,
                        color: context.saas.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          habitacion.observaciones!,
                          style: TextStyle(
                            color: context.saas.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(habitacion.precio),
                style: TextStyle(
                  color: context.saas.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_rounded,
                      color: context.saas.brand600,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: context.saas.danger,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
