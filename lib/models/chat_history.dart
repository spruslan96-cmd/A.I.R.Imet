enum ChatFormat {
  chatml,
  alpaca;

  String get value => name;
}

/// Represents different roles in a chat conversation
enum Role {
  unknown,
  system,
  user,
  assistant;

  String get value => switch (this) {
        Role.unknown => 'unknown',
        Role.system => 'system',
        Role.user => 'user',
        Role.assistant => 'assistant',
      };

  static Role fromString(String value) => switch (value.toLowerCase()) {
        'unknown' => Role.unknown,
        'system' => Role.system,
        'user' => Role.user,
        'assistant' => Role.assistant,
        _ => Role.unknown,
      };
}

/// Represents a single message in a chat conversation
class Message {
  final Role role;
  String content; // content is now mutable, consider if it needs to be mutable

  Message({
    required this.role,
    required this.content,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: Role.fromString(json['role'] as String),
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.value,
        'content': content,
      };

  @override
  String toString() => 'Message(role: ${role.value}, content: $content)';
}

/// Manages a collection of chat messages
class ChatHistory {
  final List<Message> messages;

  ChatHistory() : messages = [];

  /// Adds a new message to the chat history
  void addMessage({
    required Role role,
    required String content,
  }) {
    messages.add(Message(role: role, content: content));
  }

  /// Exports chat history in the specified format
  String exportFormat(ChatFormat format) {
    switch (format) {
      case ChatFormat.chatml:
        return _exportChatML();
      case ChatFormat.alpaca:
        return _exportAlpaca();
    }
  }

  String _exportChatML() {
    final buffer = StringBuffer();

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];

      if (message.role == Role.user) {
        buffer.writeln('<|im_start|>user');
        buffer.writeln(message.content);
        buffer.writeln('<|im_end|>assistant');
      } else if (message.role == Role.assistant) {
        buffer.writeln('<|im_start|>assistant');
        buffer.writeln(message.content);
        buffer.writeln('<|im_end|>');
      } else if (message.role == Role.system) {
        buffer.writeln('<|im_start|>system');
        buffer.writeln(message.content);
        buffer.writeln('<|im_end|>');
      }
    }

    return buffer.toString();
  }

  /// Exports chat history in Alpaca format
  String _exportAlpaca() {
    final buffer = StringBuffer();

    for (final message in messages) {
      switch (message.role) {
        case Role.system:
          buffer.writeln('### Instruction:');
          break; // Added break to prevent fall-through
        case Role.user:
          buffer.writeln('### Input:');
          break; // Added break to prevent fall-through
        case Role.assistant:
          buffer.writeln('### Response:');
          break; // Added break to prevent fall-through
        case Role.unknown:
          buffer.writeln('### Unknown:');
          break; // Added break to prevent fall-through
      }

      buffer.writeln();
      buffer.writeln(message.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    final chatHistory = ChatHistory();
    final messagesList = json['messages'] as List<dynamic>;

    for (final message in messagesList) {
      chatHistory.messages
          .add(Message.fromJson(message as Map<String, dynamic>));
    }

    return chatHistory;
  }

  Map<String, dynamic> toJson() => {
        'messages': messages.map((message) => message.toJson()).toList(),
      };

  void clear() => messages.clear();

  int get length => messages.length;

  @override
  String toString() => 'ChatHistory(messages: $messages)';
}
