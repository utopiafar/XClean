import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/clean_rule.dart';
import '../../providers/dashboard_provider.dart';
import 'directory_picker_dialog.dart';

class RuleEditorScreen extends ConsumerStatefulWidget {
  final int? ruleId;
  const RuleEditorScreen({super.key, this.ruleId});

  @override
  ConsumerState<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends ConsumerState<RuleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _pathControllers = <TextEditingController>[];
  final _excludedPathControllers = <TextEditingController>[];

  bool _enabled = true;
  int _priority = 100;
  bool _recursive = true;
  String _engine = 'normal';
  String _actionType = 'delete';
  int _shredPasses = 3;
  bool _requirePreview = true;
  int _minMatchCount = 1;

  final List<_MatchConditionForm> _conditions = [];

  @override
  void initState() {
    super.initState();
    _loadRule();
  }

  void _loadRule() {
    final ruleId = widget.ruleId;
    if (ruleId == null) {
      _pathControllers.add(TextEditingController(text: '/storage/emulated/0/'));
      return;
    }

    final rules = ref.read(allRulesProvider).valueOrNull ?? [];
    final rule = rules.firstWhere((r) => r.id == ruleId);

    _nameController.text = rule.name;
    _descController.text = rule.description ?? '';
    _enabled = rule.enabled;
    _priority = rule.priority;
    _recursive = rule.scope.recursive;
    _engine = rule.scope.engine;
    _actionType = rule.action.type;
    _shredPasses = rule.action.shredPasses;
    _requirePreview = rule.safety.requirePreview;
    _minMatchCount = rule.safety.minMatchCount;

    for (final path in rule.scope.paths) {
      _pathControllers.add(TextEditingController(text: path));
    }
    for (final path in rule.safety.excludedPaths) {
      _excludedPathControllers.add(TextEditingController(text: path));
    }

    for (final c in rule.matchConditions) {
      c.map(
        filename: (v) => _conditions.add(_MatchConditionForm(
          type: 'filename', pattern: v.pattern, mode: v.mode,
        )),
        extension: (v) => _conditions.add(_MatchConditionForm(
          type: 'extension', extensions: v.values.join(','),
        )),
        size: (v) => _conditions.add(_MatchConditionForm(
          type: 'size', operator: v.operator, sizeValue: v.value.toString(),
        )),
        modifiedTime: (v) => _conditions.add(_MatchConditionForm(
          type: 'modifiedTime', operator: v.operator, timeValue: v.value,
        )),
        subfileCount: (v) => _conditions.add(_MatchConditionForm(
          type: 'subfileCount', operator: v.operator, countValue: v.value.toString(),
        )),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _pathControllers) { c.dispose(); }
    for (final c in _excludedPathControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruleId == null ? '新建规则' : '编辑规则'),
        actions: [
          TextButton(
            onPressed: _saveRule,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('基本信息', [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '规则名称', hintText: '例如：清理日志文件'),
                validator: (v) => v == null || v.isEmpty ? '请输入名称' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: '描述（可选）'),
              ),
              SwitchListTile(
                title: const Text('启用此规则'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              ListTile(
                title: const Text('优先级'),
                subtitle: Text('$_priority（数字越小优先级越高）'),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: _priority.toDouble(),
                    min: 1,
                    max: 200,
                    divisions: 199,
                    label: '$_priority',
                    onChanged: (v) => setState(() => _priority = v.toInt()),
                  ),
                ),
              ),
            ]),
            _buildSection('作用范围', [
              ..._pathControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '路径 ${index + 1}',
                          hintText: '/storage/emulated/0/...',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open_outlined),
                            tooltip: '浏览目录',
                            onPressed: () async {
                              final path = await DirectoryPickerDialog.show(
                                context,
                                initialPath: controller.text.isNotEmpty
                                    ? controller.text
                                    : '/storage/emulated/0',
                              );
                              if (path != null) {
                                controller.text = path;
                              }
                            },
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? '请输入路径' : null,
                      ),
                    ),
                    if (_pathControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() {
                          controller.dispose();
                          _pathControllers.removeAt(index);
                        }),
                      ),
                  ],
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _pathControllers.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('添加路径'),
              ),
              SwitchListTile(
                title: const Text('递归子目录'),
                value: _recursive,
                onChanged: (v) => setState(() => _recursive = v),
              ),
              ListTile(
                title: const Text('权限引擎'),
                subtitle: Text(_engineLabel(_engine)),
                trailing: DropdownButton<String>(
                  value: _engine,
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('普通权限')),
                    DropdownMenuItem(value: 'shizuku', child: Text('Shizuku')),
                    DropdownMenuItem(value: 'root', child: Text('Root')),
                  ],
                  onChanged: (v) => setState(() => _engine = v!),
                ),
              ),
            ]),
            _buildSection('匹配条件', [
              if (_conditions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('未添加条件（将匹配所有文件）', style: TextStyle(color: Colors.grey)),
                ),
              ..._conditions.asMap().entries.map((entry) {
                final index = entry.key;
                final condition = entry.value;
                return _buildConditionCard(index, condition);
              }),
              const SizedBox(height: 8),
              _buildAddConditionMenu(),
            ]),
            _buildSection('执行动作', [
              ListTile(
                title: const Text('动作类型'),
                trailing: DropdownButton<String>(
                  value: _actionType,
                  items: const [
                    DropdownMenuItem(value: 'delete', child: Text('删除')),
                    DropdownMenuItem(value: 'shred', child: Text('粉碎删除')),
                  ],
                  onChanged: (v) => setState(() => _actionType = v!),
                ),
              ),
              if (_actionType == 'shred')
                ListTile(
                  title: const Text('覆写次数'),
                  trailing: DropdownButton<int>(
                    value: _shredPasses,
                    items: [1, 3, 5, 7].map((n) => DropdownMenuItem(value: n, child: Text('$n 次'))).toList(),
                    onChanged: (v) => setState(() => _shredPasses = v!),
                  ),
                ),
            ]),
            _buildSection('安全策略', [
              SwitchListTile(
                title: const Text('首次执行要求预览'),
                value: _requirePreview,
                onChanged: (v) => setState(() => _requirePreview = v),
              ),
              ListTile(
                title: const Text('最少匹配数量'),
                trailing: SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '$_minMatchCount',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) => _minMatchCount = int.tryParse(v) ?? 1,
                  ),
                ),
              ),
              ..._excludedPathControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '排除路径 ${index + 1}',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open_outlined),
                            tooltip: '浏览目录',
                            onPressed: () async {
                              final path = await DirectoryPickerDialog.show(
                                context,
                                initialPath: controller.text.isNotEmpty
                                    ? controller.text
                                    : '/storage/emulated/0',
                              );
                              if (path != null) {
                                controller.text = path;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() {
                        controller.dispose();
                        _excludedPathControllers.removeAt(index);
                      }),
                    ),
                  ],
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _excludedPathControllers.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('添加排除路径'),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(int index, _MatchConditionForm condition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('条件 ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() => _conditions.removeAt(index)),
                ),
              ],
            ),
            if (condition.type == 'filename') ...[
              TextFormField(
                initialValue: condition.pattern,
                decoration: const InputDecoration(labelText: '文件名模式', hintText: '*.log'),
                onChanged: (v) => condition.pattern = v,
              ),
              DropdownButtonFormField<String>(
                value: condition.mode ?? 'wildcard',
                decoration: const InputDecoration(labelText: '匹配模式'),
                items: const [
                  DropdownMenuItem(value: 'wildcard', child: Text('通配符 (*, ?)')),
                  DropdownMenuItem(value: 'regex', child: Text('正则表达式')),
                  DropdownMenuItem(value: 'contains', child: Text('包含文本')),
                  DropdownMenuItem(value: 'exact', child: Text('精确匹配')),
                ],
                onChanged: (v) => setState(() => condition.mode = v),
              ),
            ],
            if (condition.type == 'extension') ...[
              TextFormField(
                initialValue: condition.extensions,
                decoration: const InputDecoration(labelText: '扩展名（逗号分隔）', hintText: 'log, tmp, txt'),
                onChanged: (v) => condition.extensions = v,
              ),
            ],
            if (condition.type == 'size') ...[
              DropdownButtonFormField<String>(
                value: condition.operator ?? '>',
                decoration: const InputDecoration(labelText: '比较方式'),
                items: const [
                  DropdownMenuItem(value: '>', child: Text('大于')),
                  DropdownMenuItem(value: '>=', child: Text('大于等于')),
                  DropdownMenuItem(value: '<', child: Text('小于')),
                  DropdownMenuItem(value: '<=', child: Text('小于等于')),
                  DropdownMenuItem(value: '==', child: Text('等于')),
                ],
                onChanged: (v) => setState(() => condition.operator = v),
              ),
              TextFormField(
                initialValue: condition.sizeValue,
                decoration: const InputDecoration(labelText: '大小（字节）'),
                keyboardType: TextInputType.number,
                onChanged: (v) => condition.sizeValue = v,
              ),
            ],
            if (condition.type == 'modifiedTime') ...[
              DropdownButtonFormField<String>(
                value: condition.operator ?? '>',
                decoration: const InputDecoration(labelText: '比较方式'),
                items: const [
                  DropdownMenuItem(value: '>', child: Text('早于')),
                  DropdownMenuItem(value: '<', child: Text('晚于')),
                ],
                onChanged: (v) => setState(() => condition.operator = v),
              ),
              TextFormField(
                initialValue: condition.timeValue,
                decoration: const InputDecoration(labelText: '时间（如 7d, 24h, 30m）'),
                onChanged: (v) => condition.timeValue = v,
              ),
            ],
            if (condition.type == 'subfileCount') ...[
              DropdownButtonFormField<String>(
                value: condition.operator ?? '==',
                decoration: const InputDecoration(labelText: '比较方式'),
                items: const [
                  DropdownMenuItem(value: '==', child: Text('等于')),
                  DropdownMenuItem(value: '>', child: Text('大于')),
                  DropdownMenuItem(value: '<', child: Text('小于')),
                ],
                onChanged: (v) => setState(() => condition.operator = v),
              ),
              TextFormField(
                initialValue: condition.countValue,
                decoration: const InputDecoration(labelText: '子文件数量'),
                keyboardType: TextInputType.number,
                onChanged: (v) => condition.countValue = v,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddConditionMenu() {
    return PopupMenuButton<String>(
      onSelected: (type) => setState(() => _conditions.add(_MatchConditionForm(type: type))),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'filename', child: Text('文件名')),
        PopupMenuItem(value: 'extension', child: Text('扩展名')),
        PopupMenuItem(value: 'size', child: Text('文件大小')),
        PopupMenuItem(value: 'modifiedTime', child: Text('修改时间')),
        PopupMenuItem(value: 'subfileCount', child: Text('子文件数量')),
      ],
      child: const Chip(
        avatar: Icon(Icons.add, size: 18),
        label: Text('添加条件'),
      ),
    );
  }

  String _engineLabel(String engine) {
    return switch (engine) {
      'normal' => '普通权限',
      'shizuku' => 'Shizuku',
      'root' => 'Root',
      _ => '普通权限',
    };
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pathControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个路径')),
      );
      return;
    }

    final paths = _pathControllers.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();
    final excludedPaths = _excludedPathControllers.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();

    final matchConditions = _conditions.map((c) {
      return switch (c.type) {
        'filename' => MatchCondition.filename(pattern: c.pattern ?? '*', mode: c.mode ?? 'wildcard'),
        'extension' => MatchCondition.extension(
          values: c.extensions?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [],
        ),
        'size' => MatchCondition.size(
          operator: c.operator ?? '>',
          value: int.tryParse(c.sizeValue ?? '0') ?? 0,
        ),
        'modifiedTime' => MatchCondition.modifiedTime(
          operator: c.operator ?? '>',
          value: c.timeValue ?? '7d',
        ),
        'subfileCount' => MatchCondition.subfileCount(
          operator: c.operator ?? '==',
          value: int.tryParse(c.countValue ?? '0') ?? 0,
        ),
        _ => MatchCondition.filename(pattern: '*'),
      };
    }).toList();

    final rule = CleanRuleEntity(
      id: widget.ruleId ?? 0,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      enabled: _enabled,
      priority: _priority,
      scope: RuleScope(paths: paths, recursive: _recursive, engine: _engine),
      matchConditions: matchConditions,
      action: RuleAction(type: _actionType, shredPasses: _shredPasses),
      safety: RuleSafety(
        requirePreview: _requirePreview,
        minMatchCount: _minMatchCount,
        excludedPaths: excludedPaths,
      ),
    );

    final repo = ref.read(ruleRepositoryProvider);
    if (widget.ruleId == null) {
      await repo.insertRule(rule);
    } else {
      await repo.updateRule(rule);
    }

    ref.invalidate(allRulesProvider);
    ref.invalidate(enabledRulesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('规则已保存')),
      );
      context.pop();
    }
  }
}

class _MatchConditionForm {
  String type;
  String? pattern;
  String? mode;
  String? extensions;
  String? operator;
  String? sizeValue;
  String? timeValue;
  String? countValue;

  _MatchConditionForm({required this.type, this.pattern, this.mode, this.extensions, this.operator, this.sizeValue, this.timeValue, this.countValue});
}
