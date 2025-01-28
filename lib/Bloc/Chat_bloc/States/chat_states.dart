// Bloc States
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatMessageSent extends ChatState {
  final List<Map<String, String>> messages;
  ChatMessageSent(this.messages);
}

class ChatWaitingForResponse extends ChatState {
  final List<Map<String, String>> messages;
  ChatWaitingForResponse(this.messages);
}

class ChatResponseReceived extends ChatState {
  final List<Map<String, String>> messages;
  ChatResponseReceived(this.messages);
}
