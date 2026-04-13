import 'package:equatable/equatable.dart';
import '../../domain/entities/faq.dart';

abstract class FaqEvent extends Equatable {
  const FaqEvent();
  @override
  List<Object?> get props => [];
}

class LoadFaqs extends FaqEvent {}

class CreateFaq extends FaqEvent {
  final Faq faq;
  const CreateFaq(this.faq);
  @override
  List<Object?> get props => [faq];
}

class UpdateFaq extends FaqEvent {
  final Faq faq;
  const UpdateFaq(this.faq);
  @override
  List<Object?> get props => [faq];
}

class DeleteFaq extends FaqEvent {
  final int id;
  const DeleteFaq(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleFaqActive extends FaqEvent {
  final int id;
  const ToggleFaqActive(this.id);
  @override
  List<Object?> get props => [id];
}
