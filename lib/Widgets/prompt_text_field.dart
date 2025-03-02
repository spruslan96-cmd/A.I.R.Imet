import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromptTextField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PromptTextField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<PromptTextField> createState() => _PromptTextFieldState();
}

class _PromptTextFieldState extends State<PromptTextField> {
  int _charCount = 0;
  final int _charLimit = 1000;
  final double _maxHeight = 150.0;
  bool _isScrollable = false;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharCount);
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      _charCount = widget.controller.text.length;
      _isScrollable = widget.controller.text.split('\n').length >
          (_maxHeight / 20); // Adjust 20 as needed
    });
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: _maxHeight),
          child: Scrollbar(
            thumbVisibility: _isScrollable, // Show scrollbar only if scrollable
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              reverse: true,
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_charLimit),
                ],
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(8.0),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('$_charCount / $_charLimit',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
