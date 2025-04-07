import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:oil_collection_app/data/services/data_predection_service.dart';
import 'package:oil_collection_app/service/remote_request.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../domain/entities/request.dart';
import 'request_state.dart';

class RequestCubit extends Cubit<RequestState> {
  final RemoteRequest requestRemote;
  final stt.SpeechToText _speechToText = GetIt.instance<stt.SpeechToText>();
  final FlutterTts _flutterTts = FlutterTts();

  Request _currentRequest = Request();
  final String _userId =
      "user123"; // Replace with dynamic user ID (e.g., from auth)

  RequestCubit({
    required this.requestRemote,
  }) : super(RequestInitial()) {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool speechInitialized = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech init error: $error'),
    );
    if (!speechInitialized) {
      emit(RequestError('فشل تهيئة التعرف على الكلام'));
    }
    var isLanguageAvailable = await _flutterTts.isLanguageAvailable('ar');
    final voices = await _flutterTts.getVoices;
    debugPrint('Available voices: $voices');

    debugPrint('Is language available: $isLanguageAvailable');
    await _flutterTts.setLanguage('ar-SA');
    await _flutterTts.setSpeechRate(0.5); // Adjust speed if needed
    debugPrint('Speech and TTS initialized');
  }

  Future<void> sendMessage(String message, {bool fromSpeech = false}) async {
    if (message.trim().isEmpty) return;

    emit(RequestProcessing());
    debugPrint('Sending message: $message (fromSpeech: $fromSpeech)');

    // Speak the user's message if it came from STT
    if (fromSpeech) {
      await _speak("قلت: $message"); // e.g., "قلت: السلام عليكم"
    }

    try {
      final response =
          await IntentPredictionService().predictIntent(message, _userId);
      debugPrint('Backend response: ${response.toString()}');
      final data = response['data'];
      final intent = data['predicted_intent'];
      final responseMessage = data['response'];
      final state = data['state'];

      // Update Request based on backend intent
      switch (intent) {
        case 'provide_quantity':
          final match = RegExp(r'\d+').firstMatch(message);
          if (match != null) {
            _currentRequest =
                _currentRequest.copyWith(quantity: match.group(0));
          }
          break;
        case 'provide_address':
          _currentRequest = _currentRequest.copyWith(address: message.trim());
          break;
        case 'choose_gift':
          _currentRequest =
              _currentRequest.copyWith(giftSelection: message.trim());
          break;
        case 'submit_order':
          if (_currentRequest.quantity != null &&
              _currentRequest.address != null) {
            emit(RequestSubmitting());
            emit(RequestSubmitted());
            _speak(responseMessage);
            _currentRequest = Request(); // Reset after submission
            return;
          } else {
            emit(RequestError('معلومات الطلب غير مكتملة'));
            _speak('معلومات الطلب غير مكتملة');
            return;
          }
      }

      emit(RequestUpdated(
        responseMessage: responseMessage,
        request: _currentRequest,
        state: state,
      ));
      _speak(responseMessage);
    } on Exception catch (e) {
      debugPrint('Error in sendMessage: $e');
      emit(RequestError(e.toString()));
      _speak('حدث خطأ، حاول مرة أخرى');
    }
  }

  Future<void> startListening() async {
    if (_speechToText.isAvailable && !_speechToText.isListening) {
      emit(RequestListening());
      await _speechToText.listen(
        onResult: (result) async {
          debugPrint('Speech result: ${result.recognizedWords}');
          if (result.finalResult) {
            String text = result.recognizedWords;
            debugPrint('Speech recognized: $text');
            if (text.isNotEmpty) {
              await sendMessage(text, fromSpeech: true); // Process spoken input
            }
          }
        },
        localeId: 'ar-SA',
        onSoundLevelChange: (level) => debugPrint('Sound level: $level'),
      );
    } else {
      emit(RequestError('التعرف على الكلام غير متاح أو قيد التشغيل بالفعل'));
      _speak('التعرف على الكلام غير متاح');
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    if (state is RequestListening) {
      emit(RequestInitial());
    }
  }

  Future<void> _speak(String text) async {
    debugPrint('Speaking: $text');
    await _flutterTts.speak(text);
  }

  void reset() {
    _currentRequest = Request();
    emit(RequestInitial());
  }
}
