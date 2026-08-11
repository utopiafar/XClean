import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/l10n/app_localizations.dart';
import 'package:xclean/platform/channels.dart';
import 'package:xclean/presentation/screens/clean/scan_screen.dart';
import 'package:xclean/routing/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const permissionChannel = MethodChannel(ChannelNames.permissionChannel);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          if (call.method == 'getPermissionStatus') return 'denied';
          if (call.method == 'requestAllFilesAccess') return false;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  testWidgets('Android one-key scan shortcut opens the scan page', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        'xclean://shortcut/scan';
    final testRouter = createRouter();
    addTearDown(() {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
      testRouter.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(testRouter.routeInformationProvider.value.uri.path, '/scan');
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('permission')), findsOneWidget);
  });

  testWidgets('Android shortcut routes an already-running app to scan', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    final testRouter = createRouter();
    addTearDown(() {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
      testRouter.dispose();
    });

    // Start on a lightweight existing route so this test represents a warm
    // app without invoking DashboardScreen's database and platform work.
    testRouter.go('/preview');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    expect(testRouter.routeInformationProvider.value.uri.path, '/preview');

    // FlutterActivity forwards an Intent data URI received by onNewIntent()
    // as this message on the framework navigation channel.
    final message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', <String, dynamic>{
        'location': 'xclean://shortcut/scan',
      }),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    await tester.pump();
    await tester.pump();

    expect(testRouter.routeInformationProvider.value.uri.path, '/scan');
    expect(find.byType(ScanScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('permission')), findsOneWidget);
  });

  testWidgets('does not stack duplicate scan pages while preparing', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    final testRouter = createRouter();
    addTearDown(() {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
      testRouter.dispose();
    });
    testRouter.go('/preview');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    testRouter.push('/scan');
    await tester.pumpAndSettle();
    expect(find.byType(ScanScreen), findsOneWidget);

    testRouter.push('/scan');
    await tester.pumpAndSettle();

    expect(find.byType(ScanScreen), findsOneWidget);
  });
}
