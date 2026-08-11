import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/domain/entities/clean_rule.dart';
import 'package:xclean/platform/channels.dart';
import 'package:xclean/presentation/providers/dashboard_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fileChannel = MethodChannel(ChannelNames.fileChannel);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fileChannel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fileChannel, null);
  });

  testWidgets(
    'ScanNotifier shares an in-progress scan with concurrent callers',
    (tester) async {
      final scanResult = Completer<List<dynamic>>();
      var scanPathCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(fileChannel, (call) async {
            if (call.method == 'scanPath') {
              scanPathCalls += 1;
              return scanResult.future;
            }
            return null;
          });

      final notifier = ScanNotifier();
      final rules = [
        const CleanRuleEntity(
          id: 1,
          name: 'Test rule',
          scope: RuleScope(paths: ['/test']),
          action: RuleAction(),
        ),
      ];

      var firstFinished = false;
      var secondFinished = false;
      final firstScan = notifier.scanWithRules(rules).then((_) {
        firstFinished = true;
      });
      final secondScan = notifier.scanWithRules(rules).then((_) {
        secondFinished = true;
      });
      await tester.pump();

      expect(scanPathCalls, 1);
      expect(notifier.state.isScanning, isTrue);
      expect(firstFinished, isFalse);
      expect(secondFinished, isFalse);

      scanResult.complete([
        {
          'path': '/test/cache.tmp',
          'name': 'cache.tmp',
          'size': 42,
          'lastModified': 0,
          'isDirectory': false,
        },
      ]);
      await Future.wait([firstScan, secondScan]);

      expect(scanPathCalls, 1);
      expect(firstFinished, isTrue);
      expect(secondFinished, isTrue);
      expect(notifier.state.isScanning, isFalse);
      expect(notifier.state.files.single.path, '/test/cache.tmp');
    },
  );
}
