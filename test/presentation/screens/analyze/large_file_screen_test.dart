import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/l10n/app_localizations.dart';
import 'package:xclean/presentation/screens/analyze/large_file_screen.dart';

void main() {
  group('LargeFileScreen widget', () {
    Widget buildApp() {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LargeFileScreen(),
        ),
      );
    }

    testWidgets('shows default threshold of 500 MB', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('slider has correct range', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 100.0);
      expect(slider.max, 5000.0);
      expect(slider.divisions, 49);
    });

    testWidgets('shows sort menu button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.sort), findsOneWidget);
    });
  });
}
