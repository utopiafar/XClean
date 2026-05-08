import '../../domain/entities/clean_rule.dart';
import '../../platform/channels.dart';

/// Matches a scanned file against a cleanup rule.
bool matchesRule(NativeScanResult file, CleanRuleEntity rule) {
  if (rule.matchConditions.isEmpty) return true;
  for (final condition in rule.matchConditions) {
    if (!condition.map(
      filename: (c) {
        if (c.mode == 'wildcard') {
          return wildcardMatch(file.name, c.pattern);
        } else if (c.mode == 'regex') {
          return RegExp(c.pattern).hasMatch(file.name);
        } else if (c.mode == 'contains') {
          return file.name.contains(c.pattern);
        }
        return file.name == c.pattern;
      },
      extension: (c) => c.values.any((ext) => file.name.toLowerCase().endsWith('.$ext')),
      size: (c) => compareValue(file.size, c.operator, c.value),
      modifiedTime: (c) {
        final duration = parseDuration(c.value);
        final compareTime = DateTime.now().subtract(duration);
        // The operator is interpreted from the UI perspective:
        // '>' means "older than" (file was modified BEFORE compareTime)
        // '<' means "newer than" (file was modified AFTER compareTime)
        return compareValue(
          compareTime.millisecondsSinceEpoch,
          c.operator,
          file.lastModified,
        );
      },
      subfileCount: (c) {
        return file.isDirectory && compareValue(file.subfileCount, c.operator, c.value);
      },
    )) {
      return false;
    }
  }
  return true;
}

/// Converts a simple wildcard pattern (*, ?) into a regex and tests match.
bool wildcardMatch(String text, String pattern) {
  final regex = pattern
      .replaceAll('.', r'\.')
      .replaceAll('*', '.*')
      .replaceAll('?', '.');
  return RegExp('^$regex\$', caseSensitive: false).hasMatch(text);
}

/// Compares two integers with the given operator.
bool compareValue(int a, String op, int b) {
  return switch (op) {
    '>' => a > b,
    '>=' => a >= b,
    '<' => a < b,
    '<=' => a <= b,
    '==' => a == b,
    '!=' => a != b,
    _ => false,
  };
}

/// Parses a duration string like '7d', '24h', '30m'.
Duration parseDuration(String value) {
  final num = int.parse(value.replaceAll(RegExp(r'[a-zA-Z]'), ''));
  if (value.endsWith('d')) return Duration(days: num);
  if (value.endsWith('h')) return Duration(hours: num);
  if (value.endsWith('m')) return Duration(minutes: num);
  return Duration(days: num);
}
