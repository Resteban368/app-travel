import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:agente_viajes/features/tour/presentation/screens/tour_list_screen.dart';
import 'package:agente_viajes/features/tour/domain/repositories/tour_repository.dart';
import 'package:agente_viajes/features/tour/presentation/bloc/tour_bloc.dart';
import 'package:get_it/get_it.dart';

// Manual Mock
class MockTourRepository extends Fake implements TourRepository {
  @override
  Future<List<Tour>> getTours() async {
    return [
      Tour(
        id: '1',
        idTour: 1,
        name: 'Tour 1 Verified',
        agency: 'Agency Verified',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        price: 1000,
        departurePoint: 'Point 1',
        departureTime: '10 AM',
        arrival: 'Arrival 1',
        pdfLink: '',
        imageUrl:
            'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=800',
        inclusions: const [],
        exclusions: const [],
        itinerary: const [],
      ),
    ];
  }
}

void main() {
  final sl = GetIt.instance;

  setUp(() {
    sl.reset();
    sl.registerLazySingleton<TourRepository>(() => MockTourRepository());
    sl.registerFactory(() => TourBloc(tourRepository: sl()));
  });

  testWidgets('TourListScreen should correctly render tours from BLoC', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (context) => const TourListScreen(),
          '/tours/create': (context) =>
              const Scaffold(body: Text('Create Screen')),
        },
        initialRoute: '/',
      ),
    );

    // Wait for BLoC and Animations
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify tour is displayed
    expect(find.text('Tour 1 Verified'), findsOneWidget);
    expect(find.text('Agency Verified'), findsOneWidget);

    // Verify count text
    expect(find.text('1 tour'), findsOneWidget);
  });
}
