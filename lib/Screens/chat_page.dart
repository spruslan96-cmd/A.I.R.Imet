// chat_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/Widgets/prompt_text_field.dart';
import 'package:local_ai_chat/models/chat_history.dart';
import 'package:local_ai_chat/utils/ai_helpers.dart';
import 'package:local_ai_chat/utils/llama_helpers.dart';

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
  bool _isGenerating = false;
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

  @override
  void dispose() {
    print('chat page disposed');
    _llamaHelper.dispose();
    super.dispose();
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
    setState(() {
      _modelLoaded = true;
      _selectedModel = modelFileName;
    });
  }

  Future<void> _generateText() async {
    if (!_modelLoaded || _isGenerating) return;

    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true; // Set loading state to true
      _messages.add({'sender': 'user', 'text': prompt});
      _messages.add({'sender': 'ai', 'text': '...'});
      _controller.clear();
    });
    // print('_isGenerating = $_isGenerating');

    String aiResponse = '';

    await AiHelpers.generateText(
      prompt,
      _llamaHelper,
      ChatHistory(),
      (response) {
        setState(() {
          aiResponse = response;
          _messages.last['text'] = aiResponse;
        });
      },
      (error) {
        AiHelpers.showSnackBar(context, error);
      },
    ).whenComplete(() {
      setState(() {
        _isGenerating = false; // Reset loading state to false
      });
    });
    // print('_isGenerating = $_isGenerating');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Hamburger(),
      appBar: AppBar(
        title: const Text('Chat'),
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
                    child: _messages.isEmpty && !_modelLoaded
                        ? const Center(
                            child: Text(
                              'No model is loaded, please select a model',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
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
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    message['text']!,
                                    style: TextStyle(
                                      color: isUser
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
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
                        _isGenerating
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.send),
                                onPressed: _modelLoaded ? _generateText : null,
                                color: _modelLoaded
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
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
