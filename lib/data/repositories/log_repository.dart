import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/entities/clean_log.dart';
import '../local/database.dart';

class LogRepository {
  final AppDatabase _db;

  LogRepository(this._db);

  Future<List<CleanLogEntity>> getRecentLogs(int limit) async {
    final rows = await _db.getRecentLogs(limit);
    return rows.map(_mapRowToEntity).toList();
  }

  Future<List<CleanLogEntity>> getAllLogs() async {
    final rows = await _db.getAllLogs();
    return rows.map(_mapRowToEntity).toList();
  }

  Future<int> insertLog(CleanLogEntity log) {
    return _db.insertLog(CleanLogsCompanion(
      executedAt: Value(log.executedAt),
      taskType: Value(log.taskType),
      rulesAppliedJson: Value(jsonEncode(log.rulesApplied)),
      resultsJson: Value(jsonEncode(log.results.toJson())),
      detailsJson: Value(log.details),
    ));
  }

  CleanLogEntity _mapRowToEntity(CleanLog row) {
    return CleanLogEntity(
      id: row.id,
      executedAt: row.executedAt,
      taskType: row.taskType,
      rulesApplied: (jsonDecode(row.rulesAppliedJson) as List).cast<int>(),
      results: CleanResult.fromJson(jsonDecode(row.resultsJson)),
      details: row.detailsJson,
    );
  }
}
