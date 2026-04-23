import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: SaasPalette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Hero image ──────────────────────────────────────────────
                _HeroSection(tour: tour, currencyFormat: _currencyFormat),

                // ── Body ────────────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price row + agency
                        _PriceAgencyRow(
                          tour: tour,
                          currencyFormat: _currencyFormat,
                        ),
                        const SizedBox(height: 24),

                        // Info chips
                        _InfoGrid(tour: tour, dateFormat: dateFormat),
                        const SizedBox(height: 24),

                        // Inclusions
                        if (tour.inclusions.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.check_circle_rounded,
                            label: 'Incluye',
                            color: SaasPalette.success,
                          ),
                          const SizedBox(height: 12),
                          ...tour.inclusions.map(
                            (item) => _ListItem(
                              text: item,
                              icon: Icons.check_rounded,
                              color: SaasPalette.success,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Exclusions
                        if (tour.exclusions.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.cancel_rounded,
                            label: 'No incluye',
                            color: SaasPalette.danger,
                          ),
                          const SizedBox(height: 12),
                          ...tour.exclusions.map(
                            (item) => _ListItem(
                              text: item,
                              icon: Icons.close_rounded,
                              color: SaasPalette.danger,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Itinerary
                        if (tour.itinerary.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.map_rounded,
                            label: 'Itinerario',
                            color: SaasPalette.brand600,
                          ),
                          const SizedBox(height: 16),
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

class _HeroSection extends StatelessWidget {
  final Tour tour;
  final NumberFormat currencyFormat;

  const _HeroSection({required this.tour, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Badges
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                if (tour.isPromotion)
                  _Tag(label: 'PROMO', color: SaasPalette.warning),
                if (!tour.isActive) ...[
                  if (tour.isPromotion) const SizedBox(width: 8),
                  _Tag(label: 'INACTIVO', color: SaasPalette.danger),
                ],
              ],
            ),
          ),

          // Bottom Info
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.name,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tour.departurePoint,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PriceAgencyRow extends StatelessWidget {
  final Tour tour;
  final NumberFormat currencyFormat;
  const _PriceAgencyRow({required this.tour, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Precio por persona',
                  style: TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  currencyFormat.format(tour.price),
                  style: const TextStyle(
                    color: SaasPalette.brand600,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: SaasPalette.border),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agencia Operadora',
                  style: TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  tour.agency,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
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

class _InfoGrid extends StatelessWidget {
  final Tour tour;
  final DateFormat dateFormat;
  const _InfoGrid({required this.tour, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.calendar_today_rounded,
        'Periodo',
        '${dateFormat.format(tour.startDate)} - ${dateFormat.format(tour.endDate)}',
      ),
      (Icons.alarm_rounded, 'Hora Salida', tour.departureTime),
      (Icons.flight_land_rounded, 'Llegada', tour.arrival),
      (Icons.map_rounded, 'Destino', tour.departurePoint),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: SaasPalette.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(items[i].$1, size: 16, color: SaasPalette.brand600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    items[i].$2,
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    items[i].$3,
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryItem extends StatelessWidget {
  final dynamic day;
  final bool isLast;
  const _ItineraryItem({required this.day, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: SaasPalette.brand600,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.dayNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: SaasPalette.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.title,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                day.description,
                style: const TextStyle(
                  color: SaasPalette.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
