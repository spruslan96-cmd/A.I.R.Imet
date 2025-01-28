// Model Check Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ai_chat/Bloc/Model_bloc/Bloc/model_bloc.dart';
import 'package:local_ai_chat/Bloc/Model_bloc/Events/model_events.dart';
import 'package:local_ai_chat/Bloc/Model_bloc/States/model_states.dart';
import 'package:local_ai_chat/Screens/ai_chat_page.dart';

class ModelCheckPage extends StatelessWidget {
  const ModelCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocConsumer<ModelBloc, ModelState>(
          listener: (context, state) {
            if (state is ModelDownloaded) {
              BlocProvider.of<ModelBloc>(context).add(CheckModelEvent());
            } else if (state is ModelError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          builder: (context, state) {
            if (state is ModelChecking || state is ModelDownloading) {
              return const CircularProgressIndicator();
            } else if (state is ModelExists) {
              return ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                ),
                child: const Text('Start Chat'),
              );
            } else if (state is ModelNotExists) {
              return ElevatedButton(
                onPressed: () => _showModelDownloadDialog(context),
                child: const Text('Download a Model'),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  void _showModelDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Model'),
        content: const Text('Choose which Llama model to download:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              BlocProvider.of<ModelBloc>(context).add(DownloadModelEvent('1B'));
            },
            child: const Text('1B Model'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              BlocProvider.of<ModelBloc>(context).add(DownloadModelEvent('3B'));
            },
            child: const Text('3B Model'),
          ),
        ],
      ),
    );
  }
}
