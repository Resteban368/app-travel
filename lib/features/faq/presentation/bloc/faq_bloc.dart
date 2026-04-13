import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/faq_repository.dart';
import 'faq_event.dart';
import 'faq_state.dart';

class FaqBloc extends Bloc<FaqEvent, FaqState> {
  final FaqRepository _faqRepository;

  FaqBloc({required FaqRepository faqRepository})
    : _faqRepository = faqRepository,
      super(FaqInitial()) {
    on<LoadFaqs>(_onLoadFaqs);
    on<CreateFaq>(_onCreateFaq);
    on<UpdateFaq>(_onUpdateFaq);
    on<DeleteFaq>(_onDeleteFaq);
    on<ToggleFaqActive>(_onToggleFaqActive);
  }

  Future<void> _onLoadFaqs(LoadFaqs event, Emitter<FaqState> emit) async {
    emit(FaqLoading());
    try {
      final faqs = await _faqRepository.getFaqs();
      emit(FaqsLoaded(faqs));
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<void> _onCreateFaq(CreateFaq event, Emitter<FaqState> emit) async {
    final currentFaqs = state is FaqsLoaded ? (state as FaqsLoaded).faqs : null;
    emit(FaqSaving(currentFaqs));
    try {
      await _faqRepository.createFaq(event.faq);
      emit(FaqSaved(currentFaqs));
      add(LoadFaqs());
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<void> _onUpdateFaq(UpdateFaq event, Emitter<FaqState> emit) async {
    final currentFaqs = state is FaqsLoaded ? (state as FaqsLoaded).faqs : null;
    emit(FaqSaving(currentFaqs));
    try {
      await _faqRepository.updateFaq(event.faq);
      emit(FaqSaved(currentFaqs));
      add(LoadFaqs());
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<void> _onDeleteFaq(DeleteFaq event, Emitter<FaqState> emit) async {
    final currentFaqs = state is FaqsLoaded ? (state as FaqsLoaded).faqs : null;
    emit(FaqSaving(currentFaqs));
    try {
      await _faqRepository.deleteFaq(event.id);
      emit(FaqSaved(currentFaqs));
      add(LoadFaqs());
    } catch (e) {
      emit(FaqError(e.toString()));
    }
  }

  Future<void> _onToggleFaqActive(
    ToggleFaqActive event,
    Emitter<FaqState> emit,
  ) async {
    final currentState = state;
    if (currentState is FaqsLoaded) {
      final currentFaqs = currentState.faqs;
      emit(FaqSaving(currentFaqs));
      try {
        final faq = currentFaqs.firstWhere((f) => f.id == event.id);
        final updated = faq.copyWith(isActive: !faq.isActive);
        await _faqRepository.updateFaq(updated);
        emit(FaqSaved(currentFaqs));
        add(LoadFaqs());
      } catch (e) {
        emit(FaqError(e.toString()));
      }
    }
  }
}
