// ai_helpers.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';
import 'package:local_ai_chat/models/chat_history.dart';

class AiHelpers {
  static Future<void> loadAvailableModels(LlamaHelper llamaHelper,
      Function(List<String>) onModelsLoaded, Function(String) onError) async {
    try {
      final models = await llamaHelper.loadAvailableModels();
      onModelsLoaded(models);
    } catch (e) {
      print("Error loading models: $e");
      onError("Error loading models: $e");
    }
  }

  static Future<void> loadModel(
    String modelFileName,
    LlamaHelper llamaHelper,
    bool modelLoaded,
    Function(bool, String) onModelLoading,
    Function(String) onError, {
    required int nCtx,
    required int nBatch,
    required int nPredict,
  }) async {
    if (modelLoaded) return;

    onModelLoading(true, "Loading Model...");
    try {
      await llamaHelper.loadModel(modelFileName);
      onModelLoading(false, "");
    } catch (e) {
      print("Error loading model: $e");
      onModelLoading(false, "");
      onError("Error loading model: $e");
    }
  }

  static Future<void> loadVoiceModel(
      String modelFileName,
      LlamaHelper llamaHelper,
      bool modelLoaded,
      Function(bool, String) onModelLoading,
      Function(String) onError) async {
    if (modelLoaded) return;

    onModelLoading(true, "Loading Model...");
    try {
      await llamaHelper.loadModel(modelFileName);
      onModelLoading(false, "");
    } catch (e) {
      print("Error loading model: $e");
      onModelLoading(false, "");
      onError("Error loading model: $e");
    }
  }

  static Future<void> generateText(
      String prompt,
      LlamaHelper llamaHelper,
      ChatHistory chatHistory,
      Function(String) onResponseGenerated,
      Function(String) onError) async {
    String result = '';
    try {
      final generatedTextStream = await llamaHelper.generateText(prompt);
      generatedTextStream.listen(
        (chunk) {
          result += chunk;
          onResponseGenerated(result);
        },
        onError: (error) {
          print("Error generating text: $error");
          onError("Error generating text: $error");
        },
        onDone: () {
          chatHistory.addMessage(role: Role.assistant, content: result);
        },
      );
    } catch (e) {
      print("Error generating text: $e");
      onError("Error generating text: $e");
    }
  }

  // New method for generating voice
  static Future<void> generateVoice(
    String prompt,
    LlamaHelper llamaHelper,
    ChatHistory chatHistory,
    Function(String) onResponseGenerated,
    Function(String) onError, {
    Function()? onComplete,
  }) async {
    try {
      final generatedTextStream = await llamaHelper.generateText(prompt);
      String fullResponse = '';

      generatedTextStream.listen(
        (chunk) {
          fullResponse += chunk;
          onResponseGenerated(chunk); // ✅ Send only the chunk
        },
        onError: (error) {
          print("Error generating text: $error");
          onError("Error generating text: $error");
        },
        onDone: () {
          print('Triggering onDone');
          chatHistory.addMessage(role: Role.assistant, content: fullResponse);
          if (onComplete != null) onComplete(); // ✅ Trigger complete callback
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Error generating text: $e");
      onError("Error generating text: $e");
    }
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
