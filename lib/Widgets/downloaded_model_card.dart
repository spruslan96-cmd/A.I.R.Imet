import 'package:flutter/material.dart';

class DownloadedModelCard extends StatelessWidget {
  final dynamic model;
  final Function(String) onDelete;
  final int? modelSize;

  const DownloadedModelCard({
    super.key,
    required this.model,
    required this.onDelete,
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
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            /// Icon
            Icon(Icons.storage, color: theme.colorScheme.primary),

            const SizedBox(width: 16),

            /// Info
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
                  if (modelSize != null)
                    Text(
                      "Size: ${(modelSize! / (1024 * 1024)).toStringAsFixed(1)} MB",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            /// Delete button
            IconButton(
              tooltip: "Delete model",
              icon: const Icon(Icons.delete),
              color: theme.colorScheme.error,
              onPressed: () => onDelete(modelId),
            ),
          ],
        ),
      ),
    );
  }
}
