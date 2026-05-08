import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/core/utils/rule_matcher.dart';
import 'package:xclean/domain/entities/clean_rule.dart';
import 'package:xclean/platform/channels.dart';

NativeScanResult _file({
  String name = 'test.txt',
  int size = 100,
  int lastModified = 0,
  bool isDirectory = false,
  int subfileCount = 0,
}) {
  return NativeScanResult(
    path: '/storage/emulated/0/$name',
    name: name,
    size: size,
    lastModified: lastModified,
    isDirectory: isDirectory,
    subfileCount: subfileCount,
  );
}

CleanRuleEntity _rule(List<MatchCondition> conditions) {
  return CleanRuleEntity(
    id: 1,
    name: 'Test',
    scope: const RuleScope(paths: ['/storage/emulated/0'], recursive: true, engine: 'normal'),
    matchConditions: conditions,
    action: const RuleAction(type: 'delete'),
  );
}

void main() {
  group('matchesRule - subfileCount', () {
    test('matches empty directory with subfileCount == 0', () {
      final emptyDir = _file(name: 'empty', isDirectory: true, subfileCount: 0);
      final rule = _rule([const MatchCondition.subfileCount(operator: '==', value: 0)]);
      expect(matchesRule(emptyDir, rule), isTrue);
    });

    test('does not match non-empty directory with subfileCount == 0', () {
      final nonEmptyDir = _file(name: 'nonempty', isDirectory: true, subfileCount: 3);
      final rule = _rule([const MatchCondition.subfileCount(operator: '==', value: 0)]);
      expect(matchesRule(nonEmptyDir, rule), isFalse);
    });

    test('matches non-empty directory with subfileCount > 0', () {
      final nonEmptyDir = _file(name: 'nonempty', isDirectory: true, subfileCount: 5);
      final rule = _rule([const MatchCondition.subfileCount(operator: '>', value: 0)]);
      expect(matchesRule(nonEmptyDir, rule), isTrue);
    });

    test('does not match empty directory with subfileCount > 0', () {
      final emptyDir = _file(name: 'empty', isDirectory: true, subfileCount: 0);
      final rule = _rule([const MatchCondition.subfileCount(operator: '>', value: 0)]);
      expect(matchesRule(emptyDir, rule), isFalse);
    });

    test('does not match file regardless of subfileCount', () {
      final file = _file(name: 'test.txt', isDirectory: false, subfileCount: 0);
      final rule = _rule([const MatchCondition.subfileCount(operator: '==', value: 0)]);
      expect(matchesRule(file, rule), isFalse);
    });

    test('matches directory with exact subfileCount', () {
      final dir = _file(name: 'three_items', isDirectory: true, subfileCount: 3);
      final rule = _rule([const MatchCondition.subfileCount(operator: '==', value: 3)]);
      expect(matchesRule(dir, rule), isTrue);
    });

    test('matches directory with subfileCount < threshold', () {
      final dir = _file(name: 'few_items', isDirectory: true, subfileCount: 2);
      final rule = _rule([const MatchCondition.subfileCount(operator: '<', value: 5)]);
      expect(matchesRule(dir, rule), isTrue);
    });

    test('matches directory with subfileCount >= threshold', () {
      final dir = _file(name: 'many_items', isDirectory: true, subfileCount: 5);
      final rule = _rule([const MatchCondition.subfileCount(operator: '>=', value: 5)]);
      expect(matchesRule(dir, rule), isTrue);
    });
  });

  group('matchesRule - filename', () {
    test('matches wildcard pattern', () {
      final file = _file(name: 'test.log');
      final rule = _rule([const MatchCondition.filename(pattern: '*.log', mode: 'wildcard')]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('does not match wildcard pattern', () {
      final file = _file(name: 'test.txt');
      final rule = _rule([const MatchCondition.filename(pattern: '*.log', mode: 'wildcard')]);
      expect(matchesRule(file, rule), isFalse);
    });

    test('matches exact filename', () {
      final file = _file(name: 'readme.md');
      final rule = _rule([const MatchCondition.filename(pattern: 'readme.md', mode: 'exact')]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('matches contains mode', () {
      final file = _file(name: 'backup_2024_01.zip');
      final rule = _rule([const MatchCondition.filename(pattern: 'backup', mode: 'contains')]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('matches regex mode', () {
      final file = _file(name: 'image_123.png');
      final rule = _rule([const MatchCondition.filename(pattern: r'image_\d+\.png', mode: 'regex')]);
      expect(matchesRule(file, rule), isTrue);
    });
  });

  group('matchesRule - extension', () {
    test('matches one of the extensions', () {
      final file = _file(name: 'data.tmp');
      final rule = _rule([const MatchCondition.extension(values: ['tmp', 'log'])]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('does not match any extension', () {
      final file = _file(name: 'data.txt');
      final rule = _rule([const MatchCondition.extension(values: ['tmp', 'log'])]);
      expect(matchesRule(file, rule), isFalse);
    });
  });

  group('matchesRule - size', () {
    test('matches file larger than threshold', () {
      final file = _file(name: 'big.bin', size: 1024);
      final rule = _rule([const MatchCondition.size(operator: '>', value: 512)]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('does not match file smaller than threshold', () {
      final file = _file(name: 'small.bin', size: 100);
      final rule = _rule([const MatchCondition.size(operator: '>', value: 512)]);
      expect(matchesRule(file, rule), isFalse);
    });
  });

  group('matchesRule - modifiedTime', () {
    test('matches old file', () {
      final oldTime = DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch;
      final file = _file(name: 'old.txt', lastModified: oldTime);
      final rule = _rule([const MatchCondition.modifiedTime(operator: '>', value: '7d')]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('does not match recent file', () {
      final recentTime = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final file = _file(name: 'recent.txt', lastModified: recentTime);
      final rule = _rule([const MatchCondition.modifiedTime(operator: '>', value: '7d')]);
      expect(matchesRule(file, rule), isFalse);
    });
  });

  group('matchesRule - empty conditions', () {
    test('returns true when no conditions', () {
      final file = _file(name: 'anything.exe');
      final rule = _rule([]);
      expect(matchesRule(file, rule), isTrue);
    });
  });

  group('matchesRule - multiple conditions', () {
    test('matches only when all conditions pass', () {
      final file = _file(name: 'app_2024.log', size: 2048);
      final rule = _rule([
        const MatchCondition.filename(pattern: 'app_*.log', mode: 'wildcard'),
        const MatchCondition.size(operator: '>', value: 1024),
      ]);
      expect(matchesRule(file, rule), isTrue);
    });

    test('fails when one condition fails', () {
      final file = _file(name: 'app_2024.log', size: 512);
      final rule = _rule([
        const MatchCondition.filename(pattern: 'app_*.log', mode: 'wildcard'),
        const MatchCondition.size(operator: '>', value: 1024),
      ]);
      expect(matchesRule(file, rule), isFalse);
    });
  });

  group('wildcardMatch', () {
    test('* matches any characters', () {
      expect(wildcardMatch('hello.txt', '*.txt'), isTrue);
      expect(wildcardMatch('hello.log', '*.txt'), isFalse);
    });

    test('? matches single character', () {
      expect(wildcardMatch('test1.log', 'test?.log'), isTrue);
      expect(wildcardMatch('test12.log', 'test?.log'), isFalse);
    });

    test('exact match', () {
      expect(wildcardMatch('file.txt', 'file.txt'), isTrue);
      expect(wildcardMatch('file.txt', 'file.log'), isFalse);
    });
  });

  group('compareValue', () {
    test('all operators', () {
      expect(compareValue(5, '>', 3), isTrue);
      expect(compareValue(3, '>', 5), isFalse);
      expect(compareValue(5, '>=', 5), isTrue);
      expect(compareValue(3, '<', 5), isTrue);
      expect(compareValue(5, '<=', 5), isTrue);
      expect(compareValue(5, '==', 5), isTrue);
      expect(compareValue(5, '!=', 3), isTrue);
      expect(compareValue(5, 'unknown', 3), isFalse);
    });
  });

  group('parseDuration', () {
    test('parses days', () {
      expect(parseDuration('7d'), const Duration(days: 7));
    });

    test('parses hours', () {
      expect(parseDuration('24h'), const Duration(hours: 24));
    });

    test('parses minutes', () {
      expect(parseDuration('30m'), const Duration(minutes: 30));
    });

    test('defaults to days when no suffix', () {
      expect(parseDuration('7'), const Duration(days: 7));
    });
  });
}
