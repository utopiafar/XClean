import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/l10n/app_localizations.dart';
import 'package:xclean/platform/channels.dart';
import 'package:xclean/presentation/screens/analyze/large_file_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LargeFileScreen widget', () {
    const fileChannel = MethodChannel(ChannelNames.fileChannel);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(fileChannel, null);
    });

    Widget buildApp() {
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LargeFileScreen(),
      );
    }

    testWidgets('opens without starting a scan', (tester) async {
      var scanCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(fileChannel, (call) async {
            if (call.method == 'scanPath') scanCalled = true;
            return <dynamic>[];
          });

      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(scanCalled, isFalse);
      expect(find.text('No scan yet'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('shows threshold presets instead of a slider', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byType(Slider), findsNothing);
      expect(find.text('100 MB'), findsOneWidget);
      expect(find.text('500 MB'), findsAtLeastNWidgets(1));
      expect(find.text('1 GB'), findsOneWidget);
      expect(find.text('5 GB'), findsOneWidget);
    });

    testWidgets('scan button sends the selected threshold and shows results', (
      tester,
    ) async {
      Map<dynamic, dynamic>? scanArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(fileChannel, (call) async {
            if (call.method == 'scanPath') {
              scanArgs = call.arguments as Map<dynamic, dynamic>;
              return [
                {
                  'path': '/storage/emulated/0/Movies/movie.mkv',
                  'name': 'movie.mkv',
                  'size': 700 * 1024 * 1024,
                  'lastModified': 123,
                  'isDirectory': false,
                  'subfileCount': 0,
                },
              ];
            }
            return null;
          });

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(scanArgs?['path'], '/storage/emulated/0');
      expect(scanArgs?['recursive'], isTrue);
      expect(scanArgs?['engine'], 'auto');
      expect(scanArgs?['minSizeBytes'], 500 * 1024 * 1024);
      expect(find.text('movie.mkv'), findsOneWidget);
      expect(find.textContaining('0.7 GB'), findsAtLeastNWidgets(1));
    });
  });
}
