import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class CleanRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get priority => integer().withDefault(const Constant(100))();
  TextColumn get scopeJson => text().withDefault(const Constant('{}'))();
  TextColumn get matchConditionsJson => text().withDefault(const Constant('[]'))();
  TextColumn get actionJson => text().withDefault(const Constant('{}'))();
  TextColumn get safetyJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CleanLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get executedAt => dateTime()();
  TextColumn get taskType => text()();
  TextColumn get rulesAppliedJson => text().withDefault(const Constant('[]'))();
  TextColumn get resultsJson => text().withDefault(const Constant('{}'))();
  TextColumn get detailsJson => text().nullable()();
}

class AutoTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get ruleIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get scheduleJson => text().withDefault(const Constant('{}'))();
  TextColumn get conditionsJson => text().nullable()();
  BoolColumn get requirePreview => boolean().withDefault(const Constant(false))();
  BoolColumn get useForegroundService => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [CleanRules, CleanLogs, AutoTasks, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(autoTasks);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'xclean_database');
  }

  // Settings helpers
  Future<String?> getSetting(String key) async {
    final result = await (select(appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  // Rule helpers
  Future<List<CleanRule>> getEnabledRules() async {
    return (select(cleanRules)
          ..where((r) => r.enabled.equals(true))
          ..orderBy([(r) => OrderingTerm.asc(r.priority)]))
        .get();
  }

  Future<List<CleanRule>> getAllRules() async {
    return (select(cleanRules)..orderBy([(r) => OrderingTerm.asc(r.priority)])).get();
  }

  Future<int> insertRule(CleanRulesCompanion rule) => into(cleanRules).insert(rule);

  Future<bool> updateRule(CleanRulesCompanion rule) => update(cleanRules).replace(rule);

  Future<int> deleteRule(int id) => (delete(cleanRules)..where((r) => r.id.equals(id))).go();

  // Log helpers
  Future<List<CleanLog>> getRecentLogs(int limit) async {
    return (select(cleanLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.executedAt)])
          ..limit(limit))
        .get();
  }

  Future<int> insertLog(CleanLogsCompanion log) => into(cleanLogs).insert(log);

  Future<int> clearOldLogs(DateTime before) =>
      (delete(cleanLogs)..where((l) => l.executedAt.isSmallerThanValue(before))).go();
}
