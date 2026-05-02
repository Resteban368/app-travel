import 'package:equatable/equatable.dart';
import 'tour_precio.dart';

/// Represents a day in the tour itinerary.
class ItineraryDay extends Equatable {
  final int dayNumber;
  final String title;
  final String description;

  const ItineraryDay({
    required this.dayNumber,
    required this.title,
    required this.description,
  });

  ItineraryDay copyWith({int? dayNumber, String? title, String? description}) {
    return ItineraryDay(
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [dayNumber, title, description];
}

/// Represents a tour/excursion plan.
class Tour extends Equatable {
  final String id;
  final int idTour;
  final String name;
  final String agency;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String departurePoint;
  final String departureTime;
  final String arrival;
  final String pdfLink;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<ItineraryDay> itinerary;
  final String? sedeId;
  final bool isPromotion;
  final bool isActive;
  final bool isDraft;
  final bool precioPorPareja;
  final int? cupos;
  final int? cuposDisponibles;
  final List<TourPrecio> precios;

  const Tour({
    required this.id,
    required this.idTour,
    required this.name,
    required this.agency,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.departurePoint,
    required this.departureTime,
    required this.arrival,
    required this.pdfLink,
    required this.inclusions,
    required this.exclusions,
    required this.itinerary,
    this.sedeId,
    this.isPromotion = false,
    this.isActive = true,
    this.isDraft = true,
    this.precioPorPareja = false,
    this.cupos,
    this.cuposDisponibles,
    this.precios = const [],
  });

  Tour copyWith({
    String? id,
    int? idTour,
    String? name,
    String? agency,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? departurePoint,
    String? departureTime,
    String? arrival,
    String? pdfLink,
    List<String>? inclusions,
    List<String>? exclusions,
    List<ItineraryDay>? itinerary,
    String? imageUrl,
    String? sedeId,
    bool? isPromotion,
    bool? isActive,
    bool? isDraft,
    bool? precioPorPareja,
    int? cupos,
    int? cuposDisponibles,
    List<TourPrecio>? precios,
  }) {
    return Tour(
      id: id ?? this.id,
      idTour: idTour ?? this.idTour,
      name: name ?? this.name,
      agency: agency ?? this.agency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      departurePoint: departurePoint ?? this.departurePoint,
      departureTime: departureTime ?? this.departureTime,
      arrival: arrival ?? this.arrival,
      pdfLink: pdfLink ?? this.pdfLink,
      inclusions: inclusions ?? this.inclusions,
      exclusions: exclusions ?? this.exclusions,
      itinerary: itinerary ?? this.itinerary,
      sedeId: sedeId ?? this.sedeId,
      isPromotion: isPromotion ?? this.isPromotion,
      isActive: isActive ?? this.isActive,
      isDraft: isDraft ?? this.isDraft,
      precioPorPareja: precioPorPareja ?? this.precioPorPareja,
      cupos: cupos ?? this.cupos,
      cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
      precios: precios ?? this.precios,
    );
  }

  @override
  List<Object?> get props => [
    id,
    idTour,
    name,
    agency,
    startDate,
    endDate,
    price,
    departurePoint,
    departureTime,
    arrival,
    pdfLink,
    inclusions,
    exclusions,
    itinerary,
    sedeId,
    isPromotion,
    isActive,
    isDraft,
    precioPorPareja,
    cupos,
    cuposDisponibles,
    precios,
  ];
}
