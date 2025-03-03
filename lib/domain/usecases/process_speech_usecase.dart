import 'package:either_dart/either.dart';
import '../repositories/request_repository.dart';
import '../failures/failures.dart';

class ProcessSpeechUseCase {
  final RequestRepository repository;

  ProcessSpeechUseCase(this.repository);

  Future<Either<Failure, String>> call(String audioPath) {
    return repository.processSpeech(audioPath);
  }
}
