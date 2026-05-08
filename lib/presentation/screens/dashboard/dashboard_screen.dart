import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../domain/entities/clean_log.dart';
import '../../../domain/entities/clean_rule.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/permission_banner.dart';
import '../../widgets/storage_ring.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final rules = await ref.read(ruleRepositoryProvider).getAllRules();
    if (rules.isEmpty) {
      await ref.read(ruleRepositoryProvider).initPresetRules();
    }
    ref.invalidate(enabledRulesProvider);
    ref.invalidate(recentLogsProvider);
    ref.invalidate(storageInfoProvider);
  }

  @override
  Widget build(BuildContext context) {
    final storageAsync = ref.watch(storageInfoProvider);
    final enabledRulesAsync = ref.watch(enabledRulesProvider);
    final recentLogsAsync = ref.watch(recentLogsProvider);
    final romTypeAsync = ref.watch(romTypeProvider);
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storageInfoProvider);
          ref.invalidate(enabledRulesProvider);
          ref.invalidate(recentLogsProvider);
          ref.invalidate(permissionStatusProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PermissionBanner(),
            const SizedBox(height: 16),
            _buildStorageCard(storageAsync),
            const SizedBox(height: 16),
            _buildQuickActions(enabledRulesAsync, scanState),
            const SizedBox(height: 16),
            _buildEnabledRulesCard(enabledRulesAsync),
            const SizedBox(height: 16),
            _buildRecentLogsCard(recentLogsAsync),
            const SizedBox(height: 8),
            romTypeAsync.when(
              data: (rom) => Text(
                '检测到系统: $rom',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(AsyncValue<Map<String, dynamic>> storageAsync) {
    return storageAsync.when(
      data: (info) {
        final total = info['totalBytes'] as int? ?? 1;
        final used = info['usedBytes'] as int? ?? 0;
        final free = info['freeBytes'] as int? ?? 0;
        final percent = total > 0 ? used / total : 0.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StorageRing(percent: percent, size: 120),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStorageStat('已用', formatBytes(used), Colors.orange),
                    const SizedBox(width: 32),
                    _buildStorageStat('可用', formatBytes(free), Colors.green),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '总计: ${formatBytes(total)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('无法获取存储信息: $e'),
        ),
      ),
    );
  }

  Widget _buildStorageStat(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActions(
    AsyncValue<List<CleanRuleEntity>> rulesAsync,
    ScanState scanState,
  ) {
    final isScanning = scanState.isScanning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('快捷操作', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isScanning
                        ? null
                        : () async {
                            final rules = await ref.read(enabledRulesProvider.future);
                            if (rules.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('没有启用的规则，请先启用规则')),
                                );
                              }
                              return;
                            }
                            await ref.read(scanProvider.notifier).scanWithRules(rules);
                            final files = ref.read(scanProvider).files;
                            if (mounted) {
                              if (files.isNotEmpty) {
                                context.push('/preview');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('没有匹配到可清理的文件')),
                                );
                              }
                            }
                          },
                    icon: isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cleaning_services),
                    label: Text(isScanning ? '扫描中...' : '一键扫描'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/rules'),
                    icon: const Icon(Icons.rule_folder_outlined),
                    label: const Text('规则管理'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/auto_tasks'),
                    icon: const Icon(Icons.schedule_outlined),
                    label: const Text('自动清理'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/large_files'),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('大文件'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledRulesCard(AsyncValue<List<CleanRuleEntity>> rulesAsync) {
    return rulesAsync.when(
      data: (rules) {
        if (rules.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('已启用规则', style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => context.push('/rules'),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...rules.take(3).map((CleanRuleEntity rule) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  title: Text(rule.name, style: const TextStyle(fontSize: 14)),
                  subtitle: rule.description != null
                      ? Text(rule.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                      : null,
                )),
                if (rules.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '还有 ${rules.length - 3} 条规则...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentLogsCard(AsyncValue<List<CleanLogEntity>> logsAsync) {
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最近清理', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...logs.take(3).map((CleanLogEntity log) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      log.taskType == 'auto' ? Icons.schedule : Icons.touch_app,
                      size: 20,
                    ),
                    title: Text(
                      '${formatBytes(log.results.freedBytes)} · ${log.results.fileCount} 个文件',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      _formatTime(log.executedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }
}
