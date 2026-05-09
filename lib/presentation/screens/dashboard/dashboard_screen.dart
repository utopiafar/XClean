import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xclean/l10n/app_localizations.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../core/utils/size_formatter.dart';
import '../../../domain/entities/clean_log.dart';
import '../../../domain/entities/clean_rule.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/permission_banner.dart';
import '../../widgets/storage_ring.dart';
import '../logs/log_detail_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final storageAsync = ref.watch(storageInfoProvider);
    final enabledRulesAsync = ref.watch(enabledRulesProvider);
    final recentLogsAsync = ref.watch(recentLogsProvider);
    final romTypeAsync = ref.watch(romTypeProvider);
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
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
            _buildStorageCard(storageAsync, l10n),
            const SizedBox(height: 16),
            _buildQuickActions(enabledRulesAsync, scanState, l10n),
            const SizedBox(height: 16),
            _buildEnabledRulesCard(enabledRulesAsync, l10n),
            const SizedBox(height: 16),
            _buildRecentLogsCard(recentLogsAsync, l10n),
            const SizedBox(height: 8),
            romTypeAsync.when(
              data: (rom) => Text(
                l10n.romDetected(rom),
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

  Widget _buildStorageCard(AsyncValue<Map<String, dynamic>> storageAsync, AppLocalizations l10n) {
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
                    _buildStorageStat(l10n.used, formatBytes(used), Colors.orange),
                    const SizedBox(width: 32),
                    _buildStorageStat(l10n.available, formatBytes(free), Colors.green),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.total}: ${formatBytes(total)}',
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
          child: Text(l10n.storageInfoError('$e')),
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
    AppLocalizations l10n,
  ) {
    final isScanning = scanState.isScanning;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.quickActions, style: Theme.of(context).textTheme.titleMedium),
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
                                  SnackBar(content: Text(l10n.noEnabledRules)),
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
                                  SnackBar(content: Text(l10n.noMatchedFiles)),
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
                    label: Text(isScanning ? l10n.scanning : l10n.oneKeyScan),
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
                    label: Text(l10n.ruleManagement),
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
                    label: Text(l10n.autoClean),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/large_files'),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(l10n.largeFiles),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledRulesCard(AsyncValue<List<CleanRuleEntity>> rulesAsync, AppLocalizations l10n) {
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
                    Text(l10n.enabledRules, style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => context.push('/rules'),
                      child: Text(l10n.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...rules.take(3).map((CleanRuleEntity rule) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  title: Text(localizePresetName(context, rule.name), style: const TextStyle(fontSize: 14)),
                  subtitle: rule.description != null
                      ? Text(localizePresetDesc(context, rule.description!), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                      : null,
                )),
                if (rules.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.moreRules(rules.length - 3),
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

  Widget _buildRecentLogsCard(AsyncValue<List<CleanLogEntity>> logsAsync, AppLocalizations l10n) {
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
                Text(l10n.recentCleanups, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...logs.take(3).map((CleanLogEntity log) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      log.taskType == 'auto' ? Icons.schedule : Icons.touch_app,
                      size: 20,
                    ),
                    title: Text(
                      '${formatBytes(log.results.freedBytes)} · ${l10n.nFiles(log.results.fileCount)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      _formatTime(log.executedAt, l10n),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LogDetailScreen(log: log),
                    )),
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

  String _formatTime(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${dt.month}/${dt.day}';
  }
}
