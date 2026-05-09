import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../domain/entities/clean_log.dart';

class LogDetailScreen extends ConsumerWidget {
  final CleanLogEntity log;

  const LogDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final deletedFiles = _parseDeletedFiles(log.details);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cleanComplete),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context, l10n),
          const SizedBox(height: 16),
          if (deletedFiles.isNotEmpty) ...[
            Text(
              l10n.deletedFilesTitle(deletedFiles.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: deletedFiles.map((name) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file, size: 20),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                )).toList(),
              ),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.noDeletedFilesDetail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(l10n.releasedSpace(formatBytes(log.results.freedBytes))),
            _buildInfoRow(l10n.fileCount(log.results.fileCount)),
            _buildInfoRow(l10n.successFailCount(log.results.successCount, log.results.failCount)),
            _buildInfoRow(l10n.duration(formatDuration(log.results.durationMs))),
            _buildInfoRow('${_formatDateTime(log.executedAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  List<String> _parseDeletedFiles(String? details) {
    if (details == null || details.isEmpty) return [];
    return details.split('\n').where((s) => s.isNotEmpty).toList();
  }

  String _formatDateTime(DateTime dt) {
    final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
