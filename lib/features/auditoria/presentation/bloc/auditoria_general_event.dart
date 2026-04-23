import 'package:equatable/equatable.dart';

abstract class AuditoriaGeneralEvent extends Equatable {
  const AuditoriaGeneralEvent();

  @override
  List<Object?> get props => [];
}

class LoadAuditoriaGeneral extends AuditoriaGeneralEvent {
  const LoadAuditoriaGeneral();
}
