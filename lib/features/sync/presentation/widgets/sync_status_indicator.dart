import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/sync_providers.dart';
import '../../../../core/domain/sync_status.dart';

/// A widget that displays the current sync status
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    
    return syncStatusAsync.when(
      data: (status) => _buildStatusIcon(status),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, _) => Icon(
        Icons.sync_problem,
        color: Colors.red[600],
        size: 20,
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          color: Colors.grey[600],
          size: 20,
        );
      case SyncStatus.syncing:
      case SyncStatus.syncingInbound:
      case SyncStatus.syncingOutbound:
      case SyncStatus.preparing:
      case SyncStatus.merging:
      case SyncStatus.finalizing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.synced:
      case SyncStatus.completed:
        return Icon(
          Icons.cloud_done,
          color: Colors.green[600],
          size: 20,
        );
      case SyncStatus.error:
      case SyncStatus.cancelled:
        return Icon(
          Icons.cloud_off,
          color: Colors.red[600],
          size: 20,
        );
      case SyncStatus.idle:
      default:
        return Icon(
          Icons.cloud_queue,
          color: Colors.grey[400],
          size: 20,
        );
    }
  }
}

/// A more detailed sync status widget with text and last sync time
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SyncStatusIndicator(),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.read(manualSyncProvider.notifier).performManualSync(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            syncStatusAsync.when(
              data: (status) => Text(_getStatusText(status)),
              loading: () => const Text('Checking sync status...'),
              error: (error, _) => Text('Sync error: ${error.toString()}'),
            ),
            const SizedBox(height: 4),
            Text(
              lastSync != null 
                ? 'Last synced: ${_formatLastSync(lastSync)}'
                : 'Never synced',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return 'Working offline - data saved locally';
      case SyncStatus.syncing:
      case SyncStatus.syncingInbound:
      case SyncStatus.syncingOutbound:
      case SyncStatus.preparing:
      case SyncStatus.merging:
      case SyncStatus.finalizing:
        return 'Syncing your data...';
      case SyncStatus.synced:
      case SyncStatus.completed:
        return 'All data is up to date';
      case SyncStatus.error:
      case SyncStatus.cancelled:
        return 'Sync temporarily unavailable';
      case SyncStatus.idle:
      default:
        return 'Ready to sync';
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}