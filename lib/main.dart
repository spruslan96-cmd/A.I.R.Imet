import 'package:flutter/material.dart';
import 'package:local_ai_chat/Screens/ai_chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ChatAIApp()); // Run the app
}

class ChatAIApp extends StatelessWidget {
  const ChatAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat with the AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatPage(), // Go to your ChatPage (UI)
    );
  }
}
