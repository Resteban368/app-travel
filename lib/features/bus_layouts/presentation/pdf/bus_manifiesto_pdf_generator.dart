import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import '../../domain/entities/bus_layout.dart';
import '../../domain/entities/bus_manifiesto.dart';

class BusManifestoPdfGenerator {
  // ─── Brand colors ────────────────────────────────────────────────
  static final _brand = PdfColor.fromHex('2563EB');
  static final _brandDark = PdfColor.fromHex('1E3A8A');
  static final _brandLight = PdfColor.fromHex('EFF6FF');
  static final _textPrimary = PdfColor.fromHex('1A1A1A');
  static final _textSecondary = PdfColor.fromHex('57534E');
  static final _textTertiary = PdfColor.fromHex('78716C');
  static final _border = PdfColor.fromHex('E5E7EB');
  static final _bgSubtle = PdfColor.fromHex('F5F5F4');
  static final _success = PdfColor.fromHex('16A34A');

  // ─── Seat palette (matches screen _kReservaColors) ───────────────
  static final _seatColors = [
    PdfColor.fromHex('2563EB'),
    PdfColor.fromHex('059669'),
    PdfColor.fromHex('D97706'),
    PdfColor.fromHex('7C3AED'),
    PdfColor.fromHex('DB2777'),
    PdfColor.fromHex('0891B2'),
    PdfColor.fromHex('EA580C'),
    PdfColor.fromHex('65A30D'),
    PdfColor.fromHex('6D28D9'),
    PdfColor.fromHex('0F766E'),
  ];
  static final _seatFree = PdfColor.fromHex('E2E8F0');
  static final _busPanel = PdfColor.fromHex('1E293B');
  static final _banoBg = PdfColor.fromHex('F0FDF4');
  static final _banoBorder = PdfColor.fromHex('86EFAC');
  static final _agenteBg = PdfColor.fromHex('FEF3C7');
  static final _agenteText = PdfColor.fromHex('D97706');
  static final _entradaBg = PdfColor.fromHex('EDE9FE');
  static final _entradaText = PdfColor.fromHex('7C3AED');

  // ─── Font caches ─────────────────────────────────────────────────
  static pw.MemoryImage? _cachedLogo;
  static pw.Font? _cachedBold;
  static pw.Font? _cachedRegular;

