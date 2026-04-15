import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/settings/domain/entities/sede.dart';
import '../../../../features/settings/presentation/bloc/sede_bloc.dart';
import '../../domain/entities/catalogue.dart';
import '../bloc/catalogue_bloc.dart';
import '../bloc/catalogue_event.dart';
import '../bloc/catalogue_state.dart';
import '../../../../core/theme/premium_palette.dart';



class CatalogueFormScreen extends StatefulWidget {
  final Catalogue? catalogue;
  const CatalogueFormScreen({super.key, this.catalogue});

  @override
  State<CatalogueFormScreen> createState() => _CatalogueFormScreenState();
}

class _CatalogueFormScreenState extends State<CatalogueFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  int? _selectedSedeId;
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.catalogue != null;

  @override
  void initState() {
    super.initState();
    final c = widget.catalogue;
    _nameCtrl = TextEditingController(text: c?.nombreCatalogue ?? '');
    _urlCtrl = TextEditingController(text: c?.urlArchivo ?? '');
    _selectedSedeId = c?.idSede;
    _isActive = c?.activo ?? true;

    context.read<SedeBloc>().add(LoadSedes());

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSedeId == null) {
      _showToast(context, 'Por favor, selecciona una sede', isError: true);
      return;
    }

    final catalogue = Catalogue(
      idCatalogue: _isEditing ? widget.catalogue!.idCatalogue : 0,
      idSede: _selectedSedeId!,
      nombreCatalogue: _nameCtrl.text.trim(),
      urlArchivo: _urlCtrl.text.trim(),
      activo: _isActive,
      fechaCreacion: _isEditing ? widget.catalogue!.fechaCreacion : DateTime.now(),
    );

    if (_isEditing) {
      context.read<CatalogueBloc>().add(UpdateCatalogue(catalogue));
    } else {
      context.read<CatalogueBloc>().add(CreateCatalogue(catalogue));
    }
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? D.rose : D.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('catalogues')
        : true;

    return BlocListener<CatalogueBloc, CatalogueState>(
      listener: (context, state) {
        if (state is CatalogueSaved) {
          _showToast(context, _isEditing ? 'Catálogo actualizado' : 'Catálogo creado');
          Navigator.pop(context);
        } else if (state is CatalogueError) {
          _showToast(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditing && !canWrite ? 'Ver Catálogo' : (_isEditing ? 'Editar Catálogo' : 'Nuevo Catálogo'),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            // Orbes de fondo
            Positioned(top: -100, right: -50, child: _orb(250, D.royalBlue.withOpacity(0.1))),
            Positioned(bottom: -50, left: -50, child: _orb(200, D.cyan.withOpacity(0.08))),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge de info
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: D.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: D.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: D.skyBlue, size: 16),
                                const SizedBox(width: 8),
                                Text('Completa los detalles del PDF', style: TextStyle(color: D.slate400, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Card del Formulario
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: D.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: D.border),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _nameCtrl,
                                  label: 'Nombre del Catálogo',
                                  icon: Icons.title_rounded,
                                  hint: 'Ej: Guía de Viaje Europa 2024',
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _urlCtrl,
                                  label: 'URL del Archivo (PDF)',
                                  icon: Icons.link_rounded,
                                  hint: 'https://ejemplo.com/archivo.pdf',
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                _buildSedeDropdown(canWrite: canWrite),
                                const SizedBox(height: 20),
                                // Switch premium
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: D.surfaceHigh.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: D.border),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Estado del Catálogo', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: Text(_isActive ? 'Activo y visible' : 'Oculto para usuarios', style: TextStyle(color: D.slate600, fontSize: 12)),
                                    value: _isActive,
                                    activeColor: D.emerald,
                                    activeTrackColor: D.emerald.withOpacity(0.2),
                                    onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Botón de Guardar
                          if (canWrite)
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: BlocBuilder<CatalogueBloc, CatalogueState>(
                                builder: (context, state) {
                                  final isSaving = state is CatalogueSaving;
                                  return ElevatedButton(
                                    onPressed: isSaving ? null : () => _save(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: D.royalBlue,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: D.slate600.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      elevation: 8,
                                      shadowColor: D.royalBlue.withOpacity(0.4),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text(_isEditing ? 'Actualizar Catálogo' : 'Crear Catálogo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: D.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: (v) => v == null || v.isEmpty ? 'Este campo es requerido' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: D.slate600, fontSize: 14),
            prefixIcon: Icon(icon, color: D.skyBlue, size: 20),
            filled: true,
            fillColor: D.surfaceHigh.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.skyBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.rose)),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
      ],
    );
  }

  Widget _buildSedeDropdown({required bool canWrite}) {
    return BlocBuilder<SedeBloc, SedeState>(
      builder: (context, state) {
        if (state is SedeLoading || state is SedeInitial) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Sede / Sucursal', style: TextStyle(color: D.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator(color: D.skyBlue)),
            ],
          );
        }

        List<Sede> sedes = [];
        if (state is SedesLoaded) {
          sedes = state.sedes;
        } else if (state is SedeSaved && state.sedes != null) {
          sedes = state.sedes!;
        } else if (state is SedeSaving && state.sedes != null) {
          sedes = state.sedes!;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sede / Sucursal', style: TextStyle(color: D.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: sedes.any((s) => int.tryParse(s.id) == _selectedSedeId) ? _selectedSedeId : null,
              dropdownColor: D.surfaceHigh,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.business_rounded, color: D.skyBlue, size: 20),
                filled: true,
                fillColor: D.surfaceHigh.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.skyBlue, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              items: sedes.map((s) {
                return DropdownMenuItem(
                  value: int.tryParse(s.id) ?? 0,
                  child: Text(s.nombreSede),
                );
              }).toList(),
              onChanged: canWrite ? (val) => setState(() => _selectedSedeId = val) : null,
              validator: (v) => v == null ? 'Selecciona una sede' : null,
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}
