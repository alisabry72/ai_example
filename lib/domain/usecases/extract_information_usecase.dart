import 'package:either_dart/either.dart';
import '../entities/request.dart';
import '../repositories/request_repository.dart';
import '../failures/failures.dart';

class ExtractInformationUseCase {
  final RequestRepository repository;

  ExtractInformationUseCase(this.repository);

  Future<Either<Failure, Request>> call(String text, Request currentRequest) {
    return repository.extractInformation(text, currentRequest);
  }
}
