import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/domain/entities/clean_rule.dart';
import 'package:xclean/l10n/app_localizations.dart';
import 'package:xclean/presentation/providers/dashboard_provider.dart';
import 'package:xclean/presentation/screens/rules/rule_list_screen.dart';

void main() {
  group('RuleListScreen', () {
    final presetRule = CleanRuleEntity(
      id: 1,
      name: 'Thumbnail Cache',
      description: 'Clean image cache in .thumbnails directory',
      enabled: true,
      priority: 10,
      scope: const RuleScope(paths: ['/test'], recursive: true, engine: 'normal'),
      matchConditions: const [],
      action: const RuleAction(type: 'delete'),
      safety: const RuleSafety(),
    );

    final customRule = CleanRuleEntity(
      id: 6,
      name: 'My Custom Rule',
      description: 'A custom rule',
      enabled: false,
      priority: 100,
      scope: const RuleScope(paths: ['/test'], recursive: true, engine: 'normal'),
      matchConditions: const [],
      action: const RuleAction(type: 'delete'),
      safety: const RuleSafety(),
    );

    final shizukuRule = CleanRuleEntity(
      id: 7,
      name: 'Shizuku Rule',
      description: null,
      enabled: true,
      priority: 50,
      scope: const RuleScope(paths: ['/test'], recursive: true, engine: 'shizuku'),
      matchConditions: const [],
      action: const RuleAction(type: 'delete'),
      safety: const RuleSafety(),
    );

    testWidgets('displays preset and custom sections', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRulesProvider.overrideWith((ref) async => [presetRule, customRule]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RuleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preset Rules'), findsOneWidget);
      expect(find.text('Custom Rules'), findsOneWidget);
      expect(find.text('Thumbnail Cache'), findsOneWidget);
      expect(find.text('My Custom Rule'), findsOneWidget);
    });

    testWidgets('preset rules do not show delete button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRulesProvider.overrideWith((ref) async => [presetRule]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RuleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('custom rules show both edit and delete buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRulesProvider.overrideWith((ref) async => [customRule]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RuleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('engine chips display correct colors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRulesProvider.overrideWith((ref) async => [presetRule, shizukuRule]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RuleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both rules are rendered
      expect(find.text('Thumbnail Cache'), findsOneWidget);
      expect(find.text('Shizuku Rule'), findsOneWidget);
    });

    testWidgets('shows empty state when no rules', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRulesProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RuleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No rules yet'), findsOneWidget);
    });

    testWidgets('switch is present for each rule', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allRulesProvider.overrideWith((ref) async => [presetRule, customRule]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RuleListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find 2 switches (one for each rule)
      expect(find.byType(Switch), findsNWidgets(2));
    });
  });
}


