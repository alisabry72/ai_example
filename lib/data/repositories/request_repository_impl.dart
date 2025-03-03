import 'package:either_dart/either.dart';
import '../../domain/entities/request.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/nlp_service.dart';

class RequestRepositoryImpl implements RequestRepository {
  final NlpService nlpService;

  RequestRepositoryImpl({required this.nlpService});

  @override
  Future<Either<Failure, String>> processSpeech(String audioPath) {
    return nlpService.convertSpeechToText(audioPath);
  }

  @override
  Future<Either<Failure, Request>> extractInformation(
      String text, Request currentRequest) {
    return nlpService.extractEntities(text, currentRequest);
  }

  @override
  Future<Either<Failure, bool>> submitRequest(Request request) {
    return nlpService.submitRequestData(request);
  }
}
