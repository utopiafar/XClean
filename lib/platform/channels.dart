import 'dart:async';

import 'package:flutter/services.dart';

/// Platform channel constants matching Android native code
class ChannelNames {
  static const fileChannel = 'com.utopiafar.xclean/file';
  static const permissionChannel = 'com.utopiafar.xclean/permission';
  static const backgroundChannel = 'com.utopiafar.xclean/background';
}

/// File scan result from native
class NativeScanResult {
  final String path;
  final String name;
  final int size;
  final int lastModified;
  final bool isDirectory;
  final int subfileCount;

  NativeScanResult({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.isDirectory,
    this.subfileCount = 0,
  });

  factory NativeScanResult.fromMap(Map<String, dynamic> map) {
    return NativeScanResult(
      path: map['path'] as String,
      name: map['name'] as String,
      size: map['size'] as int,
      lastModified: map['lastModified'] as int,
      isDirectory: map['isDirectory'] as bool,
      subfileCount: map['subfileCount'] as int? ?? 0,
    );
  }
}

/// File operation channel
class FileChannel {
  static const _channel = MethodChannel(ChannelNames.fileChannel);
  static const _eventChannel = EventChannel('com.utopiafar.xclean/file_events');

  /// Scan files in a path with optional pattern
  static Future<List<NativeScanResult>> scanPath({
    required String path,
    String? pattern,
    bool recursive = true,
    String engine = 'auto',
    int? minSizeBytes,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('scanPath', {
      'path': path,
      'pattern': pattern,
      'recursive': recursive,
      'engine': engine,
      'minSizeBytes': minSizeBytes,
    });
    return (result ?? [])
        .map((e) => NativeScanResult.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Stream scan for large directories
  static Stream<NativeScanResult> scanPathStream({
    required String path,
    String? pattern,
    bool recursive = true,
    String engine = 'auto',
    int? minSizeBytes,
  }) {
    _channel.invokeMethod('startScanStream', {
      'path': path,
      'pattern': pattern,
      'recursive': recursive,
      'engine': engine,
      'minSizeBytes': minSizeBytes,
    });
    return _eventChannel.receiveBroadcastStream().map((event) {
      return NativeScanResult.fromMap(Map<String, dynamic>.from(event as Map));
    });
  }

  /// Delete files by paths
  static Future<Map<String, dynamic>> deleteFiles(
    List<String> paths, {
    String engine = 'auto',
    bool requireExisting = true,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'deleteFiles',
      {'paths': paths, 'engine': engine, 'requireExisting': requireExisting},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Read native diagnostic logs for scan/delete troubleshooting.
  static Future<String> getDiagnosticLogs() async {
    return await _channel.invokeMethod<String>('getDiagnosticLogs') ?? '';
  }

  /// Clear native diagnostic logs.
  static Future<bool> clearDiagnosticLogs() async {
    return await _channel.invokeMethod<bool>('clearDiagnosticLogs') ?? false;
  }

  /// Get storage info: {totalBytes, freeBytes, usedBytes}
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getStorageInfo',
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Calculate directory size
  static Future<int> getDirectorySize(
    String path, {
    String engine = 'auto',
  }) async {
    return await _channel.invokeMethod<int>('getDirectorySize', {
          'path': path,
          'engine': engine,
        }) ??
        0;
  }

  /// Get video thumbnail path (JPEG). Returns null if thumbnail cannot be generated.
  static Future<String?> getVideoThumbnail(String path) async {
    return await _channel.invokeMethod<String>('getVideoThumbnail', {
      'path': path,
    });
  }
}

/// Permission channel
class PermissionChannel {
  static const _channel = MethodChannel(ChannelNames.permissionChannel);

  static Future<String> getPermissionStatus() async {
    return await _channel.invokeMethod<String>('getPermissionStatus') ??
        'unknown';
  }

  static Future<bool> requestAllFilesAccess() async {
    return await _channel.invokeMethod<bool>('requestAllFilesAccess') ?? false;
  }

  static Future<bool> openAppSettings() async {
    return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
  }

  static Future<String> getRomType() async {
    return await _channel.invokeMethod<String>('getRomType') ?? 'unknown';
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    return await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored') ??
        false;
  }

  static Future<bool> requestIgnoreBatteryOptimization() async {
    return await _channel.invokeMethod<bool>(
          'requestIgnoreBatteryOptimization',
        ) ??
        false;
  }

  static Future<bool> isShizukuAvailable() async {
    return await _channel.invokeMethod<bool>('isShizukuAvailable') ?? false;
  }

  static Future<bool> isRootAvailable() async {
    return await _channel.invokeMethod<bool>('isRootAvailable') ?? false;
  }
}

/// Background task channel
class BackgroundChannel {
  static const _channel = MethodChannel(ChannelNames.backgroundChannel);

  static Future<bool> scheduleAutoClean({
    required int intervalMinutes,
    required List<int> ruleIds,
    bool useForegroundService = false,
  }) async {
    return await _channel.invokeMethod<bool>('scheduleAutoClean', {
          'intervalMinutes': intervalMinutes,
          'ruleIds': ruleIds,
          'useForegroundService': useForegroundService,
        }) ??
        false;
  }

  static Future<bool> cancelAutoClean() async {
    return await _channel.invokeMethod<bool>('cancelAutoClean') ?? false;
  }
}
