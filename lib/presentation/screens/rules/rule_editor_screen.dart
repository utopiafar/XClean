import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xclean/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruleId == null ? l10n.newRuleTitle : l10n.editRuleTitle),
        actions: [
          TextButton(
            onPressed: _saveRule,
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(l10n.basicInfo, [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.ruleName, hintText: l10n.ruleNameHint),
                validator: (v) => v == null || v.isEmpty ? l10n.nameRequired : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              SwitchListTile(
                title: Text(l10n.enableThisRule),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              ListTile(
                title: Text(l10n.priority),
                subtitle: Text(l10n.priorityDesc(_priority)),
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
            _buildSection(l10n.scope, [
              ..._pathControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: l10n.pathLabel(index + 1),
                          hintText: l10n.pathHint,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open_outlined),
                            tooltip: l10n.browseDirectory,
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
                        validator: (v) => v == null || v.isEmpty ? l10n.pathRequired : null,
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
                label: Text(l10n.addPath),
              ),
              SwitchListTile(
                title: Text(l10n.recursiveSubdirs),
                value: _recursive,
                onChanged: (v) => setState(() => _recursive = v),
              ),
              ListTile(
                title: Text(l10n.permissionEngine),
                subtitle: Text(_engineLabel(_engine, l10n)),
                trailing: DropdownButton<String>(
                  value: _engine,
                  items: [
                    DropdownMenuItem(value: 'normal', child: Text(l10n.normalPermission)),
                    const DropdownMenuItem(value: 'shizuku', child: Text('Shizuku')),
                    const DropdownMenuItem(value: 'root', child: Text('Root')),
                  ],
                  onChanged: (v) => setState(() => _engine = v!),
                ),
              ),
            ]),
            _buildSection(l10n.matchConditions, [
              if (_conditions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l10n.noConditions, style: const TextStyle(color: Colors.grey)),
                ),
              ..._conditions.asMap().entries.map((entry) {
                final index = entry.key;
                final condition = entry.value;
                return _buildConditionCard(index, condition, l10n);
              }),
              const SizedBox(height: 8),
              _buildAddConditionMenu(l10n),
            ]),
            _buildSection(l10n.actionType, [
              ListTile(
                title: Text(l10n.actionType),
                trailing: DropdownButton<String>(
                  value: _actionType,
                  items: [
                    DropdownMenuItem(value: 'delete', child: Text(l10n.deleteAction)),
                    DropdownMenuItem(value: 'shred', child: Text(l10n.shredAction)),
                  ],
                  onChanged: (v) => setState(() => _actionType = v!),
                ),
              ),
              if (_actionType == 'shred')
                ListTile(
                  title: Text(l10n.passesCount),
                  trailing: DropdownButton<int>(
                    value: _shredPasses,
                    items: [1, 3, 5, 7].map((n) => DropdownMenuItem(value: n, child: Text(l10n.passesCountLabel(n)))).toList(),
                    onChanged: (v) => setState(() => _shredPasses = v!),
                  ),
                ),
            ]),
            _buildSection(l10n.safetyPolicy, [
              SwitchListTile(
                title: Text(l10n.requirePreview),
                value: _requirePreview,
                onChanged: (v) => setState(() => _requirePreview = v),
              ),
              ListTile(
                title: Text(l10n.minMatchCount),
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
                          labelText: l10n.excludedPathLabel(index + 1),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open_outlined),
                            tooltip: l10n.browseDirectory,
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
                label: Text(l10n.addExcludedPath),
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

  Widget _buildConditionCard(int index, _MatchConditionForm condition, AppLocalizations l10n) {
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
                Text(l10n.conditionLabel(index + 1), style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() => _conditions.removeAt(index)),
                ),
              ],
            ),
            if (condition.type == 'filename') ...[
              TextFormField(
                initialValue: condition.pattern,
                decoration: InputDecoration(labelText: l10n.filenamePattern, hintText: l10n.filenamePatternHint),
                onChanged: (v) => condition.pattern = v,
              ),
              DropdownButtonFormField<String>(
                value: condition.mode ?? 'wildcard',
                decoration: InputDecoration(labelText: l10n.matchMode),
                items: [
                  DropdownMenuItem(value: 'wildcard', child: Text(l10n.wildcardMode)),
                  DropdownMenuItem(value: 'regex', child: Text(l10n.regexMode)),
                  DropdownMenuItem(value: 'contains', child: Text(l10n.containsMode)),
                  DropdownMenuItem(value: 'exact', child: Text(l10n.exactMode)),
                ],
                onChanged: (v) => setState(() => condition.mode = v),
              ),
            ],
            if (condition.type == 'extension') ...[
              TextFormField(
                initialValue: condition.extensions,
                decoration: InputDecoration(labelText: l10n.extensionsLabel, hintText: l10n.extensionsHint),
                onChanged: (v) => condition.extensions = v,
              ),
            ],
            if (condition.type == 'size') ...[
              DropdownButtonFormField<String>(
                value: condition.operator ?? '>',
                decoration: InputDecoration(labelText: l10n.compareMethod),
                items: [
                  DropdownMenuItem(value: '>', child: Text(l10n.greaterThan)),
                  DropdownMenuItem(value: '>=', child: Text(l10n.greaterThanOrEqual)),
                  DropdownMenuItem(value: '<', child: Text(l10n.lessThan)),
                  DropdownMenuItem(value: '<=', child: Text(l10n.lessThanOrEqual)),
                  DropdownMenuItem(value: '==', child: Text(l10n.equal)),
                ],
                onChanged: (v) => setState(() => condition.operator = v),
              ),
              TextFormField(
                initialValue: condition.sizeValue,
                decoration: InputDecoration(labelText: l10n.sizeInBytes),
                keyboardType: TextInputType.number,
                onChanged: (v) => condition.sizeValue = v,
              ),
            ],
            if (condition.type == 'modifiedTime') ...[
              DropdownButtonFormField<String>(
                value: condition.operator ?? '>',
                decoration: InputDecoration(labelText: l10n.compareMethod),
                items: [
                  DropdownMenuItem(value: '>', child: Text(l10n.olderThan)),
                  DropdownMenuItem(value: '<', child: Text(l10n.newerThan)),
                ],
                onChanged: (v) => setState(() => condition.operator = v),
              ),
              TextFormField(
                initialValue: condition.timeValue,
                decoration: InputDecoration(labelText: l10n.timeFormatHint),
                onChanged: (v) => condition.timeValue = v,
              ),
            ],
            if (condition.type == 'subfileCount') ...[
              DropdownButtonFormField<String>(
                value: condition.operator ?? '==',
                decoration: InputDecoration(labelText: l10n.compareMethod),
                items: [
                  DropdownMenuItem(value: '==', child: Text(l10n.equal)),
                  DropdownMenuItem(value: '>', child: Text(l10n.greaterThan)),
                  DropdownMenuItem(value: '<', child: Text(l10n.lessThan)),
                ],
                onChanged: (v) => setState(() => condition.operator = v),
              ),
              TextFormField(
                initialValue: condition.countValue,
                decoration: InputDecoration(labelText: l10n.subfileCountLabel),
                keyboardType: TextInputType.number,
                onChanged: (v) => condition.countValue = v,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddConditionMenu(AppLocalizations l10n) {
    return PopupMenuButton<String>(
      onSelected: (type) => setState(() => _conditions.add(_MatchConditionForm(type: type))),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'filename', child: Text(l10n.filenameCondition)),
        PopupMenuItem(value: 'extension', child: Text(l10n.extensionCondition)),
        PopupMenuItem(value: 'size', child: Text(l10n.fileSizeCondition)),
        PopupMenuItem(value: 'modifiedTime', child: Text(l10n.modifiedTimeCondition)),
        PopupMenuItem(value: 'subfileCount', child: Text(l10n.subfileCountCondition)),
      ],
      child: Chip(
        avatar: const Icon(Icons.add, size: 18),
        label: Text(l10n.addCondition),
      ),
    );
  }

  String _engineLabel(String engine, AppLocalizations l10n) {
    return switch (engine) {
      'normal' => l10n.normalPermission,
      'shizuku' => 'Shizuku',
      'root' => 'Root',
      _ => l10n.normalPermission,
    };
  }

  Future<void> _saveRule() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_pathControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseAddAtLeastOnePath)),
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
        SnackBar(content: Text(l10n.ruleSaved)),
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
