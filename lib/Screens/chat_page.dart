// chat_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/Widgets/prompt_text_field.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:local_ai_chat/utils/ai_helpers.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart'; // Import the helper

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  String? _selectedModel;
  List<String> _availableModels = [];
  final _llamaHelper = LlamaHelper();
  bool _isLoading = true;
  bool _modelLoaded = false;
  String _loadingMessage = "Loading Models...";

  @override
  void initState() {
    super.initState();
    AiHelpers.loadAvailableModels(
      _llamaHelper,
      (models) {
        setState(() {
          _availableModels = models;
          _isLoading = false;
          _loadingMessage = "";
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
        setState(() {
          _isLoading = false;
          _loadingMessage = "";
        });
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
          _isLoading = isLoading;
          _loadingMessage = message;
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
      },
    );
  }

  Future<void> _generateText() async {
    if (!_modelLoaded) {
      AiHelpers.showSnackBar(context, "Model not loaded yet!");
      return;
    }

    final prompt = _controller.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': prompt});
      _controller.clear();
    });

    AiHelpers.generateText(
      prompt,
      _llamaHelper,
      ChatHistory(),
      (response) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': response});
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Hamburger(),
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
            : Column(
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
                              color:
                                  isUser ? Colors.blueAccent : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message['text']!,
                              style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black),
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
                          child: PromptTextField(
                            controller: _controller,
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
              ),
      ),
    );
  }
}
