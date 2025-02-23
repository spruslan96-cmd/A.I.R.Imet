import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Global key
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  String? _selectedModel;
  List<String> _availableModels = [];
  final _llamaHelper = LlamaHelper();
  bool _isLoading = true;
  bool _modelLoaded = false;
  String _loadingMessage = "Loading Models...";
  StreamSubscription<String>? _generationSubscription; // Store the subscription
  final chatHistory = ChatHistory();

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    try {
      final models = await _llamaHelper.loadAvailableModels();
      setState(() {
        _availableModels = models;
        _isLoading = false;
        _loadingMessage = "";
      });
    } catch (e) {
      print("Error loading models: $e");
      setState(() {
        _isLoading = false;
        _loadingMessage = "";
      });
      _showSnackBar("Error loading models: $e"); // Show error using helper
    }
  }

  Future<void> _loadModel(String modelFileName) async {
    print("_loadModel started. Model file name: $modelFileName");

    if (mounted) {
      print("_loadModel: Widget is mounted (initial check)");
      setState(() {
        _isLoading = true;
        _modelLoaded = false;
        _loadingMessage = "Loading Model...";
        _messages.add({
          'sender': 'ai',
          'text': 'Loading model...'
        }); // Show loading message
      });
    } else {
      print("_loadModel: Widget is NOT mounted (initial check)");
    }

    try {
      await _llamaHelper.loadModel(modelFileName);
      setState(() {
        _selectedModel = modelFileName;
        _isLoading = false;
        _modelLoaded = true;
        _loadingMessage = "";
        _messages.removeLast(); // Remove the "loading model..." message
      });
    } catch (e) {
      print("_loadModel: Error: $e");
      setState(() {
        _isLoading = false;
        _loadingMessage = "";
        _messages.removeLast(); // Remove the "loading model..." message
      });

      _showSnackBar("Error loading model: $e");
    }
  }

  Future<void> _generateText() async {
    if (!_modelLoaded) {
      _showSnackBar("Model not loaded yet!");
      return;
    }

    final prompt = _controller.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': prompt});
      _controller.clear();
      _generationSubscription?.cancel();
    });
    print('User Prompt: $prompt');

    try {
      setState(() {
        _messages.add({'sender': 'ai', 'text': '...'});
      });

      String result = '';
      final generatedTextStream = _llamaHelper.generateText(prompt);

      _generationSubscription = generatedTextStream.listen((chunk) {
        print('Chunk = $chunk');
        result += chunk;
        setState(() {
          _messages.last = {'sender': 'ai', 'text': result};
        });
      }, onError: (error) {
        print("Error generating text: $error");
        _showSnackBar("Error generating text: $error");
      }, onDone: () {
        print("Generation complete");
        _generationSubscription = null;
        chatHistory.addMessage(
            role: Role.assistant, content: result); // Add to history
      });
    } catch (e) {
      print("Error generating text: $e");
      _showSnackBar("Error generating text: $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      _showOverlayMessage(message);
    }
  }

  void _showOverlayMessage(String message) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0, // Adjust position as needed
        left: 20.0,
        right: 20.0,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.red,
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _llamaHelper.dispose();
    _generationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Hamburger(),
      appBar: AppBar(
        title: const Text('Chat with the AI'),
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
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingMessage),
                ],
              )
            : _modelLoaded
                ? Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isUser = message['sender'] == 'user';
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.blueAccent
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  message['text']!,
                                  style: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                enabled: !_isLoading,
                                decoration: const InputDecoration(
                                  hintText: 'Type your message...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _generateText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text("Select a model")),
      ),
    );
  }
}
