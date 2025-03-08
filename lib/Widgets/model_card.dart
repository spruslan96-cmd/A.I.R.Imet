import 'package:flutter/material.dart';

class ModelCard extends StatefulWidget {
  final dynamic model;
  final Function(String) onDownload;
  final Function(String)? onCancelDownload; // Made optional
  final Function(String) onDelete;
  final bool modelExists;
  final double downloadProgress;
  final int? modelSize;

  const ModelCard({
    Key? key,
    required this.model,
    required this.onDownload,
    this.onCancelDownload, // Optional now
    required this.onDelete,
    required this.modelExists,
    required this.downloadProgress,
    required this.modelSize,
  }) : super(key: key);

  @override
  State<ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  bool _isDownloading = false;

  void _cancelDownload() {
    if (widget.onCancelDownload != null) {
      widget.onCancelDownload!(widget.model['id']); // Call if available
      setState(() {
        _isDownloading = false; // Reset state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modelSize == null) {
      return const SizedBox.shrink(); // Hide card if size is not available
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Green progress bar
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widget.downloadProgress,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Foreground content
          ListTile(
            title: Text(widget.model['id']),
            subtitle: Text("Size: ${widget.modelSize! ~/ (1024 * 1024)} MB"),
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
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: widget.downloadProgress,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.onCancelDownload !=
                              null) // Show only if available
                            IconButton(
                              onPressed: _cancelDownload,
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: "Cancel Download",
                            ),
                        ],
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
        ],
      ),
    );
  }
}
