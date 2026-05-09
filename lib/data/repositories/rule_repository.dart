import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/entities/clean_rule.dart';
import '../local/database.dart';

const Set<String> kPresetRuleNames = {
  'Thumbnail Cache',
  'Empty Folders',
  'Download Temp Files',
  'Log Files',
  'App Residual',
  'APK Installer Files',
};

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

    const presets = [
      CleanRuleEntity(
        id: 0,
        name: 'Thumbnail Cache',
        description: 'Clean image cache in .thumbnails directory',
        enabled: true,
        priority: 10,
        scope: RuleScope(
          paths: ['/storage/emulated/0/DCIM/.thumbnails'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: [],
        action: RuleAction(type: 'delete'),
        safety: RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: 'Empty Folders',
        description: 'Recursively clean empty directories',
        enabled: true,
        priority: 20,
        scope: RuleScope(
          paths: ['/storage/emulated/0'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: [
          MatchCondition.subfileCount(operator: '==', value: 0),
        ],
        action: RuleAction(type: 'delete'),
        safety: RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: 'APK Installer Files',
        description: 'Clean leftover APK installer packages in download directory',
        enabled: true,
        priority: 25,
        scope: RuleScope(
          paths: ['/storage/emulated/0/Download'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: [
          MatchCondition.extension(values: ['apk']),
        ],
        action: RuleAction(type: 'delete'),
        safety: RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: 'Download Temp Files',
        description: 'Clean temporary files in download directory',
        enabled: true,
        priority: 30,
        scope: RuleScope(
          paths: ['/storage/emulated/0/Download'],
          recursive: true,
          engine: 'normal',
        ),
        matchConditions: [
          MatchCondition.extension(values: ['tmp', 'crdownload', 'part']),
        ],
        action: RuleAction(type: 'delete'),
        safety: RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: 'Log Files',
        description: 'Clean application log files',
        enabled: false,
        priority: 40,
        scope: RuleScope(
          paths: ['/storage/emulated/0/Android/data'],
          recursive: true,
          engine: 'shizuku',
        ),
        matchConditions: [
          MatchCondition.extension(values: ['log']),
        ],
        action: RuleAction(type: 'delete'),
        safety: RuleSafety(requirePreview: true),
      ),
      CleanRuleEntity(
        id: 0,
        name: 'App Residual',
        description: 'Clean residual directories of uninstalled apps',
        enabled: false,
        priority: 50,
        scope: RuleScope(
          paths: ['/storage/emulated/0/Android/data'],
          recursive: false,
          engine: 'shizuku',
        ),
        matchConditions: [],
        action: RuleAction(type: 'delete'),
        safety: RuleSafety(requirePreview: true),
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
