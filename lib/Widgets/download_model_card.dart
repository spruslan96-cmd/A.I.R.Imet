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

  List<String> _extractBadges(dynamic model) {
    final List<String> tags = (model['tags'] as List?)?.cast<String>() ?? [];
    final List<String> badgeKeywords = [
      "quantized",
      "gguf",
      "llama",
      "int8",
      "int4",
      "chat",
    ];

    return badgeKeywords
        .where((tag) =>
            model['id'].toString().toLowerCase().contains(tag) ||
            tags.any((t) => t.toLowerCase().contains(tag)))
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String modelId = model['id'] ?? 'Unknown';
    final String? description = model['cardData']?['description'];
    final int downloads = model['downloads'] ?? 0;
    final int likes = model['likes'] ?? 0;
    final List<String> badges = _extractBadges(model);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Model Name + Download Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Model Name and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelId,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                /// Download Button
                FilledButton.icon(
                  onPressed: () => onDownload(modelId),
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Badges
            Wrap(
              spacing: 6,
              runSpacing: -8,
              children: badges.map((tag) {
                return Chip(
                  label: Text(tag.toUpperCase()),
                  labelStyle: theme.textTheme.labelSmall,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            /// Stats Row
            Row(
              children: [
                Icon(Icons.download,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('$downloads', style: theme.textTheme.labelSmall),
                const SizedBox(width: 16),
                Icon(Icons.thumb_up,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('$likes', style: theme.textTheme.labelSmall),
                const SizedBox(width: 16),
                if (modelSize != null)
                  Row(
                    children: [
                      Icon(Icons.storage,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${(modelSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
