import 'package:oil_collection_app/domain/entities/request.dart';

abstract class RequestState {}

class RequestInitial extends RequestState {}

class RequestProcessing extends RequestState {}

class RequestListening extends RequestState {}

class RequestUpdated extends RequestState {
  final String responseMessage;
  final Request request;
  final String state;

  RequestUpdated(
      {required this.responseMessage,
      required this.request,
      required this.state});
}

class RequestSubmitting extends RequestState {}

class RequestSubmitted extends RequestState {}

class RequestError extends RequestState {
  final String message;

  RequestError(this.message);
}
