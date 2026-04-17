import 'package:equatable/equatable.dart';
import '../../domain/entities/upload_result.dart';

abstract class UploadState extends Equatable {
  const UploadState();
  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {
  const UploadInitial();
}

class UploadLoading extends UploadState {
  const UploadLoading();
}

class UploadSuccess extends UploadState {
  final UploadResult result;
  const UploadSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class UploadError extends UploadState {
  final String message;
  const UploadError(this.message);
  @override
  List<Object?> get props => [message];
}
