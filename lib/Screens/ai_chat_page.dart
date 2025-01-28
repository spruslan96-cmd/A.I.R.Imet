import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ai_chat/Bloc/Chat_bloc/Bloc/chat_bloc.dart';
import 'package:local_ai_chat/Bloc/Chat_bloc/Events/chat_events.dart';
import 'package:local_ai_chat/Bloc/Chat_bloc/States/chat_states.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat with the AI')),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            List<Map<String, String>> messages = [];
            if (state is ChatMessageSent ||
                state is ChatWaitingForResponse ||
                state is ChatResponseReceived) {
              messages =
                  (state as dynamic).messages; // Safe casting for shared states
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
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
                _buildMessageInput(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = controller.text;
              if (text.isNotEmpty) {
                BlocProvider.of<ChatBloc>(context).add(SendMessageEvent(text));
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
