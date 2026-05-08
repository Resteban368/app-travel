import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_layout.dart';

abstract class BusLayoutEvent extends Equatable {
  const BusLayoutEvent();

  @override
  List<Object?> get props => [];
}

class LoadBusLayouts extends BusLayoutEvent {
  const LoadBusLayouts();
}

class LoadBusLayout extends BusLayoutEvent {
  final int id;
  const LoadBusLayout(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateBusLayout extends BusLayoutEvent {
  final BusLayout layout;
  const CreateBusLayout(this.layout);

  @override
  List<Object?> get props => [layout];
}

class UpdateBusLayout extends BusLayoutEvent {
  final BusLayout layout;
  const UpdateBusLayout(this.layout);

  @override
  List<Object?> get props => [layout];
}

class DeleteBusLayout extends BusLayoutEvent {
  final int id;
  const DeleteBusLayout(this.id);

  @override
  List<Object?> get props => [id];
}
