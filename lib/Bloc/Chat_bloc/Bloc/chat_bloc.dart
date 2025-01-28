import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_ai_chat/Bloc/Chat_bloc/Events/chat_events.dart';
import 'package:local_ai_chat/Bloc/Chat_bloc/States/chat_states.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final List<Map<String, String>> _messages = [];

  ChatBloc() : super(ChatInitial());

  Stream<ChatState> mapEventToState(ChatEvent event) async* {
    if (event is SendMessageEvent) {
      _messages.add({'sender': 'user', 'text': event.message});
      yield ChatMessageSent(List.from(_messages));

      yield ChatWaitingForResponse(List.from(_messages));
      await Future.delayed(Duration(seconds: 1)); // Simulate response delay

      final aiResponse = 'AI Response to "${event.message}"';
      _messages.add({'sender': 'ai', 'text': aiResponse});
      yield ChatResponseReceived(List.from(_messages));
    }
  }
}
