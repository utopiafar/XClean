import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/clean_rule.dart';
import '../../providers/dashboard_provider.dart';
import 'rule_editor_screen.dart';

class RuleListScreen extends ConsumerWidget {
  const RuleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(allRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('清理规则'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建规则',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const RuleEditorScreen(),
              ));
            },
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('暂无规则'));
          }

          final presetRules = rules.where((r) => r.id <= 5 && r.id > 0).toList();
          final customRules = rules.where((r) => r.id > 5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (presetRules.isNotEmpty) ...[
                _buildSectionHeader(context, '预设规则'),
                ...presetRules.map((CleanRuleEntity rule) => _RuleCard(rule: rule)),
              ],
              if (customRules.isNotEmpty) ...[
                _buildSectionHeader(context, '自定义规则'),
                ...customRules.map((CleanRuleEntity rule) => _RuleCard(rule: rule)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RuleCard extends ConsumerWidget {
  final CleanRuleEntity rule;

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engineLabel = switch (rule.scope.engine) {
      'normal' => '普通权限',
      'shizuku' => 'Shizuku',
      'root' => 'Root',
      _ => '自动',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Switch(
          value: rule.enabled,
          onChanged: (value) async {
            final updated = rule.copyWith(enabled: value);
            await ref.read(ruleRepositoryProvider).updateRule(updated);
            ref.invalidate(allRulesProvider);
            ref.invalidate(enabledRulesProvider);
          },
        ),
        title: Text(rule.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rule.description != null)
              Text(
                rule.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            Row(
              children: [
                Chip(
                  label: Text(engineLabel, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _engineColor(rule.scope.engine).withAlpha(40),
                  side: BorderSide.none,
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text('优先级 ${rule.priority}', style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.grey.withAlpha(40),
                  side: BorderSide.none,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '编辑规则',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RuleEditorScreen(ruleId: rule.id),
            ));
          },
        ),
      ),
    );
  }

  Color _engineColor(String engine) {
    return switch (engine) {
      'normal' => Colors.blue,
      'shizuku' => Colors.purple,
      'root' => Colors.red,
      _ => Colors.green,
    };
  }
}
