import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:oil_collection_app/service/remote_request.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'data/datasources/nlp_service.dart';
import 'data/repositories/request_repository_impl.dart';
import 'domain/repositories/request_repository.dart';
import 'domain/usecases/extract_information_usecase.dart';
import 'domain/usecases/process_speech_usecase.dart';
import 'domain/usecases/submit_request_usecase.dart';
import 'presentation/cubit/request_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Cubits
  sl.registerLazySingleton<RequestCubit>(
    () => RequestCubit(
      requestRemote: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => ExtractInformationUseCase(sl()));
  sl.registerLazySingleton(() => ProcessSpeechUseCase(sl()));
  sl.registerLazySingleton(() => SubmitRequestUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<RequestRepository>(
    () => RequestRepositoryImpl(nlpService: sl()),
  );
  sl.registerLazySingleton<RemoteRequest>(
    () => RemoteRequest(),
  );

  // Data sources
  sl.registerLazySingleton<NlpService>(
    () => NlpServiceImpl(client: sl()),
  );

  // External
  sl.registerLazySingleton(() => SpeechToText());
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FlutterTts());
}
