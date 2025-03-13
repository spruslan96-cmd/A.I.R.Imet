import 'package:flutter/material.dart';

class ModelCard extends StatefulWidget {
  final dynamic model;
  final Function(String) onDownload;
  final Function(String)? onCancelDownload;
  final Function onDelete;
  final bool modelExists;
  final double downloadProgress;
  final int? modelSize;

  const ModelCard({
    Key? key,
    required this.model,
    required this.onDownload,
    this.onCancelDownload,
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

  @override
  void didUpdateWidget(covariant ModelCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If download progress is complete, reset the downloading state
    if (widget.downloadProgress >= 1.0) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _cancelDownload() {
    if (widget.onCancelDownload != null) {
      widget.onCancelDownload!(widget.model['id']);
      setState(() {
        _isDownloading = false; // Reset download state when canceled
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
          // Green progress bar (fills as download progresses)
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
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  )
                : _isDownloading || widget.downloadProgress > 0.0
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
                          if (widget.onCancelDownload != null)
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
