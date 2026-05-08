import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../platform/channels.dart';
import '../providers/dashboard_provider.dart';

class PermissionBanner extends ConsumerWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionStatusProvider);

    return permissionAsync.when(
      data: (status) {
        if (status == 'granted') return const SizedBox.shrink();

        return Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '需要存储权限',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Text(
                        'XClean 需要访问所有文件才能执行清理',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final granted = await PermissionChannel.requestAllFilesAccess();
                    if (granted) {
                      ref.invalidate(permissionStatusProvider);
                      ref.invalidate(storageInfoProvider);
                    } else {
                      await PermissionChannel.openAppSettings();
                    }
                  },
                  child: const Text('授权'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
