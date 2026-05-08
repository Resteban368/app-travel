import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_layout.dart';

abstract class BusLayoutState extends Equatable {
  const BusLayoutState();

  @override
  List<Object?> get props => [];
}

class BusLayoutInitial extends BusLayoutState {}

class BusLayoutLoading extends BusLayoutState {}

class BusLayoutSaving extends BusLayoutState {
  final List<BusLayout>? layouts;
  const BusLayoutSaving([this.layouts]);

  @override
  List<Object?> get props => [layouts];
}

class BusLayoutLoaded extends BusLayoutState {
  final List<BusLayout> layouts;
  const BusLayoutLoaded(this.layouts);

  @override
  List<Object?> get props => [layouts];
}

class BusLayoutDetailLoaded extends BusLayoutState {
  final BusLayout layout;
  const BusLayoutDetailLoaded(this.layout);

  @override
  List<Object?> get props => [layout];
}

class BusLayoutSaved extends BusLayoutState {
  final List<BusLayout>? layouts;
  const BusLayoutSaved([this.layouts]);

  @override
  List<Object?> get props => [layouts];
}

class BusLayoutError extends BusLayoutState {
  final String message;
  const BusLayoutError(this.message);

  @override
  List<Object?> get props => [message];
}
