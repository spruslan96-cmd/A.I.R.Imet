// Bloc Events
abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String message;
  SendMessageEvent(this.message);
}

class ReceiveMessageEvent extends ChatEvent {
  final String response;
  ReceiveMessageEvent(this.response);
}
