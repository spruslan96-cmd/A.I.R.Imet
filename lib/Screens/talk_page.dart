import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';
import 'package:local_ai_chat/models/chat_history.dart';

class TalkPage extends StatefulWidget {
  const TalkPage({super.key});

  @override
  State<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends State<TalkPage> {
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  final _llamaHelper = LlamaHelper();
  final chatHistory = ChatHistory();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  bool _modelLoaded = false;
  String _spokenText = '';
  String _responseText = '';
  String? _selectedModel;
  List<String> _availableModels = [];
  StreamSubscription<String>? _generationSubscription;
  Timer? _animationTimer;
  double _circleRadius = 150.0;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _loadAvailableModels();
    _initializeSpeechRecognition();
  }

  // Initialize speech recognition
  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speechToText.initialize();
    if (!available) {
      print("Speech recognition is not available");
    }
  }

  // Load available models
  Future<void> _loadAvailableModels() async {
    try {
      final models = await _llamaHelper.loadAvailableModels();
      setState(() {
        _availableModels = models;
      });
    } catch (e) {
      print("Error loading models: $e");
      _showSnackBar("Error loading models: $e");
    }
  }

  // Load the selected model
  Future<void> _loadModel(String modelFileName) async {
    if (_modelLoaded) return;

    setState(() {
      _isLoading = true;
      _modelLoaded = false;
      _responseText = "Loading model...";
    });

    try {
      await _llamaHelper.loadModel(modelFileName);
      setState(() {
        _selectedModel = modelFileName;
        _modelLoaded = true;
        _isLoading = false;
        _responseText = "";
      });
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _isLoading = false;
        _responseText = "Error loading model.";
      });
      _showSnackBar("Error loading model: $e");
    }
  }

  // Request microphone permission and then start listening
  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _isListening = true;
        _spokenText = '';
      });

      Timer? _speechTimeout; // Timer to stop listening if no speech is detected

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
          if (_speechTimeout != null && _speechTimeout!.isActive) {
            _speechTimeout!.cancel(); // Reset timeout if speech is detected
          }
          _speechTimeout = Timer(const Duration(seconds: 3), () {
            if (_isListening) {
              _stopListening(); // Stop listening if no speech after 3 seconds
            }
          });
        },
        onSoundLevelChange: (level) {
          if (_speechTimeout != null && _speechTimeout!.isActive) {
            _speechTimeout!.cancel(); // Reset timer if sound detected
          }
          _speechTimeout = Timer(const Duration(seconds: 3), () {
            if (_isListening) {
              _stopListening(); // Stop listening if no sound after 3 seconds
            }
          });
        },
      );
    } else {
      _showSnackBar("Microphone permission is required to start listening.");
    }
  }

  // Stop listening and generate model response
  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
    });
    await _speechToText.stop();

    if (_spokenText.trim().isNotEmpty && _modelLoaded) {
      // Check if text was detected
      _generateText(_spokenText);
    } else if (_spokenText.trim().isEmpty) {
      _showSnackBar(
          "No speech detected."); // Notify user if no speech was detected
    } else if (!_modelLoaded) {
      _showSnackBar("Model not loaded.");
    }
  }

  // Generate text using the model
  Future<void> _generateText(String spokenText) async {
    setState(() {
      _isLoading = true;
      _responseText = "Generating response...";
    });

    try {
      String result = '';
      final generatedTextStream = _llamaHelper.generateText(spokenText);

      _generationSubscription = generatedTextStream.listen(
        (chunk) {
          result += chunk;
          setState(() {
            _responseText = result;
          });
        },
        onError: (error) {
          print("Error generating text: $error");
          _showSnackBar("Error generating text: $error");
        },
        onDone: () async {
          print("Generation complete");
          chatHistory.addMessage(role: Role.assistant, content: result);
          await _speakResponse(result);
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print("Error generating text: $e");
      _showSnackBar("Error generating text: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Speak the generated response
  Future<void> _speakResponse(String response) async {
    setState(() {
      _isSpeaking = true;
    });
    await _flutterTts.speak(response);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Show a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  void dispose() {
    _generationSubscription?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCircleAnimation(),
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
}
