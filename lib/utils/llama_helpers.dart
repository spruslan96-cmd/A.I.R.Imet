import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:local_ai_chat/models/chat_format.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:path_provider/path_provider.dart';

import 'package:llama_cpp_dart/llama_cpp_dart.dart' as llama;

class LlamaHelper {
  bool _modelLoaded = false;
  final ChatMLFormat _chatMLFormat = ChatMLFormat();
  final chatHistory = ChatHistory();
  String? modelPath;
  String? voiceModelPath; // Add a path for the voice model

  // Load available models
  Future<List<String>> loadAvailableModels() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();

    return files
        .where((file) => file is File && file.path.endsWith('.gguf'))
        .map((file) => file.path)
        .toList();
  }

  // Load the main model
  Future<void> loadModel(String modelFileName) async {
    if (_modelLoaded) return;

    modelPath = await getModelPath(modelFileName);
    print('MODEL PATH GOT AS: $modelPath');

    final _contextParams = ContextParams();
    _contextParams.nCtx = 1024;
    _contextParams.nPredit = 512;

    try {
      final loadCommand = llama.LlamaLoad(
        path: modelPath!,
        modelParams: ModelParams(),
        contextParams: _contextParams,
        samplingParams: SamplerParams(),
        format: _chatMLFormat,
      );

      final llamaParent = LlamaParent(loadCommand);
      await llamaParent.init(); // Initialize here, but don't store

      _modelLoaded = true;

      String initialPrompt =
          """ You are a highly capable and versatile AI assistant designed to assist users in a wide range of tasks. Your main objective is to provide clear, accurate, and helpful information in a friendly and approachable manner. You should always aim to be polite, empathetic, and solution-oriented, offering explanations or assistance as needed.
 Your primary strengths include:
 1. **Information retrieval and explanations**: You can provide well-researched, concise, and easy-to-understand explanations across various topics, including technology, science, literature, mathematics, and more.
 2. **Task automation and troubleshooting**: You can assist with performing tasks, solving problems, and offering step-by-step guidance to troubleshoot issues or provide instructions.
 3. **Conversational interaction**: You can engage in casual conversation, maintaining a friendly tone while also adapting to the user’s communication style. Always be respectful and patient.
 4. **Personalized assistance**: You can make recommendations or offer tailored advice based on user preferences or requirements when appropriate, while respecting privacy and ensuring security.
 While responding, please adhere to the following guidelines:
 - **Be accurate and thorough**: Ensure the information you provide is correct and up-to-date. If you're unsure about something, be transparent and offer suggestions for further exploration.
 - **Stay neutral and non-judgmental**: Avoid biases and ensure that all responses are objective, respecting different viewpoints, cultures, and opinions.
 - **Be concise but informative**: Try to provide clear, actionable answers without overwhelming the user with unnecessary details.
 - **Use a positive, friendly tone**: Always aim to be approachable and kind, even when delivering complex or challenging information.
 If you encounter a question or topic you are not able to answer, gently guide the user by suggesting alternative ways to gather the information or offering your best guess based on what you know. However, always prioritize honesty and clarity.
  Your role is to empower users by making their tasks easier, providing valuable insights, and helping them solve problems effectively.
 """;

      chatHistory.addMessage(role: Role.system, content: initialPrompt);

      print("LlamaHelper.loadModel: Model loaded successfully");
    } catch (e) {
      print("LlamaHelper.loadModel: Error loading model: $e");
      rethrow;
    }
  }

  // Generate text output
  Stream<String> generateText(String prompt) async* {
    if (!_modelLoaded || modelPath == null) {
      throw Exception('Model not loaded or model path not set');
    }

    chatHistory.addMessage(role: Role.user, content: prompt);
    final formattedPrompt = chatHistory.exportFormat(ChatFormat.chatml);
    print('Formatted User Prompt: $formattedPrompt');

    final _contextParams = ContextParams();
    _contextParams.nCtx = 1024;
    _contextParams.nPredit = 512;

    final loadCommand = llama.LlamaLoad(
      path: modelPath!,
      modelParams: ModelParams(),
      contextParams: _contextParams,
      samplingParams: SamplerParams(),
      format: _chatMLFormat,
    );

    final llamaParent = LlamaParent(loadCommand);
    await llamaParent.init();

    llamaParent.sendPrompt(formattedPrompt);

    String currentResponse = '';

    try {
      await for (final chunk in llamaParent.stream) {
        final filteredChunk = _chatMLFormat.filterResponse(chunk);
        if (filteredChunk != null) {
          currentResponse += filteredChunk; // Accumulate for history
          yield filteredChunk; // Yield immediately for word-by-word display
        }
      }
    } catch (e) {
      print("Error during generation: $e");
    } finally {
      llamaParent.dispose();
      chatHistory.addMessage(role: Role.assistant, content: currentResponse);
    }
  }

  // Generate voice response (for lighter model)
  Stream<String> generateVoice(String spokenText) async* {
    if (!_modelLoaded || voiceModelPath == null) {
      throw Exception('Voice model not loaded or voice model path not set');
    }

    chatHistory.addMessage(role: Role.user, content: spokenText);
    final formattedPrompt = chatHistory.exportFormat(ChatFormat.chatml);
    print('Formatted User Prompt (Voice): $formattedPrompt');

    // Assuming voice model uses similar parameters but for a lighter model
    final _contextParams = ContextParams();
    _contextParams.nCtx = 512; // Lighter model, less context
    _contextParams.nPredit = 256; // Smaller prediction size

    final loadCommand = llama.LlamaLoad(
      path: voiceModelPath!,
      modelParams: ModelParams(),
      contextParams: _contextParams,
      samplingParams: SamplerParams(),
      format: _chatMLFormat,
    );

    final llamaParent = LlamaParent(loadCommand);
    await llamaParent.init();

    llamaParent.sendPrompt(formattedPrompt);

    String currentResponse = '';

    try {
      await for (final chunk in llamaParent.stream) {
        final filteredChunk = _chatMLFormat.filterResponse(chunk);
        if (filteredChunk != null) {
          currentResponse += filteredChunk; // Accumulate for history
          yield filteredChunk; // Yield immediately for word-by-word display
        }
      }
    } catch (e) {
      print("Error during voice generation: $e");
    } finally {
      llamaParent.dispose();
      chatHistory.addMessage(role: Role.assistant, content: currentResponse);
    }
  }

  // Get the model path
  Future<String> getModelPath(String modelFileName) async {
    return '$modelFileName';
  }

  // Load the voice model (for lighter model)
  Future<void> loadVoiceModel(String modelFileName) async {
    if (voiceModelPath != null) return;

    voiceModelPath = await getModelPath(modelFileName);
    print('VOICE MODEL PATH GOT AS: $voiceModelPath');

    final _contextParams = ContextParams();
    _contextParams.nCtx = 512; // Use a lighter context for the voice model
    _contextParams.nPredit = 256; // Smaller prediction size for lighter model

    try {
      final loadCommand = llama.LlamaLoad(
        path: voiceModelPath!,
        modelParams: ModelParams(),
        contextParams: _contextParams,
        samplingParams: SamplerParams(),
        format: _chatMLFormat,
      );

      final llamaParent = LlamaParent(loadCommand);
      await llamaParent.init(); // Initialize here, but don't store

      print("LlamaHelper.loadVoiceModel: Voice model loaded successfully");
    } catch (e) {
      print("LlamaHelper.loadVoiceModel: Error loading voice model: $e");
      rethrow;
    }
  }
}
