import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';
import 'package:local_ai_chat/utils/ai_helpers.dart'; // Import the helper
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts

class TalkPage extends StatefulWidget {
  const TalkPage({super.key});

  @override
  State<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends State<TalkPage> {
  final _llamaHelper = LlamaHelper();
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts; // Create an instance of FlutterTts
  bool _modelLoaded = false;
  String _spokenText = '';
  String _responseText = '';
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  Timer? _animationTimer;
  double _circleRadius = 150.0;
  Timer? _speechTimeout; // Add a timer

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts(); // Initialize FlutterTts

    AiHelpers.loadAvailableModels(
      _llamaHelper,
      (models) {
        setState(() {
          _availableModels = models;
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
      },
    );
  }

  Future<void> _loadModel(String modelFileName) async {
    AiHelpers.loadModel(
      modelFileName,
      _llamaHelper,
      _modelLoaded,
      (isLoading, message) {
        setState(() {
          _responseText = message;
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
      },
    );
    setState(() {
      _modelLoaded = true;
      _selectedModel = modelFileName;
    });
  }

  Future<void> _generateText(String spokenText) async {
    setState(() {
      _isLoading = true; // Show loading animation
    });

    AiHelpers.generateText(
      spokenText,
      _llamaHelper,
      ChatHistory(),
      (response) {
        setState(() {
          _responseText = response;
          _isLoading = false; // Hide loading animation
          _isSpeaking = true; // Start speaking animation
        });

        _speakResponse(response); // Speak the response
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
      },
    );
  }

  // Speak the response text
  Future<void> _speakResponse(String text) async {
    await _flutterTts.setLanguage("en-US"); // Set language to English
    await _flutterTts.setSpeechRate(0.5); // Set a slower speech rate
    await _flutterTts.speak(text); // Speak the response
  }

  // Build the animation circle based on state
  Widget _buildCircleAnimation() {
    if (_isListening) {
      return _buildListeningAnimation();
    } else if (_isLoading) {
      return _buildLoadingAnimation();
    } else if (_isSpeaking) {
      return _buildSpeakingAnimation();
    } else {
      return _buildIdleCircle();
    }
  }

  // Idle Circle with microphone icon
  Widget _buildIdleCircle() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        height: 150,
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  // Listening animation (4 dots)
  Widget _buildListeningAnimation() {
    void updateAnimation() {
      if (mounted) {
        setState(() {
          _circleRadius = 150.0 +
              (sin(DateTime.now().millisecondsSinceEpoch / 100.0) *
                  5.0); // Pulsating circle
        });
      }
    }

    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      updateAnimation();
    });

    return GestureDetector(
      onTap: () {
        if (_animationTimer != null && _animationTimer!.isActive) {
          _animationTimer!.cancel();
        }
        _stopListening();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _circleRadius,
        height: _circleRadius,
        decoration: BoxDecoration(
          color:
              Colors.blueAccent.withOpacity(0.2), // Lighter shade for pulsation
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Loading animation (spinner)
  Widget _buildLoadingAnimation() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  // Speaking animation (vibration effect)
  Widget _buildSpeakingAnimation() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: AnimatedScale(
          scale: 1.1,
          duration: Duration(milliseconds: 500),
          child: Icon(
            Icons.volume_up,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  // Start listening
  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _spokenText = '';
    });

    bool available = await _speechToText.initialize();
    if (available) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
          _resetSpeechTimeout(); // Reset the timer on speech
        },
        onSoundLevelChange: (level) {
          _resetSpeechTimeout(); // Reset the timer on sound
        },
      );
      _resetSpeechTimeout(); // Start the timer initially
    } else {
      AiHelpers.showSnackBar(context, "Speech recognition is not available.");
      setState(() {
        _isListening = false;
      });
    }
  }

  void _resetSpeechTimeout() {
    if (_speechTimeout != null && _speechTimeout!.isActive) {
      _speechTimeout!.cancel();
    }
    _speechTimeout = Timer(const Duration(seconds: 3), () {
      if (_isListening) {
        _stopListening();
      }
    });
  }

  // Stop listening and generate model response
  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
    });
    await _speechToText.stop();
    if (_spokenText.trim().isNotEmpty) {
      _generateText(_spokenText);
    } else {
      AiHelpers.showSnackBar(context, "No speech detected.");
    }
    if (_speechTimeout != null && _speechTimeout!.isActive) {
      _speechTimeout!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Hamburger(),
      appBar: AppBar(
        title: const Text("Talk to AI"),
        actions: [
          DropdownButton<String>(
            value: _selectedModel,
            hint: const Text("Select Model"),
            items: _availableModels
                .map((modelPath) => DropdownMenuItem<String>(
                    value: modelPath, child: Text(modelPath.split('/').last)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _loadModel(value);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleAnimation(), // Add the animation circle here
            const SizedBox(height: 20),
            Text(
              _spokenText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _responseText,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop(); // Stop any ongoing speech
    _speechTimeout?.cancel();
    super.dispose();
  }
}
