import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../platform/channels.dart';
import '../../providers/dashboard_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final permissionAsync = ref.watch(permissionStatusProvider);
    final romTypeAsync = ref.watch(romTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, l10n.permissionStatus),
          permissionAsync.when(
            data: (status) => ListTile(
              leading: Icon(
                status == 'granted' ? Icons.check_circle : Icons.warning,
                color: status == 'granted' ? Colors.green : Colors.orange,
              ),
              title: Text(l10n.storagePermission),
              subtitle: Text(_permissionLabel(status, l10n)),
              trailing: status != 'granted'
                  ? FilledButton(
                      onPressed: () async {
                        final granted = await PermissionChannel.requestAllFilesAccess();
                        if (granted) {
                          ref.invalidate(permissionStatusProvider);
                          ref.invalidate(storageInfoProvider);
                        }
                      },
                      child: Text(l10n.grantPermission),
                    )
                  : null,
            ),
            loading: () => ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(l10n.checkingPermission),
            ),
            error: (_, __) => ListTile(
              leading: const Icon(Icons.error),
              title: Text(l10n.cannotCheckPermission),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.battery_alert),
            title: Text(l10n.batteryOptimization),
            subtitle: Text(l10n.avoidBatteryKill),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await PermissionChannel.requestIgnoreBatteryOptimization();
              },
              child: Text(l10n.settings),
            ),
          ),
          _buildSectionHeader(context, l10n.systemInfo),
          romTypeAsync.when(
            data: (rom) => ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(l10n.systemType),
              subtitle: Text(rom.toUpperCase()),
            ),
            loading: () => ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(l10n.detecting),
            ),
            error: (_, __) => ListTile(
              leading: const Icon(Icons.error),
              title: Text(l10n.cannotDetect),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: const Text('0.1.0'),
          ),
          _buildSectionHeader(context, l10n.dataSection),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.viewLogs),
            subtitle: Text(l10n.viewLogsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/logs'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(l10n.clearLogs),
            subtitle: Text(l10n.clearLogsDesc),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.confirmClearLogsTitle),
                  content: Text(l10n.confirmClearLogsMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.confirm),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final db = ref.read(databaseProvider);
                await db.delete(db.cleanLogs).go();
                ref.invalidate(recentLogsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.logsCleared)),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _permissionLabel(String status, AppLocalizations l10n) {
    return switch (status) {
      'granted' => l10n.fullAccessGranted,
      'partial' => l10n.partialAccess,
      'denied' => l10n.notGranted,
      _ => l10n.unknownStatus,
    };
  }
}
