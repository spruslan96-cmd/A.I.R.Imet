// import 'package:flutter/material.dart';
// import 'package:local_ai_chat/Screens/chat_page.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   runApp(const ChatAIApp()); // Run the app
// }

// class ChatAIApp extends StatelessWidget {
//   const ChatAIApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Chat with the AI',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const ChatPage(), // Go to your ChatPage (UI)
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:local_ai_chat/Screens/chat_page.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AI Chat',
            theme: themeProvider.themeData,
            home: const ChatPage(),
          );
        },
      ),
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
