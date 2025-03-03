import 'dart:convert';

import 'package:either_dart/either.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/request.dart';
import '../../domain/failures/failures.dart';
import 'regex_extraction_service.dart';

abstract class NlpService {
  Future<Either<Failure, String>> convertSpeechToText(String audioPath);
  Future<Either<Failure, Request>> extractEntities(
      String text, Request currentRequest);
  Future<Either<Failure, bool>> submitRequestData(Request request);
}

class NlpServiceImpl implements NlpService {
  final http.Client client;
  final RegexExtractionService _regexService;
  final String apiUrl = 'https://your-api-endpoint.com';

  NlpServiceImpl({required this.client})
      : _regexService = RegexExtractionService();

  @override
  Future<Either<Failure, String>> convertSpeechToText(String audioPath) async {
    try {
      // This is handled directly at the UI level through speech_to_text package
      // For offline audio processing, we would need a different approach
      final response = await client.post(
        Uri.parse('$apiUrl/speech-to-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'audio_path': audioPath}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(data['text']);
      } else {
        return Left(SpeechProcessingFailure('Failed to process speech'));
      }
    } catch (e) {
      return Left(SpeechProcessingFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Request>> extractEntities(
      String text, Request currentRequest) async {
    try {
      // Use only regex-based extraction
      final extractedEntities = _regexService.extractEntities(text);

      // Update only the fields that were extracted
      return Right(Request(
        quantity: extractedEntities['quantity'] ?? currentRequest.quantity,
        address: extractedEntities['address'] ?? currentRequest.address,
        collectionDate: extractedEntities['collection_date'] ??
            currentRequest.collectionDate,
        giftSelection:
            extractedEntities['gift_selection'] ?? currentRequest.giftSelection,
      ));
    } catch (e) {
      return Left(InformationExtractionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitRequestData(Request request) async {
    try {
      final response = await client.post(
        Uri.parse('$apiUrl/submit-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'quantity': request.quantity,
          'address': request.address,
          'collection_date': request.collectionDate,
          'gift_selection': request.giftSelection,
        }),
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(SubmissionFailure('Failed to submit request'));
      }
    } catch (e) {
      return Left(SubmissionFailure(e.toString()));
    }
  }
}
