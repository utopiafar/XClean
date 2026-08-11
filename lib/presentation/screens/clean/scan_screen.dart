import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xclean/l10n/app_localizations.dart';

import '../../../platform/channels.dart';
import '../../providers/dashboard_provider.dart';

/// Runs a one-key scan immediately after the page is opened.
///
/// This is also the destination of the Android launcher shortcut, so it owns
/// the setup that the dashboard normally performs before a scan can begin.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

enum _ScanPageState {
  preparing,
  permissionRequired,
  scanning,
  noRules,
  noResults,
  error,
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  static bool _hasActiveScanScreen = false;

  _ScanPageState _pageState = _ScanPageState.preparing;
  String? _error;
  bool _isStarting = false;
  bool _waitingForPermission = false;
  late final bool _ownsScanLaunch;

  @override
  void initState() {
    super.initState();
    _ownsScanLaunch = !_hasActiveScanScreen;
    if (!_ownsScanLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _dismissDuplicate());
      return;
    }

    _hasActiveScanScreen = true;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    if (_ownsScanLaunch) {
      _hasActiveScanScreen = false;
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ownsScanLaunch &&
        state == AppLifecycleState.resumed &&
        _waitingForPermission) {
      _startScan();
    }
  }

  void _dismissDuplicate() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _startScan() async {
    if (!_ownsScanLaunch || _isStarting || !mounted) return;

    _isStarting = true;
    _waitingForPermission = false;
    setState(() {
      _pageState = _ScanPageState.preparing;
      _error = null;
    });

    try {
      final scanNotifier = ref.read(scanProvider.notifier);
      final activeScan = scanNotifier.activeScan;
      if (activeScan != null) {
        setState(() => _pageState = _ScanPageState.scanning);
        await activeScan;
        if (!mounted) return;
        _showScanResult();
        return;
      }

      final permissionStatus = await PermissionChannel.getPermissionStatus();
      if (!mounted) return;

      if (permissionStatus != 'granted') {
        _waitingForPermission = true;
        setState(() => _pageState = _ScanPageState.permissionRequired);
        return;
      }

      ref.invalidate(permissionStatusProvider);
      ref.invalidate(storageInfoProvider);

      final ruleRepository = ref.read(ruleRepositoryProvider);
      await ruleRepository.initPresetRules();
      if (!mounted) return;

      ref.invalidate(enabledRulesProvider);
      final rules = await ref.read(enabledRulesProvider.future);
      if (!mounted) return;

      if (rules.isEmpty) {
        setState(() => _pageState = _ScanPageState.noRules);
        return;
      }

      setState(() => _pageState = _ScanPageState.scanning);
      await scanNotifier.scanWithRules(rules);
      if (!mounted) return;

      _showScanResult();
    } catch (error) {
      if (mounted) {
        setState(() {
          _pageState = _ScanPageState.error;
          _error = error.toString();
        });
      }
    } finally {
      _isStarting = false;
    }
  }

  void _showScanResult() {
    final scanState = ref.read(scanProvider);
    if (scanState.files.isNotEmpty) {
      context.pushReplacement('/preview');
    } else if (scanState.error != null) {
      setState(() {
        _pageState = _ScanPageState.error;
        _error = scanState.error;
      });
    } else {
      setState(() => _pageState = _ScanPageState.noResults);
    }
  }

  Future<void> _requestPermission() async {
    await PermissionChannel.requestAllFilesAccess();
    if (!mounted) return;

    final permissionStatus = await PermissionChannel.getPermissionStatus();
    if (permissionStatus == 'granted') {
      await _startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.oneKeyScan)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildContent(context, l10n, scanState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ScanState scanState,
  ) {
    return switch (_pageState) {
      _ScanPageState.preparing => _StatusPanel(
        key: const ValueKey('preparing'),
        icon: Icons.radar_rounded,
        title: l10n.oneKeyScan,
        message: l10n.scanning,
        loading: true,
      ),
      _ScanPageState.scanning => _StatusPanel(
        key: const ValueKey('scanning'),
        icon: Icons.radar_rounded,
        title: l10n.scanning,
        message: '${(scanState.progress * 100).round()}%',
        progress: scanState.progress,
        loading: true,
      ),
      _ScanPageState.permissionRequired => _StatusPanel(
        key: const ValueKey('permission'),
        icon: Icons.folder_off_outlined,
        title: l10n.storagePermissionNeeded,
        message: l10n.storagePermissionRequired,
        action: FilledButton.icon(
          onPressed: _requestPermission,
          icon: const Icon(Icons.lock_open_outlined),
          label: Text(l10n.grantPermission),
        ),
      ),
      _ScanPageState.noRules => _StatusPanel(
        key: const ValueKey('no-rules'),
        icon: Icons.rule_folder_outlined,
        title: l10n.noEnabledRules,
        action: FilledButton.icon(
          onPressed: () => context.push('/rules'),
          icon: const Icon(Icons.rule_folder_outlined),
          label: Text(l10n.ruleManagement),
        ),
      ),
      _ScanPageState.noResults => _StatusPanel(
        key: const ValueKey('no-results'),
        icon: Icons.check_circle_outline_rounded,
        title: l10n.noMatchedFiles,
        action: OutlinedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.oneKeyScan),
        ),
      ),
      _ScanPageState.error => _StatusPanel(
        key: const ValueKey('error'),
        icon: Icons.error_outline_rounded,
        title: l10n.scanFailed(_error ?? ''),
        action: OutlinedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.oneKeyScan),
        ),
      ),
    };
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.progress,
    this.loading = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final double? progress;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: loading
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 42,
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                )
              : Icon(icon, size: 52, color: colorScheme.primary),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (progress != null) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    );
  }
}
