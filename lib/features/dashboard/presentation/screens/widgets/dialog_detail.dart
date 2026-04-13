import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Paleta (misma del dashboard/login) ──────────────────────────────────────
class _C {
  static const bg = Color(0xFF070F1C);
  static const surface = Color(0xFF0D1828);
  static const surfaceHigh = Color(0xFF122035);
  static const border = Color(0xFF1A2E45);
  static const royalBlue = Color(0xFF1447E6);
  static const skyBlue = Color(0xFF38BDF8);
  static const cyan = Color(0xFF06B6D4);
  static const indigo = Color(0xFF6366F1);
  static const gold = Color(0xFFF59E0B);
  static const emerald = Color(0xFF10B981);
  static const rose = Color(0xFFF43F5E);
  static const white = Colors.white;
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate600 = Color(0xFF475569);
}

class DialogDetailTour extends StatelessWidget {
  const DialogDetailTour({
    super.key,
    required this.tour,
    required NumberFormat currencyFormat,
    required this.dateFormat,
  }) : _currencyFormat = currencyFormat;

  final Tour tour;
  final NumberFormat _currencyFormat;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Hero image ──────────────────────────────────────────────
                _HeroSection(
                  tour: tour,
                  currencyFormat: _currencyFormat,
                ),

                // ── Body ────────────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price row + agency
                        _PriceAgencyRow(
                          tour: tour,
                          currencyFormat: _currencyFormat,
                        ),
                        const SizedBox(height: 16),

                        // Info chips
                        _InfoGrid(tour: tour, dateFormat: dateFormat),
                        const SizedBox(height: 20),

                        // Inclusions
                        if (tour.inclusions.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.check_circle_rounded,
                            label: 'Incluye',
                            color: _C.emerald,
                          ),
                          const SizedBox(height: 10),
                          ...tour.inclusions.map(
                            (item) => _ListItem(
                              text: item,
                              icon: Icons.check_rounded,
                              color: _C.emerald,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Exclusions
                        if (tour.exclusions.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.cancel_rounded,
                            label: 'No incluye',
                            color: _C.rose,
                          ),
                          const SizedBox(height: 10),
                          ...tour.exclusions.map(
                            (item) => _ListItem(
                              text: item,
                              icon: Icons.close_rounded,
                              color: _C.rose,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Itinerary
                        if (tour.itinerary.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.map_rounded,
                            label: 'Itinerario',
                            color: _C.skyBlue,
                          ),
                          const SizedBox(height: 12),
                          ...tour.itinerary.asMap().entries.map(
                            (e) => _ItineraryItem(
                              day: e.value,
                              isLast: e.key == tour.itinerary.length - 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HERO SECTION
// ═══════════════════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final Tour tour;
  final NumberFormat currencyFormat;

  const _HeroSection({required this.tour, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(
            tour.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: _C.surfaceHigh,
              child: const Icon(
                Icons.image_rounded,
                size: 56,
                color: _C.slate600,
              ),
            ),
          ),

          // Gradient overlay (full)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          // Top-left badges
          Positioned(
            top: 14,
            left: 14,
            child: Row(
              children: [
                if (tour.isPromotion)
                  _HeroBadge(
                    label: 'PROMO',
                    color: _C.gold,
                    icon: Icons.local_offer_rounded,
                  ),
                if (!tour.isActive) ...[
                  if (tour.isPromotion) const SizedBox(width: 6),
                  _HeroBadge(
                    label: 'INACTIVO',
                    color: _C.rose,
                    icon: Icons.block_rounded,
                  ),
                ],
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Bottom title + meta
          Positioned(
            bottom: 14,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: _C.skyBlue,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tour.departurePoint,
                      style: const TextStyle(
                        color: _C.slate300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _HeroBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PRICE + AGENCY ROW
// ═══════════════════════════════════════════════════════════════════════════════
class _PriceAgencyRow extends StatelessWidget {
  final Tour tour;
  final NumberFormat currencyFormat;

  const _PriceAgencyRow({required this.tour, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.royalBlue, _C.skyBlue],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.skyBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              currencyFormat.format(tour.price),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agencia',
                  style: TextStyle(
                    color: _C.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tour.agency,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

// ═══════════════════════════════════════════════════════════════════════════════
//  INFO GRID
// ═══════════════════════════════════════════════════════════════════════════════
class _InfoGrid extends StatelessWidget {
  final Tour tour;
  final DateFormat dateFormat;

  const _InfoGrid({required this.tour, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(
        icon: Icons.calendar_today_rounded,
        label: 'Fechas',
        value: '${dateFormat.format(tour.startDate)} — ${dateFormat.format(tour.endDate)}',
        color: _C.indigo,
      ),
      _InfoItem(
        icon: Icons.access_time_rounded,
        label: 'Hora de salida',
        value: tour.departureTime,
        color: _C.cyan,
      ),
      _InfoItem(
        icon: Icons.flag_rounded,
        label: 'Llegada',
        value: tour.arrival,
        color: _C.emerald,
      ),
      _InfoItem(
        icon: Icons.place_rounded,
        label: 'Punto de salida',
        value: tour.departurePoint,
        color: _C.skyBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 400;
        if (isWide) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.0,
            children: items.map((item) => _InfoChip(item: item)).toList(),
          );
        }
        return Column(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InfoChip(item: item),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _InfoChip extends StatelessWidget {
  final _InfoItem item;
  const _InfoChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: _C.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ═══════════════════════════════════════════════════════════════════════════════
//  SECTION TITLE
// ═══════════════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LIST ITEM (inclusiones / exclusiones)
// ═══════════════════════════════════════════════════════════════════════════════
class _ListItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _ListItem({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _C.slate300,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ITINERARY ITEM (timeline)
// ═══════════════════════════════════════════════════════════════════════════════
class _ItineraryItem extends StatelessWidget {
  final dynamic day;
  final bool isLast;

  const _ItineraryItem({required this.day, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 36,
            child: Column(
              children: [
                // Day circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.royalBlue, _C.cyan],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _C.skyBlue.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${day.dayNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _C.skyBlue.withOpacity(0.4),
                            _C.skyBlue.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.title,
                    style: const TextStyle(
                      color: _C.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.description,
                    style: const TextStyle(
                      color: _C.slate400,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
