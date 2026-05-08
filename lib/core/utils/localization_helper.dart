import 'package:flutter/material.dart';
import 'package:xclean/l10n/app_localizations.dart';

/// Localizes preset rule names that are stored as English keys in the database.
String localizePresetName(BuildContext context, String name) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return name;
  return switch (name) {
    'Thumbnail Cache' => l10n.thumbnailCache,
    'Empty Folders' => l10n.emptyFolders,
    'Download Temp Files' => l10n.downloadTempFiles,
    'Log Files' => l10n.logFiles,
    'App Residual' => l10n.appResidual,
    _ => name,
  };
}

/// Localizes preset rule descriptions that are stored as English keys in the database.
String localizePresetDesc(BuildContext context, String? desc) {
  if (desc == null) return '';
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return desc;
  return switch (desc) {
    'Clean image cache in .thumbnails directory' => l10n.thumbnailCacheDesc,
    'Recursively clean empty directories' => l10n.emptyFoldersDesc,
    'Clean temporary files in download directory' => l10n.downloadTempFilesDesc,
    'Clean application log files' => l10n.logFilesDesc,
    'Clean residual directories of uninstalled apps' => l10n.appResidualDesc,
    _ => desc,
  };
}
