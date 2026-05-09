import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/l10n/app_localizations.dart';
import 'package:xclean/presentation/providers/dashboard_provider.dart';
import 'package:xclean/presentation/screens/clean/preview_screen.dart';

void main() {
  group('PreviewScreen widget', () {
    final files = [
      ScannedFile(
        path: '/test/photo.jpg',
        name: 'photo.jpg',
        size: 1024,
        lastModified: DateTime.now(),
        isDirectory: false,
        selected: true,
      ),
      ScannedFile(
        path: '/test/doc.pdf',
        name: 'doc.pdf',
        size: 2048,
        lastModified: DateTime.now(),
        isDirectory: false,
        selected: false,
      ),
      ScannedFile(
        path: '/test/movie.mp4',
        name: 'movie.mp4',
        size: 10240,
        lastModified: DateTime.now(),
        isDirectory: false,
        selected: true,
      ),
    ];

    ProviderScope buildApp(Widget child) {
      return ProviderScope(
        overrides: [
          scanProvider.overrideWith((ref) => ScanNotifier()..state = ScanState(files: files)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets('shows correct selected count', (tester) async {
      await tester.pumpWidget(buildApp(const PreviewScreen()));
      await tester.pump();

      // 2 files selected (photo.jpg + movie.mp4), total 3
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('renders file grid items', (tester) async {
      await tester.pumpWidget(buildApp(const PreviewScreen()));
      await tester.pump();

      // Should find grid items
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('select all and select none buttons exist', (tester) async {
      await tester.pumpWidget(buildApp(const PreviewScreen()));
      await tester.pump();

      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('shows empty state when no files', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scanProvider.overrideWith((ref) => ScanNotifier()..state = const ScanState(files: [])),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PreviewScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No matched files'), findsOneWidget);
    });

    testWidgets('cancel and clean buttons exist', (tester) async {
      await tester.pumpWidget(buildApp(const PreviewScreen()));
      await tester.pump();

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
