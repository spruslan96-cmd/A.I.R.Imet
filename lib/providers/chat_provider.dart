// chat_provider.dart
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, String>> _messages = [];
  List<Map<String, String>> get messages => _messages;

  void addMessage(Map<String, String> message) {
    _messages.add(message);
    notifyListeners();
  }

  void updateLastMessage(String updatedText) {
    if (_messages.isNotEmpty) {
      _messages.last['text'] = updatedText;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
