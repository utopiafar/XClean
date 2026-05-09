import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../core/utils/size_formatter.dart';
import '../../providers/dashboard_provider.dart';
import 'log_detail_screen.dart';

class LogListScreen extends ConsumerWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(allLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewLogs),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.noLogs,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    log.taskType == 'auto' ? Icons.schedule : Icons.touch_app,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    '${formatBytes(log.results.freedBytes)} · ${l10n.nFiles(log.results.fileCount)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(log.executedAt)} · ${l10n.successFailCount(log.results.successCount, log.results.failCount)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LogDetailScreen(log: log),
                  )),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadFailed('$e'))),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
