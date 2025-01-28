import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ai_chat/Bloc/Model_bloc/Bloc/model_bloc.dart';
import 'package:local_ai_chat/Bloc/Model_bloc/Events/model_events.dart';
import 'package:local_ai_chat/Screens/model_check_page.dart';

void main() {
  runApp(const ChatAIApp());
}

class ChatAIApp extends StatelessWidget {
  const ChatAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat with the AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BlocProvider(
        create: (context) => ModelBloc()..add(CheckModelEvent()),
        child: const ModelCheckPage(),
      ),
    );
  }
}
