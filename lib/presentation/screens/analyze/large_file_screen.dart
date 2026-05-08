import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../platform/channels.dart';

final largeFilesProvider = FutureProvider.family<List<NativeScanResult>, String>((ref, path) async {
  return FileChannel.scanPath(path: path, recursive: true, engine: 'auto');
});

class LargeFileScreen extends ConsumerStatefulWidget {
  const LargeFileScreen({super.key});

  @override
  ConsumerState<LargeFileScreen> createState() => _LargeFileScreenState();
}

class _LargeFileScreenState extends ConsumerState<LargeFileScreen> {
  String _sortBy = 'size';
  bool _ascending = false;
  int _minSizeMb = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filesAsync = ref.watch(largeFilesProvider('/storage/emulated/0'));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.largeFileAnalysis),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'size', child: Text(l10n.sortBySize)),
              PopupMenuItem(value: 'time', child: Text(l10n.sortByTime)),
              PopupMenuItem(value: 'name', child: Text(l10n.sortByName)),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.sort),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.minFileSize(_minSizeMb), style: Theme.of(context).textTheme.bodyMedium),
                Slider(
                  value: _minSizeMb.toDouble(),
                  min: 1,
                  max: 500,
                  divisions: 99,
                  label: '$_minSizeMb MB',
                  onChanged: (v) => setState(() => _minSizeMb = v.toInt()),
                ),
              ],
            ),
          ),
          Expanded(
            child: filesAsync.when(
              data: (files) {
                final minBytes = _minSizeMb * 1024 * 1024;
                var filtered = files.where((f) => f.size >= minBytes && !f.isDirectory).toList();

                filtered.sort((a, b) {
                  final cmp = switch (_sortBy) {
                    'size' => a.size.compareTo(b.size),
                    'time' => a.lastModified.compareTo(b.lastModified),
                    'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    _ => 0,
                  };
                  return _ascending ? cmp : -cmp;
                });

                if (filtered.isEmpty) {
                  return Center(child: Text(l10n.noLargeFiles));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final file = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      trailing: Text(formatBytes(file.size), style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: file.size > 100 * 1024 * 1024 ? Colors.red : null,
                      )),
                      onTap: () => _showFileOptions(context, file),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.scanFailed('$e'))),
            ),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(BuildContext context, NativeScanResult file) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${formatBytes(file.size)} · ${file.path}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(l10n.deleteThisFile),
              onTap: () async {
                Navigator.pop(context);
                final result = await FileChannel.deleteFiles([file.path]);
                final success = (result['successCount'] as int? ?? 0) > 0;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? l10n.deleted : l10n.deleteFailed)),
                  );
                  ref.invalidate(largeFilesProvider('/storage/emulated/0'));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.viewDirectory),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
