import 'package:flutter/material.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../platform/channels.dart';

const _scanRootPath = '/storage/emulated/0';
const _sizeStepMb = 100;
const _minThresholdMb = 100;
const _maxThresholdMb = 5120;
const _sizePresetsMb = [100, 500, 1024, 2048, 5120];

class LargeFileScreen extends StatefulWidget {
  const LargeFileScreen({super.key});

  @override
  State<LargeFileScreen> createState() => _LargeFileScreenState();
}

class _LargeFileScreenState extends State<LargeFileScreen> {
  String _sortBy = 'size';
  int _minSizeMb = 500;
  bool _isScanning = false;
  bool _hasScanned = false;
  String? _error;
  List<NativeScanResult> _files = const [];
  int _scanRunId = 0;

  int get _minSizeBytes => _minSizeMb * 1024 * 1024;

  List<NativeScanResult> get _filteredFiles {
    final minBytes = _minSizeBytes;
    final filtered = _files
        .where((file) => file.size >= minBytes && !file.isDirectory)
        .toList();

    filtered.sort((a, b) {
      return switch (_sortBy) {
        'time' => b.lastModified.compareTo(a.lastModified),
        'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _ => b.size.compareTo(a.size),
      };
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.largeFileAnalysis),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.sort,
            icon: const Icon(Icons.sort),
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'size',
                checked: _sortBy == 'size',
                child: Text(l10n.sortBySize),
              ),
              CheckedPopupMenuItem(
                value: 'time',
                checked: _sortBy == 'time',
                child: Text(l10n.sortByTime),
              ),
              CheckedPopupMenuItem(
                value: 'name',
                checked: _sortBy == 'name',
                child: Text(l10n.sortByName),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 3,
            child: _isScanning ? const LinearProgressIndicator() : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                const _LargeFilePermissionNotice(),
                const SizedBox(height: 12),
                _buildScanPanel(context, l10n),
              ],
            ),
          ),
          Expanded(child: _buildContent(context, l10n)),
        ],
      ),
    );
  }

  Widget _buildScanPanel(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.largeFileThreshold(_formatThreshold(_minSizeMb)),
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _scanRootPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final preset in _sizePresetsMb) ...[
                    ChoiceChip(
                      label: Text(_formatThreshold(preset)),
                      selected: _minSizeMb == preset,
                      onSelected: _isScanning
                          ? null
                          : (_) => _setThreshold(preset),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: l10n.decreaseThreshold,
                  onPressed: _isScanning
                      ? null
                      : () => _setThreshold(_minSizeMb - _sizeStepMb),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _formatThreshold(_minSizeMb),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: l10n.increaseThreshold,
                  onPressed: _isScanning
                      ? null
                      : () => _setThreshold(_minSizeMb + _sizeStepMb),
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isScanning ? null : _scanLargeFiles,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_hasScanned ? l10n.rescan : l10n.scan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (_isScanning) {
      return _CenteredState(
        icon: Icons.manage_search,
        title: l10n.scanning,
        subtitle: l10n.largeFileScanningHint,
        progress: true,
      );
    }

    if (_error != null) {
      return _CenteredState(
        icon: Icons.error_outline,
        title: l10n.scanFailed(_error!),
        action: FilledButton.icon(
          onPressed: _scanLargeFiles,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.rescan),
        ),
      );
    }

    if (!_hasScanned) {
      return _CenteredState(
        icon: Icons.insert_drive_file_outlined,
        title: l10n.largeFileNotScanned,
        subtitle: l10n.largeFileReadySummary(_formatThreshold(_minSizeMb)),
      );
    }

    final files = _filteredFiles;
    if (files.isEmpty) {
      return _CenteredState(
        icon: Icons.check_circle_outline,
        title: l10n.noLargeFiles,
        subtitle: l10n.largeFileReadySummary(_formatThreshold(_minSizeMb)),
        action: OutlinedButton.icon(
          onPressed: _scanLargeFiles,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.rescan),
        ),
      );
    }

    return Column(
      children: [
        _buildResultSummary(context, l10n, files),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: files.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _LargeFileTile(
              file: files[index],
              onTap: () => _showFileOptions(context, files[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSummary(
    BuildContext context,
    AppLocalizations l10n,
    List<NativeScanResult> files,
  ) {
    final totalBytes = files.fold<int>(0, (total, file) => total + file.size);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.largeFileScanSummary(
                    files.length,
                    formatBytes(totalBytes),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatThreshold(_minSizeMb),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanLargeFiles() async {
    final runId = ++_scanRunId;
    setState(() {
      _isScanning = true;
      _hasScanned = true;
      _error = null;
      _files = const [];
    });

    try {
      final files = await FileChannel.scanPath(
        path: _scanRootPath,
        recursive: true,
        engine: 'auto',
        minSizeBytes: _minSizeBytes,
      );
      if (!mounted || runId != _scanRunId) return;
      setState(() {
        _files = files;
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted || runId != _scanRunId) return;
      setState(() {
        _error = e.toString();
        _isScanning = false;
      });
    }
  }

  void _setThreshold(int value) {
    final clamped = value.clamp(_minThresholdMb, _maxThresholdMb).toInt();
    final stepped = clamped == _maxThresholdMb
        ? _maxThresholdMb
        : ((clamped / _sizeStepMb).round() * _sizeStepMb)
              .clamp(_minThresholdMb, _maxThresholdMb)
              .toInt();
    setState(() {
      _minSizeMb = stepped;
      _hasScanned = false;
      _error = null;
      _files = const [];
    });
  }

  String _formatThreshold(int sizeMb) {
    if (sizeMb >= 1024 && sizeMb % 1024 == 0) {
      return '${sizeMb ~/ 1024} GB';
    }
    return '$sizeMb MB';
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
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
                    SnackBar(
                      content: Text(success ? l10n.deleted : l10n.deleteFailed),
                    ),
                  );
                  if (success) {
                    setState(() {
                      _files = _files
                          .where((item) => item.path != file.path)
                          .toList();
                    });
                  }
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

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.progress = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool progress;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colors.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (progress) ...[
              const SizedBox(height: 18),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _LargeFilePermissionNotice extends StatefulWidget {
  const _LargeFilePermissionNotice();

  @override
  State<_LargeFilePermissionNotice> createState() =>
      _LargeFilePermissionNoticeState();
}

class _LargeFilePermissionNoticeState
    extends State<_LargeFilePermissionNotice> {
  late Future<String> _permissionFuture;

  @override
  void initState() {
    super.initState();
    _permissionFuture = PermissionChannel.getPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<String>(
      future: _permissionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            snapshot.data == 'granted') {
          return const SizedBox.shrink();
        }

        return Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.storagePermissionNeeded,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Text(
                        l10n.storagePermissionRequired,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final granted =
                        await PermissionChannel.requestAllFilesAccess();
                    if (!context.mounted) return;
                    if (!granted) {
                      await PermissionChannel.openAppSettings();
                    } else {
                      setState(() {
                        _permissionFuture =
                            PermissionChannel.getPermissionStatus();
                      });
                    }
                  },
                  child: Text(l10n.grantPermission),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LargeFileTile extends StatelessWidget {
  const _LargeFileTile({required this.file, required this.onTap});

  final NativeScanResult file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.blue),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        file.path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        formatBytes(file.size),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }
}
