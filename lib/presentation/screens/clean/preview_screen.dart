import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../domain/entities/clean_log.dart';
import '../../providers/dashboard_provider.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final files = scanState.files;
    final selectedCount = files.where((f) => f.selected).length;
    final selectedSize = files.where((f) => f.selected).fold<int>(0, (sum, f) => sum + f.size);

    return Scaffold(
      appBar: AppBar(
        title: const Text('清理预览'),
        actions: [
          TextButton(
            onPressed: () => ref.read(scanProvider.notifier).selectAll(true),
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: () => ref.read(scanProvider.notifier).selectAll(false),
            child: const Text('全不选'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已选择 $selectedCount / ${files.length} 个文件',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '可释放 ${formatBytes(selectedSize)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: files.isEmpty
                ? const Center(child: Text('没有匹配的文件'))
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return CheckboxListTile(
                        value: file.selected,
                        onChanged: (_) => ref.read(scanProvider.notifier).toggleSelection(index),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${file.isDirectory ? "目录" : formatBytes(file.size)} · ${_formatDate(file.lastModified)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: Icon(
                          file.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
                          color: file.isDirectory ? Colors.amber : Colors.blue,
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(scanProvider.notifier).clear();
                        context.pop();
                      },
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: selectedCount == 0
                          ? null
                          : () => _executeClean(context, ref),
                      icon: const Icon(Icons.delete_outline),
                      label: Text('清理 (${formatBytes(selectedSize)})'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _executeClean(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(scanProvider.notifier);
    final startTime = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在清理...'),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await notifier.executeClean();
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      final finalResult = result.copyWith(durationMs: duration);

      // Save log
      await ref.read(logRepositoryProvider).insertLog(CleanLogEntity(
        id: 0,
        executedAt: DateTime.now(),
        taskType: 'manual',
        rulesApplied: [],
        results: finalResult,
      ));

      if (context.mounted) {
        Navigator.of(context).pop();
        notifier.clear();
        ref.invalidate(recentLogsProvider);
        ref.invalidate(storageInfoProvider);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('清理完成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('释放空间: ${formatBytes(finalResult.freedBytes)}'),
                Text('文件数量: ${finalResult.fileCount}'),
                Text('成功: ${finalResult.successCount}  失败: ${finalResult.failCount}'),
                Text('耗时: ${formatDuration(finalResult.durationMs)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败: $e')),
        );
      }
    }
  }
}
