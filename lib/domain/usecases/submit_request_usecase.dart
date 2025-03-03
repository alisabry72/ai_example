import 'package:either_dart/either.dart';
import '../entities/request.dart';
import '../repositories/request_repository.dart';
import '../failures/failures.dart';

class SubmitRequestUseCase {
  final RequestRepository repository;

  SubmitRequestUseCase(this.repository);

  Future<Either<Failure, bool>> call(Request request) {
    return repository.submitRequest(request);
  }
}
