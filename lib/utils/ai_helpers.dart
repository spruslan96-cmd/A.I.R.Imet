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
      final generatedTextStream = llamaHelper.generateText(prompt);
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
      Function(String) onError) async {
    String result = '';
    try {
      final generatedVoiceStream = llamaHelper.generateVoice(prompt);
      generatedVoiceStream.listen(
        (chunk) {
          result += chunk;
          onResponseGenerated(result);
        },
        onError: (error) {
          print("Error generating voice: $error");
          onError("Error generating voice: $error");
        },
        onDone: () {
          chatHistory.addMessage(role: Role.assistant, content: result);
        },
      );
    } catch (e) {
      print("Error generating voice: $e");
      onError("Error generating voice: $e");
    }
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
