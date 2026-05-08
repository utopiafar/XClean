import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../platform/channels.dart';
import '../../providers/dashboard_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionStatusProvider);
    final romTypeAsync = ref.watch(romTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '权限'),
          permissionAsync.when(
            data: (status) => ListTile(
              leading: Icon(
                status == 'granted' ? Icons.check_circle : Icons.warning,
                color: status == 'granted' ? Colors.green : Colors.orange,
              ),
              title: const Text('存储权限'),
              subtitle: Text(_permissionLabel(status)),
              trailing: status != 'granted'
                  ? FilledButton(
                      onPressed: () async {
                        final granted = await PermissionChannel.requestAllFilesAccess();
                        if (granted) {
                          ref.invalidate(permissionStatusProvider);
                          ref.invalidate(storageInfoProvider);
                        }
                      },
                      child: const Text('授权'),
                    )
                  : null,
            ),
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('检查权限中...'),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.error),
              title: Text('无法检查权限'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.battery_alert),
            title: const Text('电池优化'),
            subtitle: const Text('避免被系统后台清理'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await PermissionChannel.requestIgnoreBatteryOptimization();
              },
              child: const Text('设置'),
            ),
          ),
          _buildSectionHeader(context, '系统信息'),
          romTypeAsync.when(
            data: (rom) => ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('系统类型'),
              subtitle: Text(rom.toUpperCase()),
            ),
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('检测中...'),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.error),
              title: Text('无法检测'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            subtitle: const Text('0.1.0'),
          ),
          _buildSectionHeader(context, '数据'),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('清空日志'),
            subtitle: const Text('删除所有清理历史记录'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('确认清空'),
                  content: const Text('此操作不可恢复，确定要清空所有日志吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('确定'),
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
                    const SnackBar(content: Text('日志已清空')),
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

  String _permissionLabel(String status) {
    return switch (status) {
      'granted' => '已授权全部文件访问',
      'partial' => '仅部分授权',
      'denied' => '未授权',
      _ => '未知',
    };
  }
}
