import 'package:flutter/material.dart';

class DownloadedModelCard extends StatelessWidget {
  final dynamic model;
  final Function(String) onDelete;
  final int? modelSize;

  const DownloadedModelCard({
    Key? key,
    required this.model,
    required this.onDelete,
    required this.modelSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(model['id']),
        subtitle: modelSize != null
            ? Text("Size: ${modelSize! ~/ (1024 * 1024)} MB")
            : null,
        trailing: IconButton(
          onPressed: () => onDelete(model['id']),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    );
  }
}
