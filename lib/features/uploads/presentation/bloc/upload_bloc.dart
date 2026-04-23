import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/upload_repository.dart';
import 'upload_event.dart';
import 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadRepository repository;

  UploadBloc({required this.repository}) : super(const UploadInitial()) {
    on<UploadFile>(_onUploadFile);
    on<ResetUpload>((_, emit) => emit(const UploadInitial()));
  }

  Future<void> _onUploadFile(
    UploadFile event,
    Emitter<UploadState> emit,
  ) async {
    emit(const UploadLoading());
    try {
      final result = await repository.uploadFile(
        folderId: event.folderId,
        filename: event.filename,
        bytes: event.bytes,
        mimeType: event.mimeType,
      );
      emit(UploadSuccess(result));
    } catch (e) {
      emit(UploadError(e.toString()));
    }
  }
}
