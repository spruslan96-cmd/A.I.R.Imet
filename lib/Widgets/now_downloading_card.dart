import 'package:flutter/material.dart';

class NowDownloadingCard extends StatelessWidget {
  final dynamic model;
  final Function(String) onCancelDownload;
  final double downloadProgress;
  final int? modelSize;

  const NowDownloadingCard({
    Key? key,
    required this.model,
    required this.onCancelDownload,
    required this.downloadProgress,
    required this.modelSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // Green progress background
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: downloadProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text(model['id']),
            subtitle: modelSize != null
                ? Text("Size: ${modelSize! ~/ (1024 * 1024)} MB")
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: downloadProgress,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onCancelDownload(model['id']),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
