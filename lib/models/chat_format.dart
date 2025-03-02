import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class ChatMLFormat extends PromptFormat {
  ChatMLFormat({
    String inputSequence = "<|im_start|>user",
    String outputSequence = "<|im_end|>assistant",
    String systemSequence = "<|im_start|>system",
    String stopSequence = '<|im_end|>',
  }) : super(
          PromptFormatType.chatml,
          inputSequence: inputSequence,
          outputSequence: outputSequence,
          systemSequence: systemSequence,
          stopSequence: stopSequence,
        );

  @override
  String formatMessages(List<Map<String, dynamic>> messages) {
    String formattedMessages = '';
    for (var message in messages) {
      if (message['role'] == 'user') {
        formattedMessages +=
            '$inputSequence${message['content']}\n$outputSequence'; // Added newline and outputSequence
      } else if (message['role'] == 'assistant') {
        formattedMessages += '$outputSequence${message['content']}';
      } else if (message['role'] == 'system') {
        formattedMessages += '$systemSequence${message['content']}';
      }

      if (stopSequence != null) {
        formattedMessages += stopSequence!;
      }
    }
    return formattedMessages;
  }

  @override
  String formatPrompt(String prompt) {
    return formatMessages([
      {'role': 'user', 'content': prompt}
    ]);
  }

  @override
  String? filterResponse(String response) {
    if (response == null) return null; // Handle null input

    String filteredResponse = response;

    // 1. Remove Control Characters (Keep Newlines):
    filteredResponse =
        filteredResponse.replaceAll(RegExp(r'[^\x20-\x7F\n]'), '');

    // 2. Remove Specific Tokens (Customize this):
    filteredResponse = filteredResponse.replaceAll("<|file_separator|>", "");
    filteredResponse = filteredResponse.replaceAll("<|end_of_text|>", "");
    // Add other model-specific tokens here...
    filteredResponse = filteredResponse.replaceAll(
        RegExp(r'\n{3,}'), '\n\n'); // Limit consecutive newlines

    // 4. Remove HTML Tags (If Applicable):
    filteredResponse = filteredResponse.replaceAll(RegExp(r'<[^>]*>'), '');

    // 5. Normalize Punctuation (Be Careful):
    filteredResponse = filteredResponse.replaceAll(
        RegExp(r'\.{2,}'), '...'); // Normalize ellipses
    filteredResponse = filteredResponse.replaceAll(
        RegExp(r'!{2,}'), '!'); // Normalize exclamation marks
    filteredResponse = filteredResponse.replaceAll(
        RegExp(r'\?{2,}'), '?'); // Normalize question marks

    return filteredResponse;
  }
}
