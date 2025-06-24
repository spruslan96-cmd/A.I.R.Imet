import 'package:flutter/material.dart';

class NowDownloadingCard extends StatelessWidget {
  final dynamic model;
  final Function(String) onCancelDownload;
  final double downloadProgress;
  final int? modelSize;

  const NowDownloadingCard({
    super.key,
    required this.model,
    required this.onCancelDownload,
    required this.downloadProgress,
    required this.modelSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String modelId = model['id'] ?? 'Unknown';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          /// Progress background
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: downloadProgress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          /// Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                /// Icon
                Icon(Icons.downloading, color: theme.colorScheme.primary),

                const SizedBox(width: 16),

                /// Model info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelId,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          if (modelSize != null)
                            Text(
                              "Size: ${(modelSize! / (1024 * 1024)).toStringAsFixed(1)} MB",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            "${(downloadProgress * 100).toStringAsFixed(0)}%",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Spinner + Cancel button
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                        strokeWidth: 3,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: "Cancel download",
                      icon: const Icon(Icons.cancel),
                      color: theme.colorScheme.error,
                      onPressed: () => onCancelDownload(modelId),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
