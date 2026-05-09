import 'package:flutter/material.dart';
import 'package:xclean/l10n/app_localizations.dart';

import '../../../platform/channels.dart';

class DiagnosticLogScreen extends StatefulWidget {
  const DiagnosticLogScreen({super.key});

  @override
  State<DiagnosticLogScreen> createState() => _DiagnosticLogScreenState();
}

class _DiagnosticLogScreenState extends State<DiagnosticLogScreen> {
  late Future<String> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = FileChannel.getDiagnosticLogs();
  }

  void _refresh() {
    setState(() {
      _logsFuture = FileChannel.getDiagnosticLogs();
    });
  }

  Future<void> _clearLogs() async {
    await FileChannel.clearDiagnosticLogs();
    _refresh();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.diagnosticLogsCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagnosticLogs),
        actions: [
          IconButton(
            tooltip: l10n.refreshDiagnosticLogs,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: l10n.clearDiagnosticLogs,
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(l10n.loadFailed('${snapshot.error}')));
          }

          final logs = snapshot.data?.trimRight() ?? '';
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.noDiagnosticLogs,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              logs,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.35,
              ),
            ),
          );
        },
      ),
    );
  }
}
