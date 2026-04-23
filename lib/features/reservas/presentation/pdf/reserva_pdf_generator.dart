import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import '../../domain/entities/reserva.dart';
import '../../../pagos_realizados/domain/entities/pago_realizado.dart';
import '../../../service/domain/entities/service.dart';

/// Generates a detailed PDF for a [Reserva].
///
/// Usage:
///   final bytes = await ReservaPdfGenerator.generate(reserva, pagos: _pagos, servicios: _services);
class ReservaPdfGenerator {
  // ─── Brand colors ───────────────────────────────────────────────
  static final _brand = PdfColor.fromHex('2563EB');
  static final _brandDark = PdfColor.fromHex('1E3A8A');
  static final _brandLight = PdfColor.fromHex('EFF6FF');
  static final _textPrimary = PdfColor.fromHex('1A1A1A');
  static final _textSecondary = PdfColor.fromHex('57534E');
  static final _textTertiary = PdfColor.fromHex('78716C');
  static final _success = PdfColor.fromHex('16A34A');
  static final _warning = PdfColor.fromHex('D97706');
  static final _warningLight = PdfColor.fromHex('FEF3C7');
  static final _danger = PdfColor.fromHex('DC2626');
  static final _border = PdfColor.fromHex('E5E7EB');
  static final _bgSubtle = PdfColor.fromHex('F5F5F4');

  static final _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  // ─── Caches to speed up generation ───────────────────────────────
  static pw.MemoryImage? _cachedLogo;
  static pw.Font? _cachedBold;
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedOblique;

  static String _fmt(double? val) =>
      val != null ? _currency.format(val) : '\$0';

  // ─── Public API ─────────────────────────────────────────────────

  static Future<Uint8List> generate(
    Reserva reserva, {
    List<PagoRealizado> pagos = const [],
    List<Service> servicios = const [],
  }) async {
    final doc = pw.Document();

    // Load logo (with caching)
    pw.MemoryImage? logoImage;
    if (_cachedLogo != null) {
      logoImage = _cachedLogo;
    } else {
      try {
        // Usamos rootBundle para todas las plataformas, es más seguro y evita problemas de CORS en Web
        final data = await rootBundle.load('assets/logo-empresa/logo-empresa.jpeg');
        _cachedLogo = pw.MemoryImage(data.buffer.asUint8List());
        logoImage = _cachedLogo;
        debugPrint('[PDF] Logo cargado desde assets con éxito');
      } catch (e) {
        debugPrint('[PDF] Error cargando logo desde assets: $e');
      }
    }

    // Load Fonts (with caching)
    pw.Font bold;
    pw.Font regular;
    pw.Font oblique;

    if (_cachedBold != null &&
        _cachedRegular != null &&
        _cachedOblique != null) {
      bold = _cachedBold!;
      regular = _cachedRegular!;
      oblique = _cachedOblique!;
    } else {
      try {
        _cachedBold = await PdfGoogleFonts.robotoBold();
        _cachedRegular = await PdfGoogleFonts.robotoRegular();
        _cachedOblique = await PdfGoogleFonts.robotoItalic();

        bold = _cachedBold!;
        regular = _cachedRegular!;
        oblique = _cachedOblique!;
      } catch (_) {
        bold = pw.Font.helveticaBold();
        regular = pw.Font.helvetica();
        oblique = pw.Font.helveticaOblique();
      }
    }

    // Resolve services for this reservation
    final reservaServicios = servicios
        .where((s) => reserva.serviciosIds.contains(s.id))
        .toList();

    final displayPagos = pagos.isNotEmpty
        ? pagos
        : (reserva.pagosValidados ?? []);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (ctx) =>
            _buildPageHeader(ctx, logoImage, reserva, bold, regular),
        footer: (ctx) => _buildPageFooter(ctx, logoImage, bold, regular),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildResponsableSection(reserva, bold, regular),
          pw.SizedBox(height: 16),
          _buildIntegrantesSection(reserva, bold, regular),
          pw.SizedBox(height: 16),
          if (reserva.tipoReserva == 'tour') ...[
            _buildTourSection(reserva, bold, regular, oblique),
            pw.SizedBox(height: 16),
          ] else ...[
            _buildVuelosSection(reserva, bold, regular),
            pw.SizedBox(height: 16),
            if (reserva.hoteles.isNotEmpty) ...[
              _buildHotelesSection(reserva, bold, regular),
              pw.SizedBox(height: 16),
            ],
          ],
          if (reservaServicios.isNotEmpty ||
              reserva.serviciosIds.isNotEmpty) ...[
            _buildServiciosSection(reserva, reservaServicios, bold, regular),
            pw.SizedBox(height: 16),
          ],
          if (reserva.notas.isNotEmpty) ...[
            _buildNotasSection(reserva, bold, regular),
            pw.SizedBox(height: 16),
          ],
          if (displayPagos.isNotEmpty) ...[
            _buildPagosSection(displayPagos, bold, regular),
            pw.SizedBox(height: 16),
          ],
          _buildResumenSection(reserva, reservaServicios, bold, regular),
          if (reserva.tipoReserva == 'tour') ...[
            pw.SizedBox(height: 20),
            _buildCondicionesSection(
              reserva.tour?.name ?? 'el tour',
              bold,
              regular,
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ─── Page Header ────────────────────────────────────────────────

  static pw.Widget _buildPageHeader(
    pw.Context ctx,
    pw.MemoryImage? logo,
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
  ) {
    final isFirstPage = ctx.pageNumber == 1;
    if (!isFirstPage) {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Reserva ${reserva.idReserva ?? ''}',
              style: pw.TextStyle(
                font: bold,
                fontSize: 9,
                color: _textTertiary,
              ),
            ),
            pw.Text(
              'Travel Tours Florencia',
              style: pw.TextStyle(fontSize: 9, color: _textTertiary),
            ),
          ],
        ),
      );
    }

