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
  late ThemeData theme;

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
    AiHelpers.loadVoiceModel(
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
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: theme.colorScheme.onPrimary,
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
          color: theme.colorScheme.primary
              .withOpacity(0.2), // Lighter shade for pulsation
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
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.onPrimary,
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
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedScale(
          scale: 1.1,
          duration: const Duration(milliseconds: 500),
          child: Icon(
            Icons.volume_up,
            color: theme.colorScheme.onPrimary,
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
    theme = Theme.of(context);
    String displayResponse = _responseText.length >= 150
        ? '${_responseText.substring(0, 150)}...'
        : _responseText;

    return Scaffold(
      drawer: const Hamburger(),
      appBar: AppBar(
        title: const Text("Talk"),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedModel,
              hint: const Text("Select Model"),
              items: _availableModels.map((modelPath) {
                return DropdownMenuItem<String>(
                  value: modelPath,
                  child: Text(
                    modelPath.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _loadModel(value);
                }
              },
              style: TextStyle(color: theme.colorScheme.onBackground),
              underline: Container(
                height: 1,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _buildCircleAnimation(),
            ), // Add the animation circle here
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    if (_spokenText.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _spokenText,
                            style:
                                TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (displayResponse.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            displayResponse,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Text(
            //   _responseText,
            //   style: const TextStyle(fontSize: 16),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _llamaHelper.dispose();
    _animationTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop(); // Stop any ongoing speech
    _speechTimeout?.cancel();
    super.dispose();
  }
}
