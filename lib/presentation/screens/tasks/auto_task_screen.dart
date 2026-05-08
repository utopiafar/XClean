import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xclean/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(autoTasksProvider);
    final rulesAsync = ref.watch(allRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.autoTaskTitle),
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
                  Text(l10n.noAutoTasks),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showTaskEditor(context, ref, null, rulesAsync.valueOrNull ?? []),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newTask),
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
                  subtitle: Text(l10n.periodLabel(_periodLabel(task.schedule.period, l10n), task.schedule.timeOfDay)),
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
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.loadFailed('$e'))),
      ),
    );
  }

  String _periodLabel(String period, AppLocalizations l10n) {
    return switch (period) {
      'daily' => l10n.daily,
      '3days' => l10n.every3Days,
      'weekly' => l10n.weekly,
      'monthly' => l10n.monthly,
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(widget.task == null ? l10n.newAutoTask : l10n.editAutoTask,
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
            decoration: InputDecoration(labelText: l10n.taskName),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _period,
            decoration: InputDecoration(labelText: l10n.executionPeriod),
            items: [
              DropdownMenuItem(value: 'daily', child: Text(l10n.daily)),
              DropdownMenuItem(value: '3days', child: Text(l10n.every3Days)),
              DropdownMenuItem(value: 'weekly', child: Text(l10n.weekly)),
              DropdownMenuItem(value: 'monthly', child: Text(l10n.monthly)),
            ],
            onChanged: (v) => setState(() => _period = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(l10n.executionTime),
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
          Text(l10n.selectRules, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            title: Text(l10n.requirePreviewConfirm),
            subtitle: Text(l10n.previewConfirmDesc),
            value: _requirePreview,
            onChanged: (v) => setState(() => _requirePreview = v),
          ),
          SwitchListTile(
            title: Text(l10n.useForegroundService),
            subtitle: Text(l10n.foregroundServiceDesc),
            value: _useForeground,
            onChanged: (v) => setState(() => _useForeground = v),
          ),
          SwitchListTile(
            title: Text(l10n.onlyWhenCharging),
            value: _requireCharging,
            onChanged: (v) => setState(() => _requireCharging = v),
          ),
          ListTile(
            title: Text(l10n.minBatteryLevel),
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
              child: Text(l10n.saveTask),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskNameRequired)),
      );
      return;
    }
    if (_selectedRuleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectRulesRequired)),
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
        SnackBar(content: Text(l10n.taskSaved)),
      );
    }
  }
}
