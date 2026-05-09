import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/domain/entities/clean_log.dart';
import 'package:xclean/presentation/screens/logs/log_detail_screen.dart';

class _TestableLogDetailScreen extends LogDetailScreen {
  const _TestableLogDetailScreen({required super.log});

  List<String> parseDeletedFiles(String? details) {
    if (details == null || details.isEmpty) return [];
    return details.split('\n').where((s) => s.isNotEmpty).toList();
  }
}

void main() {
  group('LogDetailScreen parseDeletedFiles', () {
    test('parses newline-separated file names', () {
      final widget = _TestableLogDetailScreen(
        log: CleanLogEntity(
          id: 1,
          executedAt: DateTime.now(),
          taskType: 'manual',
          rulesApplied: [],
          results: const CleanResult(),
        ),
      );

      expect(
        widget.parseDeletedFiles('a.txt\nb.txt\nc.txt'),
        ['a.txt', 'b.txt', 'c.txt'],
      );
    });

    test('handles trailing newline', () {
      final widget = _TestableLogDetailScreen(
        log: CleanLogEntity(
          id: 1,
          executedAt: DateTime.now(),
          taskType: 'manual',
          rulesApplied: [],
          results: const CleanResult(),
        ),
      );

      expect(
        widget.parseDeletedFiles('a.txt\nb.txt\n'),
        ['a.txt', 'b.txt'],
      );
    });

    test('returns empty list for null details', () {
      final widget = _TestableLogDetailScreen(
        log: CleanLogEntity(
          id: 1,
          executedAt: DateTime.now(),
          taskType: 'manual',
          rulesApplied: [],
          results: const CleanResult(),
        ),
      );

      expect(widget.parseDeletedFiles(null), isEmpty);
    });

    test('returns empty list for empty string', () {
      final widget = _TestableLogDetailScreen(
        log: CleanLogEntity(
          id: 1,
          executedAt: DateTime.now(),
          taskType: 'manual',
          rulesApplied: [],
          results: const CleanResult(),
        ),
      );

      expect(widget.parseDeletedFiles(''), isEmpty);
    });

    test('handles single file without newline', () {
      final widget = _TestableLogDetailScreen(
        log: CleanLogEntity(
          id: 1,
          executedAt: DateTime.now(),
          taskType: 'manual',
          rulesApplied: [],
          results: const CleanResult(),
        ),
      );

      expect(widget.parseDeletedFiles('single.mp4'), ['single.mp4']);
    });

    test('filters out empty lines', () {
      final widget = _TestableLogDetailScreen(
        log: CleanLogEntity(
          id: 1,
          executedAt: DateTime.now(),
          taskType: 'manual',
          rulesApplied: [],
          results: const CleanResult(),
        ),
      );

      expect(
        widget.parseDeletedFiles('a.txt\n\nb.txt\n\nc.txt'),
        ['a.txt', 'b.txt', 'c.txt'],
      );
    });
  });
}
