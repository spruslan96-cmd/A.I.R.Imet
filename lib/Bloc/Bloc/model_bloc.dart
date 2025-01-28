// Bloc Implementation
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ai_chat/Bloc/Events/model_events.dart';
import 'package:local_ai_chat/Bloc/States/model_states.dart';
import 'package:path_provider/path_provider.dart';

class ModelBloc extends Bloc<ModelEvent, ModelState> {
  ModelBloc() : super(ModelInitial());

  Stream<ModelState> mapEventToState(ModelEvent event) async* {
    if (event is CheckModelEvent) {
      yield ModelChecking();
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/llama_model.tflite';
      final exists = File(modelPath).existsSync();
      if (exists) {
        yield ModelExists();
      } else {
        yield ModelNotExists();
      }
    } else if (event is DownloadModelEvent) {
      yield ModelDownloading();
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/llama_model.tflite';
      final url = event.modelSize == '1B'
          ? 'https://example.com/llama_1b.tflite'
          : 'https://example.com/llama_3b.tflite';
      try {
        Dio dio = Dio();
        await dio.download(url, modelPath,
            onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                'Downloading: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        });
        yield ModelDownloaded();
      } catch (e) {
        yield ModelError('Error downloading model: $e');
      }
    }
  }
}
