import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../domain/entities/clean_log.dart';
import '../../providers/dashboard_provider.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scanState = ref.watch(scanProvider);
    final files = scanState.files;
    final selectedCount = files.where((f) => f.selected).length;
    final selectedSize = files.where((f) => f.selected).fold<int>(0, (sum, f) => sum + f.size);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cleanPreview),
        actions: [
          TextButton(
            onPressed: () => ref.read(scanProvider.notifier).selectAll(true),
            child: Text(l10n.selectAll),
          ),
          TextButton(
            onPressed: () => ref.read(scanProvider.notifier).selectAll(false),
            child: Text(l10n.selectNone),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(context, l10n, selectedCount, files.length, selectedSize),
          Expanded(
            child: files.isEmpty
                ? Center(child: Text(l10n.noMatchedFilesPreview))
                : _buildFileGrid(context, ref, files),
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
                      child: Text(l10n.cancel),
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
                      label: Text(l10n.cleanWithSize(formatBytes(selectedSize))),
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

  Widget _buildStatsBar(
    BuildContext context,
    AppLocalizations l10n,
    int selectedCount,
    int totalCount,
    int selectedSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectedCount(selectedCount, totalCount),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  l10n.releasable(formatBytes(selectedSize)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid(BuildContext context, WidgetRef ref, List<ScannedFile> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileGridItem(
          file: file,
          onToggle: () => ref.read(scanProvider.notifier).toggleSelection(index),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _executeClean(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(scanProvider.notifier);
    final startTime = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n.cleaning),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await notifier.executeClean();
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      final finalResult = result.copyWith(durationMs: duration);

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
            title: Text(l10n.cleanComplete),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.releasedSpace(formatBytes(finalResult.freedBytes))),
                Text(l10n.fileCount(finalResult.fileCount)),
                Text(l10n.successFailCount(finalResult.successCount, finalResult.failCount)),
                Text(l10n.duration(formatDuration(finalResult.durationMs))),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cleanFailed('$e'))),
        );
      }
    }
  }
}

class _FileGridItem extends StatelessWidget {
  final ScannedFile file;
  final VoidCallback onToggle;

  const _FileGridItem({required this.file, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail or file icon
          _buildThumbnail(),

          // Selection overlay
          if (file.selected)
            Container(
              color: Colors.black.withOpacity(0.3),
            ),

          // Checkmark indicator
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: file.selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: file.selected
                    ? null
                    : Border.all(color: Colors.white, width: 1.5),
              ),
              child: file.selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),

          // File name at bottom (only for non-images or small text)
          if (!file.isDirectory && !_isImageFile(file.name))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.black.withOpacity(0.6),
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Directory label
          if (file.isDirectory)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.amber.withOpacity(0.8),
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (file.isDirectory) {
      return Container(
        color: Colors.amber.withOpacity(0.15),
        child: const Center(
          child: Icon(Icons.folder_outlined, size: 40, color: Colors.amber),
        ),
      );
    }

    if (_isImageFile(file.name)) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFileTypeFallback(),
      );
    }

    return _buildFileTypeFallback();
  }

  Widget _buildFileTypeFallback() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_fileTypeIcon(), size: 32, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              _fileTypeLabel(),
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'}.contains(ext);
  }

  IconData _fileTypeIcon() {
    final ext = file.name.split('.').last.toLowerCase();
    return switch (ext) {
      'mp4' || 'mkv' || 'avi' || 'mov' || 'wmv' => Icons.video_file_outlined,
      'mp3' || 'aac' || 'flac' || 'wav' || 'ogg' => Icons.audio_file_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip_outlined,
      'apk' => Icons.android_outlined,
      'txt' || 'log' || 'md' => Icons.text_snippet_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  String _fileTypeLabel() {
    final ext = file.name.split('.').last.toUpperCase();
    return ext.isEmpty ? 'FILE' : ext;
  }
}