    // Full company header on first page
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _brandDark,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo card on the left
              pw.Container(
                width: 75,
                height: 75,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                ),
                child: pw.Center(
                  child: logo != null
                      ? pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        )
                      : pw.Text(
                          'TT',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 24,
                            color: _brand,
                          ),
                        ),
                ),
              ),
              pw.SizedBox(width: 20),
              // Company info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Travel Tours Florencia',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'GERENTE: Daniela Agatón Soto',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor(1, 1, 1, 0.75),
                      ),
                    ),
                    pw.Text(
                      'NIT: 10065025016',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor(1, 1, 1, 0.75),
                      ),
                    ),
                    pw.Text(
                      'CRA 7 N 16A 08 BRR 7 DE AGOSTO',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor(1, 1, 1, 0.75),
                      ),
                    ),
                    pw.Text(
                      '3142266528',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor(1, 1, 1, 0.75),
                      ),
                    ),
                    pw.Text(
                      'infoasesoras2022@gmail.com',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor(1, 1, 1, 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              // Reservation info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'RESERVA',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      color: PdfColor(1, 1, 1, 0.75),
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    reserva.idReserva ?? 'RES-000000',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor(1, 1, 1, 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: pw.Row(
            children: [
              pw.Text(
                'Asesor: ',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: _textTertiary,
                  font: bold,
                ),
              ),
              pw.Text(
                reserva.agente?.nombre ?? reserva.correo,
                style: pw.TextStyle(fontSize: 8, color: _textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Page Footer ────────────────────────────────────────────────

  static pw.Widget _buildPageFooter(
    pw.Context ctx,
    pw.MemoryImage? logoImage,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            children: [
              if (logoImage != null)
                pw.Container(
                  height: 25,
                  width: 25,
                  margin: const pw.EdgeInsets.only(right: 8),
                  child: pw.Image(logoImage),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Travel Tours Florencia · NIT: 10065025016',
                    style: pw.TextStyle(fontSize: 7, font: bold, color: _brand),
                  ),
                  pw.Text(
                    'Dirección: CRA 7 N 16A 08 BRR 7 DE AGOSTO',
                    style: pw.TextStyle(fontSize: 6, color: _textTertiary),
                  ),
                  pw.Text(
                    'Tel: 3142266528 · Correo: INFOASESORAS2022@GMAIL.COM',
                    style: pw.TextStyle(fontSize: 6, color: _textTertiary),
                  ),
                ],
              ),
            ],
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: _textTertiary),
          ),
        ],
      ),
    );
  }

  // ─── Section title helper ────────────────────────────────────────

  static pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        color: _brandLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: _brand, width: 3)),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(font: bold, fontSize: 11, color: _brandDark),
        ),
      ),
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: bold,
                fontSize: 9,
                color: _textSecondary,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _card({required pw.Widget child}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: child,
    );
  }

  // ─── Reserva Info ────────────────────────────────────────────────

  // ─── Responsable ─────────────────────────────────────────────────

  static pw.Widget _buildResponsableSection(
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
  ) {
    final resp = reserva.responsable;
    final integranteResp = reserva.integrantes.isNotEmpty
        ? reserva.integrantes.firstWhere(
            (i) => i.esResponsable,
            orElse: () => reserva.integrantes.first,
          )
        : null;

    final nombre = resp?.nombre ?? integranteResp?.nombre ?? 'No especificado';
    final documento = resp != null
        ? '${resp.tipoDocumento.toUpperCase()}: ${resp.documento}'
        : (integranteResp != null
              ? '${integranteResp.tipoDocumento.toUpperCase()}: ${integranteResp.documento}'
              : '-');
    final telefono = resp?.telefono ?? integranteResp?.telefono ?? '-';
    final correo = resp?.correo ?? reserva.correo;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Responsable de la Reserva', bold),
        _card(
          child: pw.Column(
            children: [
              _infoRow('Nombre completo:', nombre, bold, regular),
              _infoRow('Documento:', documento, bold, regular),
              _infoRow('Teléfono:', telefono, bold, regular),
              _infoRow('Correo electrónico:', correo, bold, regular),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Integrantes ─────────────────────────────────────────────────

  static pw.Widget _buildIntegrantesSection(
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
  ) {
    final all = reserva.integrantes;
    if (all.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Viajeros (${all.length} pax)', bold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _bgSubtle),
              children: [
                _tableHeader('Nombre', bold),
                _tableHeader('Documento', bold),
                _tableHeader('Teléfono', bold),
                _tableHeader('Fecha Nac.', bold),
              ],
            ),
            ...all.map(
              (i) => pw.TableRow(
                children: [
                  _tableCell(i.nombre, regular),
                  _tableCell(
                    '${i.tipoDocumento.toUpperCase()}: ${i.documento}',
                    regular,
                  ),
                  _tableCell(i.telefono, regular),
                  _tableCell(
                    i.fechaNacimiento != null
                        ? DateFormat('dd/MM/yyyy').format(i.fechaNacimiento!)
                        : '—',
                    regular,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tour ────────────────────────────────────────────────────────

  static pw.Widget _buildTourSection(
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
    pw.Font oblique,
  ) {
    final tour = reserva.tour;
    if (tour == null) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Información del Tour', bold),
          _card(
            child: pw.Text(
              'Tour ID: ${reserva.idTour ?? 'No especificado'}',
              style: pw.TextStyle(fontSize: 9, color: _textSecondary),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Información del Tour', bold),
        _card(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Nombre del tour:', tour.name, bold, regular),
              _infoRow('Agencia:', tour.agency, bold, regular),
              _infoRow(
                'Fecha inicio:',
                DateFormat('dd MMMM yyyy', 'es').format(tour.startDate),
                bold,
                regular,
              ),
              _infoRow(
                'Fecha fin:',
                DateFormat('dd MMMM yyyy', 'es').format(tour.endDate),
                bold,
                regular,
              ),
              if (tour.departurePoint.isNotEmpty)
                _infoRow(
                  'Punto de salida:',
                  tour.departurePoint,
                  bold,
                  regular,
                ),
              if (tour.departureTime.isNotEmpty)
                _infoRow('Hora de salida:', tour.departureTime, bold, regular),
              if (tour.arrival.isNotEmpty)
                _infoRow('Destino/Llegada:', tour.arrival, bold, regular),
              _infoRow('Precio por persona:', _fmt(tour.price), bold, regular),
            ],
          ),
        ),

        // Inclusions / Exclusions
        if (tour.inclusions.isNotEmpty || tour.exclusions.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (tour.inclusions.isNotEmpty) ...[
                _sectionTitle('LO QUE INCLUYE EL PLAN', bold),
                pw.SizedBox(height: 4),
                ...tour.inclusions.map(
                  (inc) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '- ',
                          style: pw.TextStyle(fontSize: 9, color: _success),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            inc,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tour.exclusions.isNotEmpty) pw.SizedBox(height: 10),
              ],
              if (tour.exclusions.isNotEmpty) ...[
                _sectionTitle('NO INCLUYE', bold),
                pw.SizedBox(height: 4),
                ...tour.exclusions.map(
                  (exc) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '- ',
                          style: pw.TextStyle(fontSize: 9, color: _danger),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            exc,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],

        // Itinerary
        if (tour.itinerary.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _sectionTitle('ITINERARIO DEL TOUR', bold),
          pw.SizedBox(height: 4),
          pw.Text(
            'Los tiempos aquí descritos son estimados. El coordinador de viaje podrá modificarlos en caso de fuerza mayor, ejerciendo su autoridad para asegurar el correcto desarrollo del itinerario.',
            style: pw.TextStyle(
              font: regular,
              fontSize: 8.5,
              color: _textSecondary,
              lineSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: _border, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _bgSubtle),
                children: [
                  _tableHeader('Día', bold),
                  _tableHeader('Título', bold),
                  _tableHeader('Descripción', bold),
                ],
              ),
              ...tour.itinerary.map(
                (day) => pw.TableRow(
                  children: [
                    _tableCell('Día ${day.dayNumber}', bold, color: _brand),
                    _tableCell(day.title, bold),
                    _tableCell(day.description, regular),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Vuelos ──────────────────────────────────────────────────────

  static pw.Widget _buildVuelosSection(
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
  ) {
    if (reserva.vuelos.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Vuelos (${reserva.vuelos.length})', bold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.8),
            1: const pw.FlexColumnWidth(1.3),
            2: const pw.FlexColumnWidth(1.3),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1.8),
            6: const pw.FlexColumnWidth(1.3),
            7: const pw.FlexColumnWidth(1.3),
            8: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _bgSubtle),
              children: [
                _tableHeader('Aerolínea', bold),
                _tableHeader('N° Vuelo', bold),
                _tableHeader('N° Reserva', bold),
                _tableHeader('Origen', bold),
                _tableHeader('Destino', bold),
                _tableHeader('Fecha Salida', bold),
                _tableHeader('Clase', bold),
                _tableHeader('Tipo', bold),
                _tableHeader('Precio', bold),
              ],
            ),
            ...reserva.vuelos.map(
              (v) => pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: v.tipoVuelo == 'vuelta'
                      ? PdfColor.fromHex('FFFBEB')
                      : PdfColors.white,
                ),
                children: [
                  _tableCell(v.aerolinea?.nombre ?? '-', regular),
                  _tableCell(v.numeroVuelo, bold),
                  _tableCell(v.reservaVuelo, regular),
                  _tableCell(v.origen, regular),
                  _tableCell(v.destino, regular),
                  _tableCell(
                    '${v.fechaSalida}\n${v.horaSalida} > ${v.horaLlegada}',
                    regular,
                  ),
                  _tableCell(v.clase, regular),
                  _tableCellWidget(
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: v.tipoVuelo == 'vuelta'
                            ? _warningLight
                            : _brandLight,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        v.tipoVuelo == 'vuelta' ? 'VUELTA' : 'IDA',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 8,
                          color: v.tipoVuelo == 'vuelta' ? _warning : _brand,
                        ),
                      ),
                    ),
                  ),
                  _tableCell(
                    _fmt(v.precio),
                    bold,
                    color: _textPrimary,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Hoteles ─────────────────────────────────────────────────────

  static pw.Widget _buildHotelesSection(
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Hoteles (${reserva.hoteles.length})', bold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _bgSubtle),
              children: [
                _tableHeader('Hotel', bold),
                _tableHeader('Ciudad', bold),
                _tableHeader('N° Reserva', bold),
                _tableHeader('Check-in', bold),
                _tableHeader('Check-out', bold),
                _tableHeader('Valor', bold),
              ],
            ),
            ...reserva.hoteles.map(
              (h) => pw.TableRow(
                children: [
                  _tableCell(h.hotel?.nombre ?? 'Hotel ${h.hotelId}', bold),
                  _tableCell(h.hotel?.ciudad ?? '-', regular),
                  _tableCell(h.numeroReserva, regular),
                  _tableCell(h.fechaCheckin, regular),
                  _tableCell(h.fechaCheckout, regular),
                  _tableCell(_fmt(h.valor), bold, align: pw.TextAlign.right),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  // ─── Servicios ───────────────────────────────────────────────────

  static pw.Widget _buildServiciosSection(
    Reserva reserva,
    List<Service> serviciosList,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Servicios Adicionales', bold),
        _card(
          child: pw.Column(
            children: serviciosList.isNotEmpty
                ? serviciosList
                      .map(
                        (s) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Text(
                                    '- ',
                                    style: pw.TextStyle(
                                      color: _brand,
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    s.name,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (s.cost != null)
                                pw.Text(
                                  _fmt(s.cost),
                                  style: pw.TextStyle(
                                    font: bold,
                                    fontSize: 9,
                                    color: _textPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList()
                : reserva.serviciosIds
                      .map(
                        (id) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                '- ',
                                style: pw.TextStyle(color: _brand, fontSize: 9),
                              ),
                              pw.Text(
                                'Servicio #$id',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
          ),
        ),
      ],
    );
  }

  // ─── Notas ───────────────────────────────────────────────────────

  static pw.Widget _buildNotasSection(
    Reserva reserva,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Notas de la Reserva', bold),
        _card(
          child: pw.Text(
            reserva.notas,
            style: pw.TextStyle(fontSize: 9, color: _textPrimary),
          ),
        ),
      ],
    );
  }

  // ─── Pagos ───────────────────────────────────────────────────────

  static pw.Widget _buildPagosSection(
    List<PagoRealizado> pagos,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pagos Realizados (${pagos.length})', bold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _bgSubtle),
              children: [
                _tableHeader('Fecha', bold),
                _tableHeader('Proveedor / NIT', bold),
                _tableHeader('Monto', bold),
                _tableHeader('Método', bold),
                _tableHeader('Referencia', bold),
              ],
            ),
            ...pagos.map(
              (p) => pw.TableRow(
                children: [
                  _tableCell(p.fechaDocumento, regular),
                  _tableCell('${p.proveedorComercio}\nNIT: ${p.nit}', regular),
                  _tableCell(_fmt(p.monto), bold, align: pw.TextAlign.right),
                  _tableCell(p.metodoPago, regular),
                  _tableCell(p.referencia, regular),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Resumen de costos ───────────────────────────────────────────

  static pw.Widget _buildResumenSection(
    Reserva reserva,
    List<Service> serviciosList,
    pw.Font bold,
    pw.Font regular,
  ) {
    final isTour = reserva.tipoReserva == 'tour';
    final paxCount = reserva.integrantes.length;
    final total = reserva.valorTotal ?? 0.0;
    final sinDescuento = reserva.valorSinDescuento ?? total;
    final saldoPendiente = reserva.saldoPendiente ?? 0.0;

    final totalPaxValue =
        reserva.valorPersonas ??
        (isTour ? ((reserva.tour?.price ?? 0.0) * paxCount).toDouble() : 0.0);
    final displayPaxCount = reserva.totalPersonas ?? paxCount;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Resumen de Costos', bold),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('F8FAFF'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: _border, width: 0.5),
          ),
          child: pw.Column(
            children: [
              // Detailed Costs
              if (sinDescuento > 0)
                _summaryRow(
                  'Valor sin descuento',
                  _fmt(sinDescuento),
                  bold,
                  regular,
                ),

              if (isTour && totalPaxValue > 0)
                _summaryRow(
                  'Valor por todas las personas ($displayPaxCount pax)',
                  _fmt(totalPaxValue),
                  bold,
                  regular,
                ),

              if (serviciosList.isNotEmpty) ...[
                ...serviciosList.map(
                  (s) => _summaryRow(
                    'Servicio: ${s.name}',
                    _fmt(s.cost),
                    bold,
                    regular,
                  ),
                ),
              ],

              if (reserva.tipoReserva == 'vuelos') ...[
                ...reserva.vuelos.map(
                  (v) => _summaryRow(
                    'Vuelo: ${v.aerolinea?.nombre ?? v.numeroVuelo}',
                    _fmt(v.precio),
                    bold,
                    regular,
                  ),
                ),
                ...reserva.hoteles.map(
                  (h) => _summaryRow(
                    'Hotel: ${h.hotel?.nombre ?? 'Hospedaje'}',
                    _fmt(h.valor),
                    bold,
                    regular,
                  ),
                ),
              ],

              pw.SizedBox(height: 6),
              pw.Container(height: 0.5, color: _border),
              pw.SizedBox(height: 6),

              _summaryRow(
                'VALOR TOTAL',
                _fmt(total),
                bold,
                bold,
                isTotal: true,
              ),

              if (saldoPendiente > 0) ...[
                pw.SizedBox(height: 4),
                _summaryRow(
                  'Saldo pendiente',
                  _fmt(saldoPendiente),
                  bold,
                  regular,
                  isPending: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font bold,
    pw.Font valueFont, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isPending = false,
  }) {
    final labelColor = isTotal
        ? _textPrimary
        : isDiscount
        ? _success
        : isPending
        ? _warning
        : _textSecondary;
    final valueColor = isTotal
        ? _brand
        : isDiscount
        ? _success
        : isPending
        ? _warning
        : _textPrimary;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: isTotal ? bold : null,
                fontSize: isTotal ? 11 : 9,
                color: labelColor,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: valueFont,
              fontSize: isTotal ? 12 : 9,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Table helpers ───────────────────────────────────────────────

  static pw.Widget _tableHeader(String text, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: bold, fontSize: 8, color: _textSecondary),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    PdfColor? color,
    pw.TextAlign? align,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: color ?? _textPrimary,
        ),
      ),
    );
  }

  static pw.Widget _tableCellWidget(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: child,
    );
  }
  // ─── Condiciones y Restricciones ──────────────────────────────────

  static pw.Widget _buildCondicionesSection(
    String tourName,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        _sectionTitle('CONDICIONES Y RESTRICCIONES', bold),
        pw.SizedBox(height: 8),
        pw.Text(
          'Entre la AGENCIA DE VIAJES TRAVEL TOURS FLORENCIA, identificada con NIT 1006502501-6, inscrita en el Registro Nacional de Turismo (RNT) No. 163427, en adelante LA AGENCIA, y el turista, en adelante EL USUARIO, se celebran las presentes condiciones y restricciones que regulan la prestación del servicio turístico denominado $tourName, conforme a la Ley 300 de 1996, la Ley 1558 de 2012 y el Estatuto del Consumidor – Ley 1480 de 2011.',
          style: pw.TextStyle(font: regular, fontSize: 8),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 8),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'IMPORTANTE: ',
                style: pw.TextStyle(font: bold, fontSize: 8),
              ),
              pw.TextSpan(
                text:
                    'El inicio de la actividad dependerá exclusivamente del cumplimiento, por parte de los turistas, de todas las indicaciones y protocolos establecidos por las agencias organizadoras, orientados a garantizar la seguridad, el orden y el adecuado desarrollo de la actividad. El incumplimiento de dichas indicaciones podrá ocasionar la no iniciación o suspensión de la actividad, sin que ello genere derecho a reclamaciones.',
                style: pw.TextStyle(font: regular, fontSize: 8),
              ),
            ],
          ),
          textAlign: pw.TextAlign.justify,
        ),
        _clausula(
          'PRIMERA. ACEPTACIÓN DEL SERVICIO, RESERVA Y MEDIOS DE PAGO',
          'En cumplimiento del deber de información previsto en la Ley 1480 de 2011 (Estatuto del Consumidor), LA AGENCIA informa de manera clara, suficiente y oportuna las condiciones del servicio turístico.\nLa realización del pago parcial (abono) o pago total constituye acceptance expresa de estas condiciones por parte de EL USUARIO. La reserva del cupo se entenderá confirmada únicamente una vez efectuado el pago parcial (abono) o el pago total correspondiente a LA AGENCIA. Esto significa que no se reservan cupos sin previo abono.\nÚnicamente serán válidos los pagos realizados a través de los medios de pago autorizados (relacionados en la última página del documento) o directamente en la oficina de LA AGENCIA. Cada pago recibido generará un recibo oficial como confirmación de este.\nEl plan deberá estar cancelado en su totalidad al menos con una (1) semana de antelación a la fecha del viaje, en concordancia con lo dispuesto en la Ley 300 de 1996, la Ley 1558 de 2012 y la Ley 2068 de 2020, que regulan la prestación de servicios turísticos en Colombia. El incumplimiento de esta condición podrá dar lugar a la cancelación automática de la reserva, sin derecho a devolución de los valores abonados, conforme al artículo 47 de la Ley 1480 de 2011.',
          bold,
          regular,
        ),
        _clausula(
          'SEGUNDA. DATOS',
          'EL USUARIO deberá suministrar los datos completos de cada pasajero tal como aparecen en su documento de identidad, incluyendo a los bebés de brazo. La información requerida comprende: nombre completo, número de documento, fecha de nacimiento y número de teléfono de contacto.',
          bold,
          regular,
        ),
        _clausula(
          'TERCERA. CLÁUSULA DE CANCELACIÓN Y REEMPLAZO DE PASAJERO',
          'En caso de que EL USUARIO decida cancelar el cupo reservado por motivos personales ajenos a LA AGENCIA, el dinero abonado no será objeto de devolución, conforme a lo establecido en el artículo 47 de la Ley 1480 de 2011 (Estatuto del Consumidor), que señala que el derecho de retracto no aplica a los servicios turísticos con fecha específica de ejecución, y en concordancia con la Ley 300 de 1996 y la Ley 1558 de 2012, que regulan la prestación de servicios turísticos en Colombia.\nEn ningún caso el saldo abonado se reconocerá como saldo a favor para otro plan ni podrá ser transferido a otro pasajero, dado que el abono realizado se considerará como penalidad y no será reembolsable.\nNo obstante, EL USUARIO podrá ceder o transferir su cupo a otra persona, siempre que lo notifique a LA AGENCIA con al menos dos (2) días de antelación a la fecha de realización del viaje. Dicho reemplazo estará sujeto a la aceptación de LA AGENCIA y no generará costos adicionales, salvo aquellos derivados de trámites administrativos o logísticos que deban realizarse para garantizar la correcta prestación del servicio.',
          bold,
          regular,
        ),
        _clausula(
          'CUARTA. HORARIOS Y PUNTUALIDAD',
          'EL USUARIO se obliga a presentarse en el lugar y hora indicados. El transporte saldrá puntualmente y LA AGENCIA no asumirá responsabilidad por retrasos imputables al pasajero. La no llegada de EL USUARIO al lugar y hora indicados para el inicio de la actividad, conocida como No Show, implica la pérdida total del dinero abonado, sin derecho a devolución ni reembolso alguno, conforme al artículo 47 de la Ley 1480 de 2011. En estos casos, LA AGENCIA continuará con la prestación del servicio únicamente para los pasajeros presentes, sin que ello constituya incumplimiento contractual, en concordancia con la Ley 300 de 1996.\nComo alternativa, EL USUARIO podrá transferir su cupo a otra persona, siempre que lo notifique a LA AGENCIA con al menos un (1) día de antelación a la fecha de realización del viaje. El reemplazo estará sujeto a aceptación y registro por parte de LA AGENCIA.',
          bold,
          regular,
        ),
        _clausula(
          'QUINTA. ACOMODACIÓN HOTEL',
          'La acomodación será múltiple, a partir de tres (3) personas por habitación. Los grupos conformados por más de tres (3) personas no compartirán habitación con personas ajenas a su grupo.\nLas habitaciones de pareja tendrán un costo adicional. En caso de que EL USUARIO no cancele dicho costo adicional, la acomodación de grupos de dos (2) personas o menos quedará a disposición de LA AGENCIA, quien asignará la distribución de acuerdo con la disponibilidad y operación del servicio.\nAl momento de la asignación de habitaciones, LA AGENCIA se comunicará con EL USUARIO para informarle la distribución correspondiente, garantizando transparencia y claridad en el proceso. Esta disposición se establece en cumplimiento del deber de información previsto en el artículo 3 de la Ley 1480 de 2011 (Estatuto del Consumidor), en concordancia con la Ley 300 de 1996 y la Ley 1558 de 2012, que regulan la prestación de servicios turísticos en Colombia.',
          bold,
          regular,
        ),
        _clausula(
          'SEXTA. TRANSPORTE',
          'Los cupos de transporte terrestre son limitados y se asignan por orden de reserva. El tipo de vehículo utilizado dependerá directamente del número de turistas inscritos en el viaje, conforme a las siguientes condiciones:\n• Grupo de 15 a 18 pasajeros: vehículo tipo van.\n• Grupo de 19 a 30 pasajeros: busetón.\n• Grupo de 31 a 40 pasajeros: bus.\nPrevio a cada viaje, LA AGENCIA solicitará y verificará que los vehículos cuenten con la documentación en regla exigida por la normativa colombiana, incluyendo la revisión técnico-mecánica vigente, el seguro obligatorio de accidentes de tránsito (SOAT) y demás permisos requeridos para la prestación del servicio de transporte turístico terrestre automotor.\nEsta disposición se establece en cumplimiento del deber de información previsto en el artículo 3 de la Ley 1480 de 2011 (Estatuto del Consumidor), en concordancia con la Ley 300 de 1996, la Ley 1558 de 2012, la Ley 2068 de 2020 y la Norma Técnica Colombiana NTC 6506 de 2021 (ICONTEC), que regulan la prestación del servicio de transporte turístico terrestre automotor en Colombia.',
          bold,
          regular,
        ),
        _clausula(
          'SEPTIMA. COMPORTAMIENTO Y SEGURIDAD',
          'EL USUARIO se compromete a mantener una conducta respetuosa. LA AGENCIA podrá suspender la prestación del servicio a quienes incumplan las normas de convivencia o seguridad, sin derecho a reembolso, conforme a la Ley 300 de 1996. El pasajero participa bajo su responsabilidad personal, comprometiéndose a informar cualquier condición médica que pueda afectar su participación. LA AGENCIA no se hace responsable por accidentes derivados del incumplimiento de las normas de seguridad. Está prohibido portar armas, objetos cortopunzantes, envases de vidrio o sustancias psicoactivas. El incumplimiento de estas condiciones podrá generar la exclusión de la actividad, sin derecho a reembolso.',
          bold,
          regular,
        ),
        _clausula(
          'OCTAVA. RESPONSABILIDAD DEL USUARIO',
          'EL USUARIO declara conocer los riesgos inherentes a la actividad turística y asumir su responsabilidad personal y estado de salud. LA AGENCIA no se hace responsable por pérdida, daño u olvido de objetos personales.',
          bold,
          regular,
        ),
        _clausula(
          'NOVENA. MENORES DE EDAD',
          'Los menores de edad deberán viajar acompañados por un adulto responsable, quien asumirá la responsabilidad total durante el desarrollo de la pasadía. Si el menor viaja sin la compañía de uno de sus padres, deberá llevar un formulario firmado por al menos uno de ellos (Autorización de viaje para niños, niñas y adolescentes). EL USUARIO debe solicitar dicho documento a LA AGENCIA, quien le proveerá toda la información luego de su solicitud. Se protegen los derechos de los niños, niñas y adolescentes conforme a la Ley 1098 de 2006, la Ley 679 de 2001 y la Ley 1336 de 2009.',
          bold,
          regular,
        ),
        _clausula(
          'DECIMA. NORMATIVIDAD APLICABLE',
          'El presente documento se rige por las disposiciones contenidas en la Ley 300 de 1996, la Ley 1558 de 2012, la Ley 1480 de 2011 y demás normas concordantes del ordenamiento jurídico colombiano.',
          bold,
          regular,
        ),
      ],
    );
  }

  static pw.Widget _clausula(
    String title,
    String content,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 10),
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 8.5)),
        pw.SizedBox(height: 4),
        pw.Text(
          content,
          style: pw.TextStyle(font: regular, fontSize: 8),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }
}
