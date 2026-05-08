import 'package:freezed_annotation/freezed_annotation.dart';

part 'clean_log.freezed.dart';
part 'clean_log.g.dart';

@freezed
sealed class CleanLogEntity with _$CleanLogEntity {
  const factory CleanLogEntity({
    required int id,
    required DateTime executedAt,
    required String taskType,
    required List<int> rulesApplied,
    required CleanResult results,
    String? details,
  }) = _CleanLogEntity;

  factory CleanLogEntity.fromJson(Map<String, dynamic> json) => _$CleanLogEntityFromJson(json);
}

@freezed
sealed class CleanResult with _$CleanResult {
  const factory CleanResult({
    @Default(0) int freedBytes,
    @Default(0) int fileCount,
    @Default(0) int durationMs,
    @Default(0) int successCount,
    @Default(0) int failCount,
  }) = _CleanResultEntity;

  factory CleanResult.fromJson(Map<String, dynamic> json) => _$CleanResultFromJson(json);
}
