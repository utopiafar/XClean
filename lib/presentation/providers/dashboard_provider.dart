import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/rule_matcher.dart';
import '../../data/local/database.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/rule_repository.dart';
import '../../domain/entities/clean_log.dart';
import '../../domain/entities/clean_rule.dart';
import '../../platform/channels.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final ruleRepositoryProvider = Provider<RuleRepository>(
  (ref) => RuleRepository(ref.watch(databaseProvider)),
);

final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepository(ref.watch(databaseProvider)),
);

final storageInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return FileChannel.getStorageInfo();
});

final enabledRulesProvider = FutureProvider<List<CleanRuleEntity>>((ref) async {
  final repo = ref.watch(ruleRepositoryProvider);
  return repo.getEnabledRules();
});

final allRulesProvider = FutureProvider<List<CleanRuleEntity>>((ref) async {
  final repo = ref.watch(ruleRepositoryProvider);
  return repo.getAllRules();
});

final recentLogsProvider = FutureProvider<List<CleanLogEntity>>((ref) async {
  final repo = ref.watch(logRepositoryProvider);
  return repo.getRecentLogs(10);
});

final allLogsProvider = FutureProvider<List<CleanLogEntity>>((ref) async {
  final repo = ref.watch(logRepositoryProvider);
  return repo.getAllLogs();
});

final permissionStatusProvider = FutureProvider<String>((ref) async {
  return PermissionChannel.getPermissionStatus();
});

final romTypeProvider = FutureProvider<String>((ref) async {
  return PermissionChannel.getRomType();
});

// Scan state
class ScanState {
  final bool isScanning;
  final double progress;
  final List<ScannedFile> files;
  final String? error;

  const ScanState({
    this.isScanning = false,
    this.progress = 0,
    this.files = const [],
    this.error,
  });

  ScanState copyWith({
    bool? isScanning,
    double? progress,
    List<ScannedFile>? files,
    String? error,
  }) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      progress: progress ?? this.progress,
      files: files ?? this.files,
      error: error ?? this.error,
    );
  }
}

class ScannedFile {
  final String path;
  final String name;
  final int size;
  final DateTime lastModified;
  final bool isDirectory;
  bool selected;

  ScannedFile({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.isDirectory,
    this.selected = true,
  });
}

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier() : super(const ScanState());

  Future<void> scanWithRules(List<CleanRuleEntity> rules) async {
    state = const ScanState(isScanning: true, progress: 0, files: []);
    final allFiles = <ScannedFile>[];

    try {
      for (int i = 0; i < rules.length; i++) {
        final rule = rules[i];
        for (final path in rule.scope.paths) {
          final results = await FileChannel.scanPath(
            path: path,
            recursive: rule.scope.recursive,
            engine: rule.scope.engine,
          );

          for (final r in results) {
            if (matchesRule(r, rule)) {
              allFiles.add(ScannedFile(
                path: r.path,
                name: r.name,
                size: r.size,
                lastModified: DateTime.fromMillisecondsSinceEpoch(r.lastModified),
                isDirectory: r.isDirectory,
              ));
            }
          }
        }
        state = state.copyWith(
          progress: (i + 1) / rules.length,
        );
      }

      state = ScanState(
        isScanning: false,
        progress: 1,
        files: allFiles,
      );
    } catch (e) {
      state = ScanState(
        isScanning: false,
        error: e.toString(),
        files: allFiles,
      );
    }
  }

  Future<({CleanResult result, List<String> deletedPaths, List<String> failedPaths})> executeClean() async {
    final selectedFiles = state.files.where((f) => f.selected).toList();
    if (selectedFiles.isEmpty) {
      return (result: const CleanResult(), deletedPaths: <String>[], failedPaths: <String>[]);
    }

    final paths = selectedFiles.map((f) => f.path).toList();
    final result = await FileChannel.deleteFiles(paths);

    final freedBytes = result['freedBytes'] as int? ?? 0;
    final successCount = result['successCount'] as int? ?? 0;
    final failCount = result['failCount'] as int? ?? 0;
    final deletedPaths = (result['deletedPaths'] as List<dynamic>?)?.cast<String>() ?? [];
    final failedPaths = (result['failedPaths'] as List<dynamic>?)?.cast<String>() ?? [];

    return (
      result: CleanResult(
        freedBytes: freedBytes,
        fileCount: selectedFiles.length,
        successCount: successCount,
        failCount: failCount,
      ),
      deletedPaths: deletedPaths,
      failedPaths: failedPaths,
    );
  }

  void toggleSelection(int index) {
    final files = [...state.files];
    files[index] = files[index]..selected = !files[index].selected;
    state = state.copyWith(files: files);
  }

  void selectAll(bool selected) {
    final files = state.files.map((f) => ScannedFile(
      path: f.path,
      name: f.name,
      size: f.size,
      lastModified: f.lastModified,
      isDirectory: f.isDirectory,
      selected: selected,
    )).toList();
    state = state.copyWith(files: files);
  }

  void clear() {
    state = const ScanState();
  }


}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});
