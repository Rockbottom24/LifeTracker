import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfflineSyncBanner extends StatelessWidget {
  const OfflineSyncBanner({
    super.key,
    required this.isOffline,
    this.syncMessage,
    this.lastSyncedAt,
    this.isRefreshing = false,
    this.hasPendingSync = false,
  });

  final bool isOffline;
  final String? syncMessage;
  final DateTime? lastSyncedAt;
  final bool isRefreshing;
  final bool hasPendingSync;

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !isRefreshing && syncMessage == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isPendingOnly = hasPendingSync && !isOffline;
    final lastSyncedLabel = lastSyncedAt == null
        ? null
        : 'Last synced ${DateFormat('MMM d, h:mm a').format(lastSyncedAt!)}';

    final backgroundColor = isOffline
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.92)
        : isPendingOnly
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.92)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.92);

    final foregroundColor = isOffline
        ? theme.colorScheme.onErrorContainer
        : isPendingOnly
            ? theme.colorScheme.onTertiaryContainer
            : theme.colorScheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                isOffline
                    ? Icons.cloud_off_outlined
                    : isPendingOnly
                        ? Icons.cloud_upload_outlined
                        : Icons.sync_rounded,
                size: 20,
                color: foregroundColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncMessage ??
                          (isRefreshing ? 'Syncing latest data...' : 'Connected'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                    if (lastSyncedLabel != null)
                      Text(
                        lastSyncedLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
              if (isRefreshing)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
