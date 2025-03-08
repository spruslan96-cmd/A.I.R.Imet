// import 'dart:async';
// import 'dart:io';
// import 'dart:isolate';
// import 'package:llama_cpp_dart/llama_cpp_dart.dart';
// import 'package:local_ai_chat/models/chat_format.dart';
// import 'package:local_ai_chat/models/chat_history.dart';
// import 'package:path_provider/path_provider.dart';

// import 'package:llama_cpp_dart/llama_cpp_dart.dart' as llama;

// class LlamaHelper {
//   bool _modelLoaded = false;
//   final ChatMLFormat _chatMLFormat = ChatMLFormat();
//   final chatHistory = ChatHistory();
//   String? modelPath;
//   String? voiceModelPath; // Add a path for the voice model

//   late Isolate _modelIsolate;
//   late SendPort _sendPort;

//   // Load available models
//   Future<List<String>> loadAvailableModels() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final files = directory.listSync();

//     return files
//         .where((file) => file is File && file.path.endsWith('.gguf'))
//         .map((file) => file.path)
//         .toList();
//   }

//   // Load the model in the background isolate (not in the main isolate)
//   Future<void> loadModel(String modelFileName) async {
//     if (_modelLoaded) return;

//     modelPath = await getModelPath(modelFileName);
//     print('MODEL PATH GOT AS: $modelPath');

//     try {
//       final receivePort = ReceivePort();
//       // Spawn a separate isolate to load and initialize the model
//       _modelIsolate = await Isolate.spawn(
//         _modelIsolateEntry,
//         {'sendPort': receivePort.sendPort, 'modelPath': modelPath},
//         onExit: receivePort.sendPort,
//       );

//       // Wait for the model to be loaded and initialize it
//       final sendPort = await receivePort.first;

//       _sendPort = sendPort;
//       _modelLoaded = true;

//       String initialPrompt = """
//       You are an AI assistant designed to help users in a friendly, supportive, and conversational manner. Your role is to provide clear, informative, and empathetic responses, treating the user like a close friend.
//       """;

//       chatHistory.addMessage(role: Role.system, content: initialPrompt);

//       print("LlamaHelper.loadModel: Model loaded successfully");
//     } catch (e) {
//       print("LlamaHelper.loadModel: Error loading model: $e");
//       rethrow;
//     }
//   }

//   static void _modelIsolateEntry(Map<String, dynamic> args) async {
//     final sendPort = args['sendPort'] as SendPort;
//     final modelPath = args['modelPath'] as String;

//     final receivePort = ReceivePort();
//     sendPort.send(receivePort
//         .sendPort); // Send the sendPort back to the main isolate for communication

//     try {
//       // Load the model in the background isolate
//       final _contextParams = ContextParams();
//       _contextParams.nCtx = 1024;
//       _contextParams.nPredit = 512;

//       final loadCommand = llama.LlamaLoad(
//         path: modelPath,
//         modelParams: ModelParams(),
//         contextParams: _contextParams,
//         samplingParams: SamplerParams(),
//         format: ChatMLFormat(),
//       );

//       final llamaParent = LlamaParent(loadCommand);
//       await llamaParent.init(); // Initialize the model

//       print("Model loaded in isolate");

//       // Listen for incoming messages (prompt and sendPort)
//       receivePort.listen((message) async {
//         // Process the incoming prompt and send back the result
//         print("Received prompt in isolate: $message");
//         final stringMessage = message.toString();
//         try {
//           llamaParent.sendPrompt(stringMessage);

//           // Listen for generated chunks
//           String response = '';
//           await for (final chunk in llamaParent.stream) {
//             response += chunk;
//             print("Generated chunk: $chunk"); // Print the generated chunk
//             sendPort.send(chunk); // Send the chunk back to the main isolate
//           }

//           // Print the full response after all chunks are collected
//           print("Full response generated: $response");
//           sendPort.send(response); // Send the complete response
//         } catch (e) {
//           print("Error while sending prompt or processing response: $e");
//           sendPort.send(
//               "Error generating response: $e"); // Send error message back to UI
//         }
//       });
//     } catch (e) {
//       print("Error in model isolate: $e");
//       sendPort.send("Error loading model: $e");
//     }
//   }

//   Stream<String> generateText(String prompt) async* {
//     if (!_modelLoaded || modelPath == null) {
//       throw Exception('Model not loaded or model path not set');
//     }

//     chatHistory.addMessage(role: Role.user, content: prompt);
//     final formattedPrompt = chatHistory.exportFormat(ChatFormat.chatml);
//     print('Formatted User Prompt: $formattedPrompt');

//     try {
//       // Send only the prompt and the SendPort separately (not as a List)
//       final receivePort = ReceivePort();
//       _sendPort.send(formattedPrompt); // Send only the formatted prompt
//       _sendPort.send(receivePort.sendPort); // Send the SendPort separately

//       // Yield the chunks as they come in from the isolate
//       await for (final chunk in receivePort) {
//         print("Received chunk from isolate: $chunk"); // Print received chunk
//         yield chunk;
//       }
//     } catch (e) {
//       print("Error during generation: $e");
//     }
//   }

//   // Get the model path
//   Future<String> getModelPath(String modelFileName) async {
//     return '$modelFileName';
//   }

//   // Dispose of the model isolate (cleanup)
//   Future<void> disposeModelIsolate() async {
//     _modelIsolate.kill(priority: Isolate.immediate);
//     print("Model isolate disposed");
//   }
// }