  // ─── Public entry point ──────────────────────────────────────────
  static Future<Uint8List> generate(BusManifiesto manifiesto) async {
    final doc = pw.Document();

    // Logo
    pw.MemoryImage? logoImage;
    if (_cachedLogo != null) {
      logoImage = _cachedLogo;
    } else {
      try {
        final data = await rootBundle.load('assets/logo-empresa/logo-empresa.jpeg');
        _cachedLogo = pw.MemoryImage(data.buffer.asUint8List());
        logoImage = _cachedLogo;
      } catch (e) {
        debugPrint('[BusManifestoPdf] Logo error: $e');
      }
    }

    // Fonts
    pw.Font bold;
    pw.Font regular;
    if (_cachedBold != null && _cachedRegular != null) {
      bold = _cachedBold!;
      regular = _cachedRegular!;
    } else {
      try {
        _cachedBold = await PdfGoogleFonts.robotoBold();
        _cachedRegular = await PdfGoogleFonts.robotoRegular();
        bold = _cachedBold!;
        regular = _cachedRegular!;
      } catch (_) {
        bold = pw.Font.helveticaBold();
        regular = pw.Font.helvetica();
      }
    }

    // Build reservation → color index mapping (global across all buses)
    final Map<String, int> reservaColorIdx = {};
    for (final bus in manifiesto.buses) {
      for (final asiento in bus.asientos) {
        if (asiento.reserva != null) {
          final id = asiento.reserva!.idReserva;
          reservaColorIdx.putIfAbsent(id, () => reservaColorIdx.length);
        }
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (ctx) => _buildHeader(ctx, logoImage, manifiesto.tour, bold, regular),
        footer: (ctx) => _buildFooter(ctx, logoImage, bold),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildTourCard(manifiesto.tour, bold, regular),
          ...manifiesto.buses.expand((bus) => [
            pw.SizedBox(height: 20),
            _buildBusBlock(bus, reservaColorIdx, bold, regular),
          ]),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Page header ─────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    pw.Context ctx,
    pw.MemoryImage? logo,
    TourInfoManifiesto tour,
    pw.Font bold,
    pw.Font regular,
  ) {
    if (ctx.pageNumber != 1) {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Manifiesto de Bus · ${tour.nombreTour}',
              style: pw.TextStyle(font: bold, fontSize: 9, color: _textTertiary),
            ),
            pw.Text('Travel Tours Florencia',
                style: pw.TextStyle(fontSize: 9, color: _textTertiary)),
          ],
        ),
      );
    }

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
              // Logo box
              pw.Container(
                width: 70,
                height: 70,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Center(
                  child: logo != null
                      ? pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        )
                      : pw.Text('TT',
                          style: pw.TextStyle(font: bold, fontSize: 22, color: _brand)),
                ),
              ),
              pw.SizedBox(width: 18),
              // Company info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Travel Tours Florencia',
                        style: pw.TextStyle(font: bold, fontSize: 15, color: PdfColors.white)),
                    pw.SizedBox(height: 4),
                    _headerLine('GERENTE: Daniela Agatón Soto'),
                    _headerLine('NIT: 10065025016'),
                    _headerLine('CRA 7 N 16A 08 BRR 7 DE AGOSTO'),
                    _headerLine('3142266528 · infoasesoras2022@gmail.com'),
                  ],
                ),
              ),
              // Doc label
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('MANIFIESTO DE BUS',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 8,
                        color: PdfColor(1, 1, 1, 0.75),
                        letterSpacing: 1.2,
                      )),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _headerLine(String text) {
    return pw.Text(text,
        style: pw.TextStyle(fontSize: 8, color: PdfColor(1, 1, 1, 0.7)));
  }

  // ─── Page footer ─────────────────────────────────────────────────
  static pw.Widget _buildFooter(
    pw.Context ctx,
    pw.MemoryImage? logo,
    pw.Font bold,
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
              if (logo != null)
                pw.Container(
                  height: 22,
                  width: 22,
                  margin: const pw.EdgeInsets.only(right: 8),
                  child: pw.Image(logo),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Travel Tours Florencia · NIT: 10065025016',
                      style: pw.TextStyle(fontSize: 7, font: bold, color: _brand)),
                  pw.Text('Dirección: CRA 7 N 16A 08 BRR 7 DE AGOSTO',
                      style: pw.TextStyle(fontSize: 6, color: _textTertiary)),
                  pw.Text('Tel: 3142266528 · Correo: INFOASESORAS2022@GMAIL.COM',
                      style: pw.TextStyle(fontSize: 6, color: _textTertiary)),
                ],
              ),
            ],
          ),
          pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: _textTertiary)),
        ],
      ),
    );
  }

  // ─── Tour info card ───────────────────────────────────────────────
  static pw.Widget _buildTourCard(
    TourInfoManifiesto tour,
    pw.Font bold,
    pw.Font regular,
  ) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final chips = <String>[];
    if (tour.fechaInicio != null) chips.add('Salida: ${fmt.format(tour.fechaInicio!)}');
    if (tour.fechaFin != null) chips.add('Regreso: ${fmt.format(tour.fechaFin!)}');
    if (tour.horaPartida != null) chips.add('Hora: ${tour.horaPartida}');
    if (tour.puntoPartida != null) chips.add('Partida: ${tour.puntoPartida}');
    if (tour.llegada != null) chips.add('Destino: ${tour.llegada}');
    if (tour.cupos != null) chips.add('Cupos: ${tour.cupos}');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _brandLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _brand, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(tour.nombreTour,
              style: pw.TextStyle(font: bold, fontSize: 11, color: _brandDark)),
          if (chips.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Wrap(
              spacing: 12,
              runSpacing: 2,
              children: chips
                  .map((c) => pw.Text(c,
                      style: pw.TextStyle(font: bold, fontSize: 7.5, color: _brandDark)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bus block (grid + passenger table side by side) ─────────────
  static pw.Widget _buildBusBlock(
    BusManifiestoData bus,
    Map<String, int> reservaColorIdx,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Bus: ${bus.nombre}', bold),
        pw.SizedBox(height: 8),
        _buildStats(bus, bold),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSeatGrid(bus, reservaColorIdx, bold),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: _buildPassengerTable(bus, reservaColorIdx, bold, regular),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Stats bar ───────────────────────────────────────────────────
  static pw.Widget _buildStats(BusManifiestoData bus, pw.Font bold) {
    final pct = bus.totalAsientosCliente > 0
        ? (bus.asientosOcupados / bus.totalAsientosCliente * 100).toStringAsFixed(0)
        : '0';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _bgSubtle,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        children: [
          _statLabel('Ocupados', '${bus.asientosOcupados}', _brand, bold),
          pw.SizedBox(width: 20),
          _statLabel('Disponibles', '${bus.asientosDisponibles}', _success, bold),
          pw.SizedBox(width: 20),
          _statLabel('Total', '${bus.totalAsientosCliente}', _textPrimary, bold),
          pw.Spacer(),
          pw.Text('$pct% ocupado',
              style: pw.TextStyle(font: bold, fontSize: 9, color: _textPrimary)),
        ],
      ),
    );
  }

  static pw.Widget _statLabel(String label, String value, PdfColor color, pw.Font bold) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, color: _textSecondary)),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 9, color: color)),
      ],
    );
  }

  // ─── Seat grid ───────────────────────────────────────────────────
  static const _cellSize = 28.0;
  static const _cellMargin = 2.0;
  static const _aisleWidth = 12.0;
  static const _rowLabelWidth = 16.0;

  static pw.Widget _buildSeatGrid(
    BusManifiestoData bus,
    Map<String, int> reservaColorIdx,
    pw.Font bold,
  ) {
    final cfg = bus.configuracion;
    final asientosPorNumero = {for (final a in bus.asientos) a.numero: a};

    final maxFila = cfg.asientos.isEmpty
        ? 0
        : cfg.asientos.map((a) => a.fila).reduce((a, b) => a > b ? a : b);
    final mitad = (cfg.columnas / 2).floor();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Front cap
        _busCap('FRENTE DEL BUS', top: true),
        pw.SizedBox(height: 3),
        // Rows
        ...List.generate(maxFila + 1, (filaIdx) {
          final row = cfg.asientos
              .where((a) => a.fila == filaIdx)
              .toList()
            ..sort((a, b) => a.columna.compareTo(b.columna));

          if (row.isEmpty) return pw.SizedBox(height: 2);

          final left = row.where((a) => a.columna < mitad).toList();
          final right = row.where((a) => a.columna >= mitad).toList();

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Row label
                pw.SizedBox(
                  width: _rowLabelWidth,
                  child: pw.Text(
                    filaIdx == 0 ? '' : '$filaIdx',
                    style: pw.TextStyle(fontSize: 7, color: _textTertiary),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(width: 2),
                ..._buildSectionPdf(left, asientosPorNumero, reservaColorIdx, bold),
                pw.SizedBox(width: _aisleWidth),
                ..._buildSectionPdf(right, asientosPorNumero, reservaColorIdx, bold),
                pw.SizedBox(width: 2),
                pw.SizedBox(width: _rowLabelWidth),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 3),
        // Back cap
        _busCap('PARTE TRASERA', top: false),
      ],
    );
  }

  static pw.Widget _busCap(String label, {required bool top}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 14),
      decoration: pw.BoxDecoration(
        color: _busPanel,
        borderRadius: top
            ? const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              )
            : const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(10),
                bottomRight: pw.Radius.circular(10),
              ),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: 7, color: PdfColor(1, 1, 1, 0.5), letterSpacing: 1.0),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static List<pw.Widget> _buildSectionPdf(
    List<AsientoLayout> asientos,
    Map<String, AsientoManifiesto> asientosPorNumero,
    Map<String, int> reservaColorIdx,
    pw.Font bold,
  ) {
    final widgets = <pw.Widget>[];
    int i = 0;
    while (i < asientos.length) {
      final a = asientos[i];
      if (a.tipo == TipoAsiento.bano) {
        int count = 1;
        while (i + count < asientos.length &&
            asientos[i + count].tipo == TipoAsiento.bano) {
          count++;
        }
        widgets.add(count >= 2 ? _banoCellDouble() : _banoCellSingle());
        i += count;
      } else {
        widgets.add(
          _seatCell(a, asientosPorNumero[a.numero], reservaColorIdx, bold),
        );
        i++;
      }
    }
    return widgets;
  }

  static pw.Widget _seatCell(
    AsientoLayout layout,
    AsientoManifiesto? asiento,
    Map<String, int> reservaColorIdx,
    pw.Font bold,
  ) {
    if (layout.tipo == TipoAsiento.vacio) {
      return pw.SizedBox(width: _cellSize + _cellMargin * 2, height: _cellSize + _cellMargin * 2);
    }

    PdfColor bg;
    PdfColor fg;
    String topLabel;
    String subLabel = '';

    switch (layout.tipo) {
      case TipoAsiento.conductor:
        bg = _busPanel;
        fg = PdfColor(1, 1, 1, 0.55);
        topLabel = 'Cond';
        break;
      case TipoAsiento.agente:
        bg = _agenteBg;
        fg = _agenteText;
        topLabel = 'Agnt';
        break;
      case TipoAsiento.entrada:
        bg = _entradaBg;
        fg = _entradaText;
        topLabel = 'Ent.';
        break;
      default:
        final reserva = asiento?.reserva;
        if (reserva == null) {
          bg = _seatFree;
          fg = PdfColor.fromHex('64748B');
          topLabel = layout.numero;
        } else {
          final idx = (reservaColorIdx[reserva.idReserva] ?? 0) % _seatColors.length;
          bg = _seatColors[idx];
          fg = PdfColors.white;
          topLabel = layout.numero;
          final nombre = reserva.responsable?.nombre ?? reserva.idReserva;
          subLabel = nombre.split(' ').first;
          if (subLabel.length > 7) subLabel = subLabel.substring(0, 7);
        }
    }

    return pw.Container(
      width: _cellSize,
      height: _cellSize,
      margin: const pw.EdgeInsets.all(_cellMargin),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(topLabel,
              style: pw.TextStyle(font: bold, fontSize: 7, color: fg),
              textAlign: pw.TextAlign.center),
          if (subLabel.isNotEmpty)
            pw.Text(subLabel,
                style: pw.TextStyle(fontSize: 5, color: fg),
                textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static pw.Widget _banoCellSingle() {
    return pw.Container(
      width: _cellSize,
      height: _cellSize - 4,
      margin: const pw.EdgeInsets.all(_cellMargin),
      decoration: pw.BoxDecoration(
        color: _banoBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _banoBorder, width: 0.5),
      ),
      child: pw.Center(
        child: pw.Text('Baño',
            style: pw.TextStyle(fontSize: 6, color: PdfColor.fromHex('16A34A'))),
      ),
    );
  }

  static pw.Widget _banoCellDouble() {
    return pw.Container(
      width: _cellSize * 2 + _cellMargin * 2,
      height: _cellSize,
      margin: const pw.EdgeInsets.all(_cellMargin),
      decoration: pw.BoxDecoration(
        color: _banoBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _banoBorder, width: 0.5),
      ),
      child: pw.Center(
        child: pw.Text('Baño',
            style: pw.TextStyle(fontSize: 6, color: PdfColor.fromHex('16A34A'))),
      ),
    );
  }

  // ─── Passenger table (compact, beside the grid) ──────────────────
  static pw.Widget _buildPassengerTable(
    BusManifiestoData bus,
    Map<String, int> reservaColorIdx,
    pw.Font bold,
    pw.Font regular,
  ) {
    final asientosPorReserva = <String, List<String>>{};
    final reservasUnicas = <String, ReservaManifiesto>{};
    for (final a in bus.asientos) {
      if (a.reserva != null) {
        reservasUnicas[a.reserva!.idReserva] = a.reserva!;
        asientosPorReserva
            .putIfAbsent(a.reserva!.idReserva, () => [])
            .add(a.numero);
      }
    }

    if (reservasUnicas.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _bgSubtle,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text('Sin pasajeros asignados',
            style: pw.TextStyle(fontSize: 9, color: _textTertiary)),
      );
    }

    final rows = <pw.TableRow>[];

    for (final entry in reservasUnicas.entries) {
      final reserva = entry.value;
      final asientos = (asientosPorReserva[entry.key] ?? [])..sort();
      final idx = (reservaColorIdx[entry.key] ?? 0) % _seatColors.length;
      final accentColor = _seatColors[idx];

      final people = <PersonaManifiesto>[];
      if (reserva.responsable != null) people.add(reserva.responsable!);
      people.addAll(reserva.integrantes);

      int seatIdx = 0;
      for (int i = 0; i < people.length; i++) {
        final person = people[i];
        String seatLabel = '';

        final occupiesSeat = person.ocupaAsiento;
        if (!occupiesSeat) {
          seatLabel = 'Sin asiento';
        } else {
          if (seatIdx < asientos.length) {
            seatLabel = asientos[seatIdx];
            seatIdx++;
          } else {
            seatLabel = 'Sin asignar';
          }
        }

        rows.add(_passengerRow(
          reservaId: reserva.idReserva,
          nombre: person.nombre,
          doc: person.documento != null
              ? '${person.tipoDocumento ?? 'DOC'}: ${person.documento}'
              : '-',
          tel: person.telefono ?? '-',
          asientos: seatLabel,
          accentColor: accentColor,
          bgColor: accentColor,
          bold: bold,
          regular: regular,
          isHeader: i == 0,
        ));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(
            'Pasajeros — ${reservasUnicas.length} reservas · ${rows.length} personas',
            bold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.3),
          columnWidths: {
            0: const pw.FixedColumnWidth(50), // ID Reserva
            1: const pw.FlexColumnWidth(2.5), // Nombre
            2: const pw.FlexColumnWidth(2.0), // Documento
            3: const pw.FlexColumnWidth(1.5), // Teléfono
            4: const pw.FixedColumnWidth(45), // Asientos
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _brandDark),
              children: [
                _th('ID Reserva', bold, color: PdfColors.white),
                _th('Nombre del Pasajero', bold, color: PdfColors.white),
                _th('Documento', bold, color: PdfColors.white),
                _th('Teléfono', bold, color: PdfColors.white),
                _th('Asientos', bold, color: PdfColors.white),
              ],
            ),
            ...rows,
          ],
        ),
      ],
    );
  }

  static pw.TableRow _passengerRow({
    required String reservaId,
    required String nombre,
    required String doc,
    required String tel,
    required String asientos,
    required PdfColor accentColor,
    required PdfColor bgColor,
    required pw.Font bold,
    required pw.Font regular,
    required bool isHeader,
  }) {
    final textColor = PdfColors.white;
    final idColor = PdfColors.white;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        // Reserva ID
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text(reservaId,
              style: pw.TextStyle(font: bold, fontSize: 6, color: idColor)),
        ),
        // Nombre
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text(nombre,
              style: pw.TextStyle(
                font: isHeader ? bold : regular,
                fontSize: 7,
                color: textColor,
              )),
        ),
        // Documento
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text(doc,
              style: pw.TextStyle(font: regular, fontSize: 6.5, color: textColor)),
        ),
        // Teléfono
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text(tel,
              style: pw.TextStyle(font: regular, fontSize: 6.5, color: textColor)),
        ),
        // Asientos
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: pw.Text(asientos,
              style: pw.TextStyle(font: bold, fontSize: 6.5, color: textColor)),
        ),
      ],
    );
  }

  // ─── Widget helpers ───────────────────────────────────────────────
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
        child: pw.Text(title,
            style: pw.TextStyle(font: bold, fontSize: 11, color: _brandDark)),
      ),
    );
  }

  static pw.Widget _th(String text, pw.Font bold, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(font: bold, fontSize: 7, color: color ?? _textSecondary)),
    );
  }

}
