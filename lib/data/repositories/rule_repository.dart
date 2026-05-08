import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/entities/clean_rule.dart';
import '../local/database.dart';

class RuleRepository {
  final AppDatabase _db;

  RuleRepository(this._db);

  Future<List<CleanRuleEntity>> getAllRules() async {
    final rows = await _db.getAllRules();
    return rows.map(_mapRowToEntity).toList();
  }

  Future<List<CleanRuleEntity>> getEnabledRules() async {
    final rows = await _db.getEnabledRules();
    return rows.map(_mapRowToEntity).toList();
  }

  Future<int> insertRule(CleanRuleEntity rule) {
    return _db.insertRule(_mapEntityToCompanion(rule.copyWith(id: 0)));
  }

  Future<bool> updateRule(CleanRuleEntity rule) {
    return _db.updateRule(_mapEntityToCompanion(rule));
  }

  Future<int> deleteRule(int id) => _db.deleteRule(id);

  Future<void> initPresetRules() async {
    final existing = await _db.getAllRules();
    if (existing.isNotEmpty) return;

    final presets = [
      CleanRuleEntity(
        id: 0,
        name: '缩略图缓存',
        description: '清理 .thumbnails 目录中的图片缓存',
        enabled: true,
        priority: 10,
        scope: const RuleScope(
          paths: ['/storage/emulated/0/DCIM/.thumbnails'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: const [],
        action: const RuleAction(type: 'delete'),
        safety: const RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: '空文件夹',
        description: '递归清理空目录',
        enabled: true,
        priority: 20,
        scope: const RuleScope(
          paths: ['/storage/emulated/0'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: const [
          MatchCondition.subfileCount(operator: '==', value: 0),
        ],
        action: const RuleAction(type: 'delete'),
        safety: const RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: '下载临时文件',
        description: '清理下载目录中的临时文件',
        enabled: true,
        priority: 30,
        scope: const RuleScope(
          paths: ['/storage/emulated/0/Download'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: const [
          MatchCondition.extension(values: ['tmp', 'crdownload', 'part']),
        ],
        action: const RuleAction(type: 'delete'),
        safety: const RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: '日志文件',
        description: '清理应用日志文件',
        enabled: false,
        priority: 40,
        scope: const RuleScope(
          paths: ['/storage/emulated/0/Android/data'],
          recursive: true,
          engine: 'shizuku',
        ),
        matchConditions: const [
          MatchCondition.extension(values: ['log']),
        ],
        action: const RuleAction(type: 'delete'),
        safety: const RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: '应用残留',
        description: '清理已卸载应用的残留目录',
        enabled: false,
        priority: 50,
        scope: const RuleScope(
          paths: ['/storage/emulated/0/Android/data'],
          recursive: false,
          engine: 'shizuku',
        ),
        matchConditions: const [],
        action: const RuleAction(type: 'delete'),
        safety: const RuleSafety(requirePreview: true),
      ),
    ];

    for (final rule in presets) {
      await insertRule(rule);
    }
  }

  CleanRuleEntity _mapRowToEntity(CleanRule row) {
    return CleanRuleEntity(
      id: row.id,
      name: row.name,
      description: row.description,
      enabled: row.enabled,
      priority: row.priority,
      scope: RuleScope.fromJson(jsonDecode(row.scopeJson)),
      matchConditions: (jsonDecode(row.matchConditionsJson) as List)
          .map((e) => MatchCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      action: RuleAction.fromJson(jsonDecode(row.actionJson)),
      safety: RuleSafety.fromJson(jsonDecode(row.safetyJson)),
    );
  }

  CleanRulesCompanion _mapEntityToCompanion(CleanRuleEntity rule) {
    return CleanRulesCompanion(
      id: rule.id == 0 ? const Value.absent() : Value(rule.id),
      name: Value(rule.name),
      description: Value(rule.description),
      enabled: Value(rule.enabled),
      priority: Value(rule.priority),
      scopeJson: Value(jsonEncode(rule.scope.toJson())),
      matchConditionsJson: Value(jsonEncode(rule.matchConditions.map((e) => e.toJson()).toList())),
      actionJson: Value(jsonEncode(rule.action.toJson())),
      safetyJson: Value(jsonEncode(rule.safety.toJson())),
    );
  }
}
