import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/local/database.dart';
import '../../../domain/entities/auto_task.dart';
import '../../../domain/entities/clean_rule.dart';
import '../../providers/dashboard_provider.dart';

final autoTasksProvider = FutureProvider<List<AutoTaskEntity>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.autoTasks).get();
  return rows.map((r) => AutoTaskEntity(
    id: r.id,
    name: r.name,
    ruleIds: [],
    schedule: const TaskSchedule(),
    requirePreview: r.requirePreview,
    useForegroundService: r.useForegroundService,
    enabled: r.enabled,
  )).toList();
});

class AutoTaskScreen extends ConsumerWidget {
  const AutoTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(autoTasksProvider);
    final rulesAsync = ref.watch(allRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动清理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showTaskEditor(context, ref, null, rulesAsync.valueOrNull ?? []);
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('没有配置自动清理任务'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showTaskEditor(context, ref, null, rulesAsync.valueOrNull ?? []),
                    icon: const Icon(Icons.add),
                    label: const Text('新建任务'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final task = tasks[index];
              return Card(
                child: ListTile(
                  leading: Switch(
                    value: task.enabled,
                    onChanged: (v) async {
                      final db = ref.read(databaseProvider);
                      await db.update(db.autoTasks).replace(
                        AutoTasksCompanion(
                          id: drift.Value(task.id),
                          enabled: drift.Value(v),
                        ),
                      );
                      ref.invalidate(autoTasksProvider);
                    },
                  ),
                  title: Text(task.name),
                  subtitle: Text('周期: ${_periodLabel(task.schedule.period)} · ${task.schedule.timeOfDay}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.useForegroundService)
                        const Icon(Icons.notifications_active, size: 18, color: Colors.blue),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showTaskEditor(context, ref, task, rulesAsync.valueOrNull ?? []),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  String _periodLabel(String period) {
    return switch (period) {
      'daily' => '每天',
      '3days' => '每3天',
      'weekly' => '每周',
      'monthly' => '每月',
      _ => period,
    };
  }

  void _showTaskEditor(BuildContext context, WidgetRef ref, AutoTaskEntity? task, List<CleanRuleEntity> rules) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskEditorSheet(task: task, rules: rules),
    );
  }
}

class _TaskEditorSheet extends ConsumerStatefulWidget {
  final AutoTaskEntity? task;
  final List<CleanRuleEntity> rules;

  const _TaskEditorSheet({this.task, required this.rules});

  @override
  ConsumerState<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<_TaskEditorSheet> {
  final _nameController = TextEditingController();
  String _period = 'daily';
  String _timeOfDay = '02:00';
  final Set<int> _selectedRuleIds = {};
  bool _requirePreview = false;
  bool _useForeground = false;
  bool _requireCharging = true;
  int _minBattery = 20;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _nameController.text = task.name;
      _period = task.schedule.period;
      _timeOfDay = task.schedule.timeOfDay;
      _selectedRuleIds.addAll(task.ruleIds);
      _requirePreview = task.requirePreview;
      _useForeground = task.useForegroundService;
      if (task.conditions != null) {
        _requireCharging = task.conditions!.requireCharging;
        _minBattery = task.conditions!.minBatteryPercent;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.task == null ? '新建自动任务' : '编辑自动任务',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '任务名称'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _period,
            decoration: const InputDecoration(labelText: '执行周期'),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('每天')),
              DropdownMenuItem(value: '3days', child: Text('每3天')),
              DropdownMenuItem(value: 'weekly', child: Text('每周')),
              DropdownMenuItem(value: 'monthly', child: Text('每月')),
            ],
            onChanged: (v) => setState(() => _period = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('执行时间'),
            trailing: Text(_timeOfDay, style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final parts = _timeOfDay.split(':');
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                ),
              );
              if (time != null) {
                setState(() => _timeOfDay = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
              }
            },
          ),
          const SizedBox(height: 12),
          const Text('选择规则', style: TextStyle(fontWeight: FontWeight.bold)),
          ...widget.rules.where((r) => r.enabled).map((rule) => CheckboxListTile(
            dense: true,
            title: Text(rule.name),
            value: _selectedRuleIds.contains(rule.id),
            onChanged: (v) => setState(() {
              if (v == true) {
                _selectedRuleIds.add(rule.id);
              } else {
                _selectedRuleIds.remove(rule.id);
              }
            }),
          )),
          const Divider(),
          SwitchListTile(
            title: const Text('要求预览确认'),
            subtitle: const Text('每次执行前通知并等待确认'),
            value: _requirePreview,
            onChanged: (v) => setState(() => _requirePreview = v),
          ),
          SwitchListTile(
            title: const Text('使用前台服务保活'),
            subtitle: const Text('提升国产 ROM 上的执行可靠性'),
            value: _useForeground,
            onChanged: (v) => setState(() => _useForeground = v),
          ),
          SwitchListTile(
            title: const Text('仅充电时执行'),
            value: _requireCharging,
            onChanged: (v) => setState(() => _requireCharging = v),
          ),
          ListTile(
            title: const Text('最低电量'),
            trailing: SizedBox(
              width: 120,
              child: Slider(
                value: _minBattery.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                label: '$_minBattery%',
                onChanged: (v) => setState(() => _minBattery = v.toInt()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveTask,
              child: const Text('保存任务'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务名称')),
      );
      return;
    }
    if (_selectedRuleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一条规则')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final task = widget.task;

    final companion = AutoTasksCompanion(
      id: task == null ? const drift.Value.absent() : drift.Value(task.id),
      name: drift.Value(_nameController.text.trim()),
      ruleIdsJson: drift.Value('[]'),
      scheduleJson: drift.Value('{}'),
      conditionsJson: drift.Value('{}'),
      requirePreview: drift.Value(_requirePreview),
      useForegroundService: drift.Value(_useForeground),
      enabled: const drift.Value(true),
    );

    if (task == null) {
      await db.into(db.autoTasks).insert(companion);
    } else {
      await db.update(db.autoTasks).replace(companion);
    }

    ref.invalidate(autoTasksProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自动任务已保存')),
      );
    }
  }
}
