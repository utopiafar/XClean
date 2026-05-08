import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_task.freezed.dart';
part 'auto_task.g.dart';

@freezed
sealed class AutoTaskEntity with _$AutoTaskEntity {
  const factory AutoTaskEntity({
    required int id,
    required String name,
    @Default([]) List<int> ruleIds,
    required TaskSchedule schedule,
    TaskConditions? conditions,
    @Default(false) bool requirePreview,
    @Default(false) bool useForegroundService,
    @Default(true) bool enabled,
  }) = _AutoTaskEntity;

  factory AutoTaskEntity.fromJson(Map<String, dynamic> json) => _$AutoTaskEntityFromJson(json);
}

@freezed
sealed class TaskSchedule with _$TaskSchedule {
  const factory TaskSchedule({
    @Default('daily') String period,
    @Default('02:00') String timeOfDay,
    @Default(15) int intervalMinutes,
  }) = _TaskSchedule;

  factory TaskSchedule.fromJson(Map<String, dynamic> json) => _$TaskScheduleFromJson(json);
}

@freezed
sealed class TaskConditions with _$TaskConditions {
  const factory TaskConditions({
    @Default(10) int minBatteryPercent,
    @Default(true) bool requireCharging,
    @Default(0) int minFreeSpacePercent,
  }) = _TaskConditions;

  factory TaskConditions.fromJson(Map<String, dynamic> json) => _$TaskConditionsFromJson(json);
}
