import 'package:equatable/equatable.dart';
import '../../domain/entities/request.dart';

abstract class RequestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RequestInitial extends RequestState {}

class RequestListening extends RequestState {}

class RequestProcessing extends RequestState {}

class RequestUpdated extends RequestState {
  final Request request;
  final String? missingField;
  final String? responseMessage;

  RequestUpdated({
    required this.request,
    this.missingField,
    this.responseMessage,
  });

  @override
  List<Object?> get props => [request, missingField, responseMessage];
}

class RequestCompleted extends RequestState {
  final Request request;

  RequestCompleted(this.request);

  @override
  List<Object?> get props => [request];
}

class RequestSubmitting extends RequestState {}

class RequestSubmitted extends RequestState {}

class RequestError extends RequestState {
  final String message;

  RequestError(this.message);

  @override
  List<Object?> get props => [message];
}
