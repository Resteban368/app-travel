import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';

// ─── Events ──────────────────────────────────────────────

abstract class TourEvent extends Equatable {
  const TourEvent();
  @override
  List<Object?> get props => [];
}

class LoadTours extends TourEvent {}

class CreateTour extends TourEvent {
  final Tour tour;
  const CreateTour(this.tour);
  @override
  List<Object?> get props => [tour];
}

class UpdateTour extends TourEvent {
  final Tour tour;
  const UpdateTour(this.tour);
  @override
  List<Object?> get props => [tour];
}

class DeleteTour extends TourEvent {
  final String id;
  const DeleteTour(this.id);
  @override
  List<Object?> get props => [id];
}

class FilterTours extends TourEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minPrice;
  final double? maxPrice;

  const FilterTours({
    this.startDate,
    this.endDate,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [startDate, endDate, minPrice, maxPrice];
}

class ToggleTourActive extends TourEvent {
  final String id;
  const ToggleTourActive(this.id);
  @override
  List<Object?> get props => [id];
}

class PublishTour extends TourEvent {
  final String id;
  const PublishTour(this.id);
  @override
  List<Object?> get props => [id];
}

// ─── States ──────────────────────────────────────────────

abstract class TourState extends Equatable {
  const TourState();
  @override
  List<Object?> get props => [];
}

class TourInitial extends TourState {}

class TourLoading extends TourState {}

class ToursLoaded extends TourState {
  final List<Tour> tours;
  final List<Tour> filteredTours;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final double? filterMinPrice;
  final double? filterMaxPrice;

  const ToursLoaded({
    required this.tours,
    required this.filteredTours,
    this.filterStartDate,
    this.filterEndDate,
    this.filterMinPrice,
    this.filterMaxPrice,
  });

  @override
  List<Object?> get props => [
    tours,
    filteredTours,
    filterStartDate,
    filterEndDate,
    filterMinPrice,
    filterMaxPrice,
  ];
}

class TourSaving extends TourState {
  final List<Tour>? tours;
  const TourSaving({this.tours});
  @override
  List<Object?> get props => [tours];
}

class TourSaved extends TourState {
  final List<Tour>? tours;
  const TourSaved({this.tours});
  @override
  List<Object?> get props => [tours];
}

class TourError extends TourState {
  final String message;
  const TourError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────

class TourBloc extends Bloc<TourEvent, TourState> {
  final TourRepository _tourRepository;

  TourBloc({required TourRepository tourRepository})
    : _tourRepository = tourRepository,
      super(TourInitial()) {
    on<LoadTours>(_onLoadTours);
    on<CreateTour>(_onCreateTour);
    on<UpdateTour>(_onUpdateTour);
    on<DeleteTour>(_onDeleteTour);
    on<FilterTours>(_onFilterTours);
    on<ToggleTourActive>(_onToggleTourActive);
    on<PublishTour>(_onPublishTour);
  }

  Future<void> _onLoadTours(LoadTours event, Emitter<TourState> emit) async {
    emit(TourLoading());
    try {
      final tours = await _tourRepository.getTours();
      emit(ToursLoaded(tours: tours, filteredTours: tours));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onCreateTour(CreateTour event, Emitter<TourState> emit) async {
    final currentState = state;
    final currentTours = currentState is ToursLoaded
        ? currentState.tours
        : null;
    emit(TourSaving(tours: currentTours));
    try {
      await _tourRepository.createTour(event.tour);
      final tours = await _tourRepository.getTours();
      emit(TourSaved(tours: tours));
      emit(ToursLoaded(tours: tours, filteredTours: tours));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onUpdateTour(UpdateTour event, Emitter<TourState> emit) async {
    final currentState = state;
    final currentTours = currentState is ToursLoaded
        ? currentState.tours
        : null;
    emit(TourSaving(tours: currentTours));
    try {
      await _tourRepository.updateTour(event.tour);
      final tours = await _tourRepository.getTours();
      emit(TourSaved(tours: tours));
      emit(ToursLoaded(tours: tours, filteredTours: tours));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onDeleteTour(DeleteTour event, Emitter<TourState> emit) async {
    final currentState = state;
    final currentTours = currentState is ToursLoaded
        ? currentState.tours
        : null;
    emit(TourSaving(tours: currentTours));
    try {
      await _tourRepository.deleteTour(event.id);
      final tours = await _tourRepository.getTours();
      emit(TourSaved(tours: tours));
      emit(ToursLoaded(tours: tours, filteredTours: tours));
    } catch (e) {
      emit(TourError(e.toString()));
    }
  }

  Future<void> _onFilterTours(
    FilterTours event,
    Emitter<TourState> emit,
  ) async {
    final currentState = state;
    if (currentState is ToursLoaded) {
      List<Tour> filtered = List.from(currentState.tours);

      if (event.startDate != null) {
        filtered = filtered
            .where((t) => !t.endDate.isBefore(event.startDate!))
            .toList();
      }
      if (event.endDate != null) {
        filtered = filtered
            .where((t) => !t.startDate.isAfter(event.endDate!))
            .toList();
      }
      if (event.minPrice != null) {
        filtered = filtered.where((t) => t.price >= event.minPrice!).toList();
      }
      if (event.maxPrice != null) {
        filtered = filtered.where((t) => t.price <= event.maxPrice!).toList();
      }

      emit(
        ToursLoaded(
          tours: currentState.tours,
          filteredTours: filtered,
          filterStartDate: event.startDate,
          filterEndDate: event.endDate,
          filterMinPrice: event.minPrice,
          filterMaxPrice: event.maxPrice,
        ),
      );
    }
  }

  Future<void> _onToggleTourActive(
    ToggleTourActive event,
    Emitter<TourState> emit,
  ) async {
    final currentState = state;
    if (currentState is ToursLoaded ||
        currentState is TourSaving ||
        currentState is TourSaved) {
      List<Tour>? currentTours;
      if (currentState is ToursLoaded) currentTours = currentState.tours;
      if (currentState is TourSaving) currentTours = currentState.tours;
      if (currentState is TourSaved) currentTours = currentState.tours;

      if (currentTours != null) {
        emit(TourSaving(tours: currentTours));
        try {
          final tour = currentTours.firstWhere((t) => t.id == event.id);
          await _tourRepository.toggleActive(event.id, !tour.isActive);
          final updatedList = await _tourRepository.getTours();
          emit(TourSaved(tours: updatedList));
          emit(ToursLoaded(tours: updatedList, filteredTours: updatedList));
        } catch (e) {
          emit(TourError(e.toString()));
        }
      }
    }
  }

  Future<void> _onPublishTour(
    PublishTour event,
    Emitter<TourState> emit,
  ) async {
    final currentState = state;
    if (currentState is ToursLoaded ||
        currentState is TourSaving ||
        currentState is TourSaved) {
      List<Tour>? currentTours;
      if (currentState is ToursLoaded) currentTours = currentState.tours;
      if (currentState is TourSaving) currentTours = currentState.tours;
      if (currentState is TourSaved) currentTours = currentState.tours;

      if (currentTours != null) {
        emit(TourSaving(tours: currentTours));
        try {
          final tour = currentTours.firstWhere((t) => t.id == event.id);
          final updated = tour.copyWith(isDraft: false);
          await _tourRepository.updateTour(updated);
          final updatedList = await _tourRepository.getTours();
          emit(TourSaved(tours: updatedList));
          emit(ToursLoaded(tours: updatedList, filteredTours: updatedList));
        } catch (e) {
          emit(TourError(e.toString()));
        }
      }
    }
  }
}
