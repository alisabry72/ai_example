import 'package:either_dart/either.dart';
import '../entities/request.dart';
import '../failures/failures.dart';

abstract class RequestRepository {
  Future<Either<Failure, String>> processSpeech(String audioPath);
  Future<Either<Failure, Request>> extractInformation(
      String text, Request currentRequest);
  Future<Either<Failure, bool>> submitRequest(Request request);
}
