import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:oil_collection_app/service/remote_request.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../domain/entities/request.dart';
import '../../domain/usecases/extract_information_usecase.dart';
import '../../domain/usecases/process_speech_usecase.dart';
import '../../domain/usecases/submit_request_usecase.dart';
import 'request_state.dart';

class RequestCubit extends Cubit<RequestState> {
  final ExtractInformationUseCase extractInformationUseCase;
  final RemoteRequest requestRemote;
  final ProcessSpeechUseCase processSpeechUseCase;
  final SubmitRequestUseCase submitRequestUseCase;

  final stt.SpeechToText _speechToText = GetIt.instance<stt.SpeechToText>();
  final FlutterTts _flutterTts = FlutterTts();

  Request _currentRequest = Request();

  RequestCubit({
    required this.extractInformationUseCase,
    required this.processSpeechUseCase,
    required this.submitRequestUseCase,
    required this.requestRemote,
  }) : super(RequestInitial()) {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
    await _flutterTts.setLanguage('ar-SA'); // Arabic language for TTS
  }

  Future<void> sendMessge(String message) async {
    emit(RequestProcessing());
    final response = await requestRemote.predictIntent(message);
    emit(RequestUpdated(responseMessage: response, request: Request()));
  }

  Future<void> startListening() async {
    if (_speechToText.isAvailable) {
      emit(RequestListening());
      await _speechToText.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String text = result.recognizedWords;
            await processText(text);
          }
        },
        localeId: 'ar-SA', // Arabic language for STT
      );
    } else {
      emit(RequestError('Speech recognition not available'));
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    if (state is RequestListening) {
      emit(RequestInitial());
    }
  }

  Future<void> processText(String text) async {
    emit(RequestProcessing());

    // Extract information from text
    final result = await extractInformationUseCase(text, _currentRequest);

    result.fold((failure) => emit(RequestError(failure.message)),
        (updatedRequest) {
      _currentRequest = updatedRequest;

      // Check what information is still missing
      String? missingField;
      String responseMessage;

      if (_currentRequest.quantity == null) {
        missingField = 'quantity';
        responseMessage = 'كم كيلو من الزيت تريد أن نجمع؟';
      } else if (_currentRequest.address == null) {
        missingField = 'address';
        responseMessage = 'ما هو عنوان الاستلام؟';
      } else if (_currentRequest.collectionDate == null) {
        missingField = 'collectionDate';
        responseMessage = 'متى تريد أن نقوم بالاستلام؟';
      } else if (_currentRequest.giftSelection == null) {
        missingField = 'giftSelection';
        responseMessage = 'ما هي الهدية التي تفضلها؟';
      } else {
        // All information is complete
        responseMessage =
            'سنقوم بجمع ${_currentRequest.quantity} كيلو من الزيت من العنوان ${_currentRequest.address} '
            'في تاريخ ${_currentRequest.collectionDate}. وسنقدم لك هدية ${_currentRequest.giftSelection}. '
            'هل ترغب في تأكيد الطلب؟';
        emit(RequestCompleted(_currentRequest));
        _speak(responseMessage);
        return;
      }

      // Emit the updated state with missing field information
      emit(RequestUpdated(
        request: _currentRequest,
        missingField: missingField,
        responseMessage: responseMessage,
      ));

      // Speak the response to the user
      _speak(responseMessage);
    });
  }

  Future<void> submitRequest() async {
    if (_currentRequest.isComplete) {
      emit(RequestSubmitting());

      final result = await submitRequestUseCase(_currentRequest);

      result.fold((failure) => emit(RequestError(failure.message)), (success) {
        emit(RequestSubmitted());
        _speak('تم تقديم طلبك بنجاح! سنتواصل معك قريبا.');
        // Reset the request
        _currentRequest = Request();
      });
    } else {
      emit(RequestError('لا يمكن تقديم الطلب، بعض المعلومات مفقودة'));
      _speak('لا يمكن تقديم الطلب، بعض المعلومات مفقودة');
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void reset() {
    _currentRequest = Request();
    emit(RequestInitial());
  }
}
