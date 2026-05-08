import 'package:flutter/material.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../platform/channels.dart';

/// A simple directory picker dialog that uses dart:io directly.
/// Requires MANAGE_EXTERNAL_STORAGE permission on Android.
class DirectoryPickerDialog extends StatefulWidget {
  final String initialPath;
  final String title;

  const DirectoryPickerDialog({
    super.key,
    this.initialPath = '/storage/emulated/0',
    this.title = '',
  });

  @override
  State<DirectoryPickerDialog> createState() => _DirectoryPickerDialogState();

  static Future<String?> show(BuildContext context, {String? initialPath}) {
    return showDialog<String>(
      context: context,
      builder: (_) => DirectoryPickerDialog(
        initialPath: initialPath ?? '/storage/emulated/0',
      ),
    );
  }
}

class _DirectoryPickerDialogState extends State<DirectoryPickerDialog> {
  late String _currentPath;
  List<_DirItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Use FileChannel.scanPath instead of dart:io Directory
      // to leverage MANAGE_EXTERNAL_STORAGE permission through native layer
      final results = await FileChannel.scanPath(
        path: _currentPath,
        recursive: false,
        engine: 'auto',
      );

      final dirs = results
          .where((r) => r.isDirectory)
          .map((r) => _DirItem(
                name: r.name,
                path: r.path,
              ))
          .toList();

      dirs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _items = dirs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.loadDirectoryFailed('$e');
        _loading = false;
      });
    }
  }

  void _goUp() {
    final parent = _getParentPath(_currentPath);
    if (parent == _currentPath) return; // at root
    setState(() => _currentPath = parent);
    _loadDirectory();
  }

  String _getParentPath(String path) {
    final trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final lastSlash = trimmed.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return trimmed.substring(0, lastSlash);
  }

  void _enterDirectory(String path) {
    setState(() => _currentPath = path);
    _loadDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title.isEmpty ? l10n.selectDirectory : widget.title),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Current path bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: l10n.goUp,
                    onPressed: _canGoUp() ? _goUp : null,
                  ),
                  Expanded(
                    child: Text(
                      _currentPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Directory list
            Expanded(
              child: _buildBody(l10n),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_currentPath),
          child: Text(l10n.selectThisDirectory),
        ),
      ],
    );
  }

  bool _canGoUp() {
    final parent = _getParentPath(_currentPath);
    return parent != _currentPath;
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(child: Text(l10n.thisDirectoryIsEmpty));
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.folder, color: Colors.amber),
          title: Text(item.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _enterDirectory(item.path),
        );
      },
    );
  }
}

class _DirItem {
  final String name;
  final String path;

  _DirItem({required this.name, required this.path});
}
