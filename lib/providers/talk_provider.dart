// talk_provider.dart
import 'package:flutter/material.dart';

class TalkProvider extends ChangeNotifier {
  String _spokenText = '';
  String _responseText = '';
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;

  String get spokenText => _spokenText;
  String get responseText => _responseText;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isLoading => _isLoading;

  void setSpokenText(String text) {
    _spokenText = text;
    notifyListeners();
  }

  void setResponseText(String text) {
    _responseText = text;
    notifyListeners();
  }

  void setIsListening(bool value) {
    _isListening = value;
    notifyListeners();
  }

  void setIsSpeaking(bool value) {
    _isSpeaking = value;
    notifyListeners();
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
