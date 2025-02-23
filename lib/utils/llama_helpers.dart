import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:path_provider/path_provider.dart';

// class ChatML extends PromptFormat {
//   ChatML({
//     required String inputSequence,
//     required String outputSequence,
//     required String systemSequence,
//     String? stopSequence,
//   }) : super(
//           PromptFormatType.chatml,
//           inputSequence: inputSequence,
//           outputSequence: outputSequence,
//           systemSequence: systemSequence,
//           stopSequence: stopSequence,
//         );
// }

class ChatMLFormat extends PromptFormat {
  ChatMLFormat({
    String inputSequence = "<|im_start|>",
    String outputSequence = "<|im_end|>",
    String systemSequence = "<|im_start|>system\n",
    String? stopSequence,
  }) : super(
          PromptFormatType.chatml,
          inputSequence: inputSequence,
          outputSequence: outputSequence,
          systemSequence: systemSequence,
          stopSequence: stopSequence,
        );

  @override
  String formatPrompt(String prompt) {
    return formatMessages([
      {'role': 'user', 'content': prompt}
    ]);
  }

  @override
  String formatMessages(List<Map<String, dynamic>> messages) {
    String formattedMessages = '';
    for (var message in messages) {
      if (message['role'] == 'user') {
        formattedMessages += '$inputSequence${message['content']}';
      } else if (message['role'] == 'assistant') {
        formattedMessages += '$outputSequence${message['content']}';
      } else if (message['role'] == 'system') {
        formattedMessages += '$systemSequence${message['content']}';
      }

      if (stopSequence != null) {
        formattedMessages += stopSequence!;
      }
    }
    return formattedMessages;
  }
}

class LlamaHelper {
  LlamaParent? _llamaParent;
  bool _modelLoaded = false;
  final chatMLFormat = ChatMLFormat();
  final chatHistory = ChatHistory();

  Future<List<String>> loadAvailableModels() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    return files
        .where((file) => file is File && file.path.endsWith('.gguf'))
        .map((file) => file.path)
        .toList();
  }

  Future<void> loadModel(String modelFileName) async {
    if (_modelLoaded) return;

    final modelPath = await getModelPath(modelFileName);
    print('MODEL PATH GOT AS: $modelPath');
    try {
      final loadCommand = LlamaLoad(
        path: modelPath,
        modelParams: ModelParams(),
        contextParams: ContextParams(),
        samplingParams: SamplerParams(),
        format: chatMLFormat,
      );

      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init(); // Initialize asynchronously

      _modelLoaded = true;
      print("LlamaHelper.loadModel: Model loaded successfully");
    } catch (e) {
      print("LlamaHelper.loadModel: Error loading model: $e");
      rethrow; // Re-throw the exception
    }
  }

  Stream<String> generateText(String prompt) async* {
    if (_llamaParent == null || !_modelLoaded) {
      throw Exception('Model not loaded');
    }

    chatHistory.addMessage(role: Role.user, content: prompt);
    final formattedPrompt = chatHistory.exportFormat(ChatFormat.chatml);

    _llamaParent!.sendPrompt(formattedPrompt);

    await for (final token in _llamaParent!.stream) {
      // Correct way to handle stream
      final chunk = chatMLFormat.filterResponse(token);
      if (chunk != null) {
        yield chunk;
      }
    }
  }

  Future<String> getModelPath(String modelFileName) async {
    return '$modelFileName';
  }

  Future<String> _writeToFile(ByteData data, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(data.buffer.asUint8List());
    return file.path;
  }

  void dispose() {
    _llamaParent?.dispose();
  }
}

// class ChatMLFormat extends PromptFormat {
//   // ChatMLFormat class definition
//   ChatMLFormat({
//     String inputSequence = "<|im_start|>",
//     String outputSequence = "<|im_end|>",
//     String systemSequence = "<|im_start|>system\n",
//     String? stopSequence,
//   }) : super(
//           PromptFormatType.chatml,
//           inputSequence: inputSequence,
//           outputSequence: outputSequence,
//           systemSequence: systemSequence,
//           stopSequence: stopSequence,
//         );

//   @override
//   String formatPrompt(String prompt) {
//     return formatMessages([
//       {'role': 'user', 'content': prompt}
//     ]);
//   }

//   @override
//   String formatMessages(List<Map<String, dynamic>> messages) {
//     String formattedMessages = '';
//     for (var message in messages) {
//       if (message['role'] == 'user') {
//         formattedMessages += '$inputSequence${message['content']}';
//       } else if (message['role'] == 'assistant') {
//         formattedMessages += '$outputSequence${message['content']}';
//       } else if (message['role'] == 'system') {
//         formattedMessages += '$systemSequence${message['content']}';
//       }

//       if (stopSequence != null) {
//         formattedMessages += stopSequence!;
//       }
//     }
//     return formattedMessages;
//   }
// }

// class LlamaHelper {
//   LlamaParent? _llamaParent;
//   bool _modelLoaded = false;
//   final ChatMLFormat _chatMLFormat = ChatMLFormat(); // Instance of ChatMLFormat

//   Future<List<String>> loadAvailableModels() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final files = directory.listSync();

//     return files
//         .where((file) => file is File && file.path.endsWith('.gguf'))
//         .map((file) => file.path)
//         .toList();
//   }

//   Future<void> loadModel(String modelFileName) async {
//     if (_modelLoaded) return;

//     final modelPath = await getModelPath(modelFileName);
//     print('MODEL PATH GOT AS: $modelPath');

//     try {
//       final loadCommand = LlamaLoad(
//         path: modelPath,
//         modelParams: ModelParams(),
//         contextParams: ContextParams(),
//         samplingParams: SamplerParams(),
//         format: _chatMLFormat, // Use the instance of ChatMLFormat
//       );

//       _llamaParent = LlamaParent(loadCommand);
//       await _llamaParent!.init();

//       _modelLoaded = true;
//       print("LlamaHelper.loadModel: Model loaded successfully");
//     } catch (e) {
//       print("LlamaHelper.loadModel: Error loading model: $e");
//       rethrow;
//     }
//   }

//   Stream<String> generateText(String prompt) {
//     if (_llamaParent == null || !_modelLoaded) {
//       print('MODEL NOT LOADED');
//       throw Exception('Model not loaded');
//     }

//     final formattedPrompt = _chatMLFormat.formatPrompt(prompt); // Format prompt
//     _llamaParent!.sendPrompt(formattedPrompt); // Send formatted prompt
//     return _llamaParent!.stream;
//   }

//   Future<String> getModelPath(String modelFileName) async {
//     return '$modelFileName';
//   }

//   // Future<String> _writeToFile(ByteData data, String fileName) async {
//   //   final directory = await getApplicationDocumentsDirectory();
//   //   final file = File('${directory.path}/$fileName');
//   //   await file.writeAsBytes(data.buffer.asUint8List());
//   //   return file.path;
//   // }

//   void dispose() {
//     _llamaParent?.dispose();
//   }
// }
