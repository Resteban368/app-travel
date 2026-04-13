import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:agente_viajes/features/tour/presentation/screens/tour_form_screen.dart';
import 'package:agente_viajes/features/tour/domain/repositories/tour_repository.dart';
import 'package:agente_viajes/features/settings/domain/repositories/sede_repository.dart';
import 'package:agente_viajes/features/tour/presentation/bloc/tour_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/sede_bloc.dart';
import 'package:agente_viajes/features/settings/domain/entities/sede.dart';
import 'package:get_it/get_it.dart';

// Manual Mocks
class MockTourRepository extends Fake implements TourRepository {}

class MockSedeRepository extends Fake implements SedeRepository {
  @override
  Future<List<Sede>> getSedes() async => [
    const Sede(
      id: 'sede1',
      nombreSede: 'Sede Test',
      telefono: '123',
      direccion: 'Dir',
      linkMap: 'Link',
    ),
  ];
}

void main() {
  final sl = GetIt.instance;

  setUp(() {
    sl.reset();
    sl.registerLazySingleton<TourRepository>(() => MockTourRepository());
    sl.registerLazySingleton<SedeRepository>(() => MockSedeRepository());
    sl.registerFactory(() => TourBloc(tourRepository: sl()));
    sl.registerFactory(() => SedeBloc(sedeRepository: sl()));
  });

  group('TourFormScreen Verification', () {
    final testTour = Tour(
      id: '123',
      idTour: 123,
      name: 'Test Tour',
      agency: 'Test Agency',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 5),
      price: 500000,
      departurePoint: 'Test Start',
      departureTime: '08:00 AM',
      arrival: 'Test End',
      pdfLink: 'http://test.com/pdf',
      imageUrl: 'http://test.com/img.jpg',
      inclusions: const ['Inclusion 1'],
      exclusions: const ['Exclusion 1'],
      itinerary: const [
        ItineraryDay(
          dayNumber: 1,
          title: 'Day 1 Title',
          description: 'Day 1 Desc',
        ),
      ],
      sedeId: 'sede1',
      isPromotion: true,
      isActive: true,
      isDraft: false,
    );

    testWidgets('should pre-populate fields in edit mode', (
      WidgetTester tester,
    ) async {
      // Set screen size to avoid overflows
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(home: TourFormScreen(tour: testTour)),
      );

      // Verify basic text fields
      expect(find.text('Test Tour'), findsOneWidget);
      expect(find.text('Test Agency'), findsOneWidget);
      expect(find.text('500000'), findsOneWidget);

      // Verify list items
      expect(find.text('Inclusion 1'), findsOneWidget);
      expect(find.text('Exclusion 1'), findsOneWidget);

      // Verify itinerary
      expect(find.text('Day 1 Title'), findsOneWidget);

      // Verify switches
      final promoSwitch = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile).first,
      );
      expect(promoSwitch.value, true);
    });
  });
}
