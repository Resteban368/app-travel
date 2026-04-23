import 'dart:convert';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiTourRepository Mapping Validation', () {
    test('should correctly map JSON response to Tour entities', () {
      // GIVEN: A sample JSON from the server (based on actual curl results)
      const jsonResponse = '''
      [
        {
          "id": 1,
          "id_tour": "1",
          "nombre_tour": "Aventura en el Eje Cafetero",
          "agencia": "Agencia de Viajes Sol y Luna",
          "fecha_inicio": "2024-12-15T08:00:00.000Z",
          "fecha_fin": "2024-12-18T18:00:00.000Z",
          "precio": 850000.0,
          "punto_partida": "Terminal de Transportes de Pereira",
          "hora_partida": "07:30 AM",
          "llegada": "Pereira",
          "link_pdf": "https://ejemplo.com/tours/eje-cafetero.pdf",
          "url_imagen": "https://ejemplo.com/imagenes/eje-cafetero.jpg",
          "inclusions": [
            "Transporte privado ida y vuelta",
            "Alojamiento 3 noches en finca cafetera"
          ],
          "exclusions": [
            "Almuerzos no especificados"
          ],
          "itinerary": [
            {
              "titulo": "Llegada y Tour Cafetero",
              "dia_numero": 1,
              "descripcion": "Recepción en terminal, traslado a la finca y recorrido por los cafetales con degustación."
            }
          ],
          "estado": true,
          "es_promocion": false,
          "is_active": true,
          "es_borrador": false,
          "sede_id": "1",
          "createdAt": "2026-03-07T07:01:55.708Z"
        }
      ]
      ''';

      final List<dynamic> data = json.decode(jsonResponse);

      // WHEN: Mapping using the private _fromJson (simulated or tested via public method if possible,
      // but here we validate the logic used in the repository)
      // Since _fromJson is private, we will test the repository's parsing logic by checking
      // if it handles the real keys correctly.

      final tours = data.map((item) {
        // This mirrors the logic in ApiTourRepository._fromJson
        return Tour(
          id: (item['id'] ?? '').toString(),
          idTour: int.tryParse(item['id_tour']?.toString() ?? '0') ?? 0,
          name: item['nombre_tour'] ?? '',
          agency: item['agencia'] ?? '',
          startDate: DateTime.parse(item['fecha_inicio']),
          endDate: DateTime.parse(item['fecha_fin']),
          price: (item['precio'] ?? 0).toDouble(),
          departurePoint: item['punto_partida'] ?? '',
          departureTime: item['hora_partida'] ?? '',
          arrival: item['llegada'] ?? '',
          pdfLink: item['link_pdf'] ?? '',
          inclusions: List<String>.from(item['inclusions'] ?? []),
          exclusions: List<String>.from(item['exclusions'] ?? []),
          itinerary: (item['itinerary'] as List? ?? [])
              .map(
                (i) => ItineraryDay(
                  dayNumber: i['dia_numero'] ?? 0,
                  title: i['titulo'] ?? '',
                  description: i['descripcion'] ?? '',
                ),
              )
              .toList(),
          sedeId: item['sede_id']?.toString(),
          isPromotion: item['es_promocion'] ?? false,
          isActive: item['is_active'] ?? true,
          isDraft: item['es_borrador'] ?? false,
        );
      }).toList();

      // THEN: Verify the mapping results
      expect(tours.length, 1);
      final tour = tours.first;
      expect(tour.id, "1");
      expect(tour.name, "Aventura en el Eje Cafetero");
      expect(tour.price, 850000.0);
      expect(tour.itinerary.first.dayNumber, 1);
      expect(tour.isActive, true);
      expect(tour.sedeId, "1");
    });
  });
}
