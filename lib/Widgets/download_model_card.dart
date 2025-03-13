import 'package:flutter/material.dart';

class DownloadModelCard extends StatelessWidget {
  final dynamic model;
  final Function(String) onDownload;
  final int? modelSize;

  const DownloadModelCard({
    Key? key,
    required this.model,
    required this.onDownload,
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
        trailing: ElevatedButton(
          onPressed: () => onDownload(model['id']),
          child: const Text("Download"),
        ),
      ),
    );
  }
}
