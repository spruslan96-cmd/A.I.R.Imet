import 'package:flutter/material.dart';
import 'package:local_ai_chat/Screens/chat_page.dart';

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

// // main.dart
// import 'package:flutter/material.dart';
// import 'package:local_ai_chat/Screens/chat_page.dart';
// import 'package:provider/provider.dart';
// import 'package:local_ai_chat/providers/chat_provider.dart';
// import 'package:local_ai_chat/providers/talk_provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => ChatProvider()),
//         ChangeNotifierProvider(create: (context) => TalkProvider()),
//       ],
//       child: const ChatAIApp(),
//     ),
//   );
// }

// class ChatAIApp extends StatelessWidget {
//   const ChatAIApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Chat with the AI',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const ChatPage(),
//     );
//   }
// }
