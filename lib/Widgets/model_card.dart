import 'package:flutter/material.dart';

class ModelCard extends StatefulWidget {
  final dynamic model;
  final Function(String) onDownload;
  final bool modelExists;
  final double downloadProgress;
  final int? modelSize;
  final Function(String) onDelete;

  const ModelCard({
    Key? key,
    required this.model,
    required this.onDownload,
    required this.modelExists,
    required this.downloadProgress,
    required this.modelSize,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.modelExists ? Colors.green[200] : null,
      child: ListTile(
        title: Text(widget.model['id']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.model['description'] ?? "No Description"),
            if (widget.modelSize != null)
              Text("Size: ${widget.modelSize! ~/ (1024 * 1024)} MB"),
          ],
        ),
        trailing: widget.modelExists
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, color: Colors.green),
                  IconButton(
                    onPressed: () {
                      widget.onDelete(widget.model['id']);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              )
            : _isDownloading
                ? LinearProgressIndicator(
                    value: widget.downloadProgress,
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isDownloading = true;
                      });
                      widget.onDownload(widget.model['id']);
                    },
                    child: const Text("Download"),
                  ),
      ),
    );
  }
}
