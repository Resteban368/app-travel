import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';

// ─── Events ──────────────────────────────────────────────

abstract class TourHistoricoEvent extends Equatable {
  const TourHistoricoEvent();
  @override
  List<Object?> get props => [];
}

class LoadToursHistoricos extends TourHistoricoEvent {}

class FilterToursHistoricos extends TourHistoricoEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterToursHistoricos({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

// ─── States ──────────────────────────────────────────────

abstract class TourHistoricoState extends Equatable {
  const TourHistoricoState();
  @override
  List<Object?> get props => [];
}

class TourHistoricoInitial extends TourHistoricoState {}

class TourHistoricoLoading extends TourHistoricoState {}

class ToursHistoricosLoaded extends TourHistoricoState {
  final List<Tour> tours;
  final List<Tour> filteredTours;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  const ToursHistoricosLoaded({
    required this.tours,
    required this.filteredTours,
    this.filterStartDate,
    this.filterEndDate,
  });

  @override
  List<Object?> get props => [tours, filteredTours, filterStartDate, filterEndDate];
}

class TourHistoricoError extends TourHistoricoState {
  final String message;
  const TourHistoricoError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────

class TourHistoricoBloc extends Bloc<TourHistoricoEvent, TourHistoricoState> {
  final TourRepository _tourRepository;

  TourHistoricoBloc({required TourRepository tourRepository})
    : _tourRepository = tourRepository,
      super(TourHistoricoInitial()) {
    on<LoadToursHistoricos>(_onLoad);
    on<FilterToursHistoricos>(_onFilter);
  }

  Future<void> _onLoad(
    LoadToursHistoricos event,
    Emitter<TourHistoricoState> emit,
  ) async {
    emit(TourHistoricoLoading());
    try {
      final tours = await _tourRepository.getToursHistoricos();
      emit(ToursHistoricosLoaded(tours: tours, filteredTours: tours));
    } catch (e) {
      emit(TourHistoricoError(e.toString()));
    }
  }

  Future<void> _onFilter(
    FilterToursHistoricos event,
    Emitter<TourHistoricoState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ToursHistoricosLoaded) return;

    List<Tour> filtered = List.from(currentState.tours);

    if (event.startDate != null) {
      filtered = filtered
          .where((t) => t.endDate != null && !t.endDate!.isBefore(event.startDate!))
          .toList();
    }
    if (event.endDate != null) {
      filtered = filtered
          .where((t) => t.startDate != null && !t.startDate!.isAfter(event.endDate!))
          .toList();
    }

    emit(ToursHistoricosLoaded(
      tours: currentState.tours,
      filteredTours: filtered,
      filterStartDate: event.startDate,
      filterEndDate: event.endDate,
    ));
  }
}
