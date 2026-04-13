import 'package:equatable/equatable.dart';
import '../../domain/entities/faq.dart';

abstract class FaqState extends Equatable {
  const FaqState();
  @override
  List<Object?> get props => [];
}

class FaqInitial extends FaqState {}

class FaqLoading extends FaqState {}

class FaqsLoaded extends FaqState {
  final List<Faq> faqs;
  const FaqsLoaded(this.faqs);
  @override
  List<Object?> get props => [faqs];
}

class FaqError extends FaqState {
  final String message;
  const FaqError(this.message);
  @override
  List<Object?> get props => [message];
}

class FaqSaving extends FaqState {
  final List<Faq>? faqs;
  const FaqSaving([this.faqs]);
  @override
  List<Object?> get props => [faqs];
}

class FaqSaved extends FaqState {
  final List<Faq>? faqs;
  const FaqSaved([this.faqs]);
  @override
  List<Object?> get props => [faqs];
}
