import 'package:freezed_annotation/freezed_annotation.dart';

part 'clean_rule.freezed.dart';
part 'clean_rule.g.dart';

@freezed
sealed class CleanRuleEntity with _$CleanRuleEntity {
  const factory CleanRuleEntity({
    required int id,
    required String name,
    String? description,
    @Default(true) bool enabled,
    @Default(100) int priority,
    required RuleScope scope,
    @Default([]) List<MatchCondition> matchConditions,
    required RuleAction action,
    @Default(RuleSafety()) RuleSafety safety,
  }) = _CleanRuleEntity;

  factory CleanRuleEntity.fromJson(Map<String, dynamic> json) => _$CleanRuleEntityFromJson(json);
}

@freezed
sealed class RuleScope with _$RuleScope {
  const factory RuleScope({
    @Default([]) List<String> paths,
    @Default(true) bool recursive,
    @Default('auto') String engine,
  }) = _RuleScopeEntity;

  factory RuleScope.fromJson(Map<String, dynamic> json) => _$RuleScopeFromJson(json);
}

@freezed
sealed class MatchCondition with _$MatchCondition {
  const factory MatchCondition.filename({
    required String pattern,
    @Default('wildcard') String mode,
  }) = FilenameConditionEntity;

  const factory MatchCondition.extension({
    required List<String> values,
  }) = ExtensionConditionEntity;

  const factory MatchCondition.size({
    required String operator,
    required int value,
  }) = SizeConditionEntity;

  const factory MatchCondition.modifiedTime({
    required String operator,
    required String value,
  }) = ModifiedTimeConditionEntity;

  const factory MatchCondition.subfileCount({
    required String operator,
    required int value,
  }) = SubfileCountConditionEntity;

  factory MatchCondition.fromJson(Map<String, dynamic> json) =>
      _$MatchConditionFromJson(json);
}

@freezed
sealed class RuleAction with _$RuleAction {
  const factory RuleAction({
    @Default('delete') String type,
    String? targetDir,
    @Default(3) int shredPasses,
  }) = _RuleActionEntity;

  factory RuleAction.fromJson(Map<String, dynamic> json) => _$RuleActionFromJson(json);
}

@freezed
sealed class RuleSafety with _$RuleSafety {
  const factory RuleSafety({
    @Default(true) bool requirePreview,
    @Default(1) int minMatchCount,
    @Default([]) List<String> excludedPaths,
  }) = _RuleSafetyEntity;

  factory RuleSafety.fromJson(Map<String, dynamic> json) => _$RuleSafetyFromJson(json);
}
