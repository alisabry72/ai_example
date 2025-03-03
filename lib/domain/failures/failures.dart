abstract class Failure {
  final String message;

  Failure(this.message);
}

class SpeechProcessingFailure extends Failure {
  SpeechProcessingFailure(String message) : super(message);
}

class InformationExtractionFailure extends Failure {
  InformationExtractionFailure(String message) : super(message);
}

class SubmissionFailure extends Failure {
  SubmissionFailure(String message) : super(message);
}
