// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'XClean';

  @override
  String get storagePermissionRequired =>
      'XClean needs access to all files to perform cleanup';

  @override
  String get grantPermission => 'Grant';

  @override
  String get storagePermissionNeeded => 'Storage permission required';

  @override
  String get oneKeyScan => 'One-Key Scan';

  @override
  String get ruleManagement => 'Rule Management';

  @override
  String get autoClean => 'Auto Clean';

  @override
  String get largeFiles => 'Large Files';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get enabledRules => 'Enabled Rules';

  @override
  String get viewAll => 'View All';

  @override
  String get recentCleanups => 'Recent Cleanups';

  @override
  String get available => 'Available';

  @override
  String get used => 'Used';

  @override
  String get total => 'Total';

  @override
  String get scanning => 'Scanning...';

  @override
  String get noEnabledRules => 'No enabled rules, please enable a rule first';

  @override
  String get noMatchedFiles => 'No cleanable files matched';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String moreRules(int count) {
    return '$count more rules...';
  }

  @override
  String storageInfoError(String error) {
    return 'Unable to get storage info: $error';
  }

  @override
  String romDetected(String rom) {
    return 'Detected system: $rom';
  }

  @override
  String get settings => 'Settings';

  @override
  String get thumbnailCache => 'Thumbnail Cache';

  @override
  String get thumbnailCacheDesc => 'Clean image cache in .thumbnails directory';

  @override
  String get emptyFolders => 'Empty Folders';

  @override
  String get emptyFoldersDesc => 'Recursively clean empty directories';

  @override
  String get downloadTempFiles => 'Download Temp Files';

  @override
  String get downloadTempFilesDesc =>
      'Clean temporary files in download directory';

  @override
  String get logFiles => 'Log Files';

  @override
  String get logFilesDesc => 'Clean application log files';

  @override
  String get appResidual => 'App Residual';

  @override
  String get appResidualDesc =>
      'Clean residual directories of uninstalled apps';

  @override
  String get cleanPreview => 'Clean Preview';

  @override
  String get selectAll => 'Select All';

  @override
  String get selectNone => 'Select None';

  @override
  String selectedCount(int selected, int total) {
    return 'Selected $selected / $total files';
  }

  @override
  String releasable(String size) {
    return 'Releasable $size';
  }

  @override
  String get noMatchedFilesPreview => 'No matched files';

  @override
  String get directory => 'Directory';

  @override
  String get cancel => 'Cancel';

  @override
  String cleanWithSize(String size) {
    return 'Clean ($size)';
  }

  @override
  String get cleaning => 'Cleaning...';

  @override
  String get cleanComplete => 'Clean Complete';

  @override
  String releasedSpace(String size) {
    return 'Released space: $size';
  }

  @override
  String fileCount(int count) {
    return 'File count: $count';
  }

  @override
  String successFailCount(int success, int fail) {
    return 'Success: $success  Fail: $fail';
  }

  @override
  String duration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String cleanFailed(String error) {
    return 'Clean failed: $error';
  }

  @override
  String get confirm => 'OK';

  @override
  String get largeFileAnalysis => 'Large File Analysis';

  @override
  String minFileSize(int size) {
    return 'Min file size: $size MB';
  }

  @override
  String get sortBySize => 'Sort by size';

  @override
  String get sortByTime => 'Sort by time';

  @override
  String get sortByName => 'Sort by name';

  @override
  String get noLargeFiles => 'No large files found matching criteria';

  @override
  String get videoThumbnailError => 'Video thumbnail unavailable';

  @override
  String scanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get deleteThisFile => 'Delete this file';

  @override
  String get deleted => 'Deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get viewDirectory => 'View directory';

  @override
  String get ruleListTitle => 'Clean Rules';

  @override
  String get newRule => 'New Rule';

  @override
  String get presetRules => 'Preset Rules';

  @override
  String get customRules => 'Custom Rules';

  @override
  String get noRules => 'No rules yet';

  @override
  String get auto => 'Auto';

  @override
  String loadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String priorityLabel(int priority) {
    return 'Priority $priority';
  }

  @override
  String get normalPermission => 'Normal Permission';

  @override
  String get editRule => 'Edit Rule';

  @override
  String get newRuleTitle => 'New Rule';

  @override
  String get editRuleTitle => 'Edit Rule';

  @override
  String get save => 'Save';

  @override
  String get ruleSaved => 'Rule saved';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get ruleName => 'Rule Name';

  @override
  String get ruleNameHint => 'e.g. Clean log files';

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get description => 'Description (optional)';

  @override
  String get enableThisRule => 'Enable this rule';

  @override
  String get priority => 'Priority';

  @override
  String priorityDesc(int priority) {
    return '$priority (lower number = higher priority)';
  }

  @override
  String get scope => 'Scope';

  @override
  String pathLabel(int index) {
    return 'Path $index';
  }

  @override
  String get pathHint => '/storage/emulated/0/...';

  @override
  String get pathRequired => 'Please enter a path';

  @override
  String get addPath => 'Add Path';

  @override
  String get recursiveSubdirs => 'Recursive subdirectories';

  @override
  String get permissionEngine => 'Permission Engine';

  @override
  String get browseDirectory => 'Browse directory';

  @override
  String get matchConditions => 'Match Conditions';

  @override
  String get noConditions => 'No conditions added (will match all files)';

  @override
  String get addCondition => 'Add Condition';

  @override
  String get filenameCondition => 'Filename';

  @override
  String get extensionCondition => 'Extension';

  @override
  String get fileSizeCondition => 'File Size';

  @override
  String get modifiedTimeCondition => 'Modified Time';

  @override
  String get subfileCountCondition => 'Subfile Count';

  @override
  String get actionType => 'Action Type';

  @override
  String get deleteAction => 'Delete';

  @override
  String get shredAction => 'Shred Delete';

  @override
  String get passesCount => 'Overwrite Passes';

  @override
  String passesCountLabel(int count) {
    return '$count passes';
  }

  @override
  String get safetyPolicy => 'Safety Policy';

  @override
  String get requirePreview => 'Require preview on first run';

  @override
  String get minMatchCount => 'Minimum match count';

  @override
  String get addExcludedPath => 'Add excluded path';

  @override
  String excludedPathLabel(int index) {
    return 'Excluded path $index';
  }

  @override
  String conditionLabel(int index) {
    return 'Condition $index';
  }

  @override
  String get filenamePattern => 'Filename pattern';

  @override
  String get filenamePatternHint => '*.log';

  @override
  String get matchMode => 'Match mode';

  @override
  String get wildcardMode => 'Wildcard (*, ?)';

  @override
  String get regexMode => 'Regular Expression';

  @override
  String get containsMode => 'Contains text';

  @override
  String get exactMode => 'Exact match';

  @override
  String get extensionsLabel => 'Extensions (comma separated)';

  @override
  String get extensionsHint => 'log, tmp, txt';

  @override
  String get compareMethod => 'Compare method';

  @override
  String get greaterThan => 'Greater than';

  @override
  String get greaterThanOrEqual => 'Greater than or equal';

  @override
  String get lessThan => 'Less than';

  @override
  String get lessThanOrEqual => 'Less than or equal';

  @override
  String get equal => 'Equal';

  @override
  String get sizeInBytes => 'Size (bytes)';

  @override
  String get timeFormatHint => 'Time (e.g. 7d, 24h, 30m)';

  @override
  String get olderThan => 'Older than';

  @override
  String get newerThan => 'Newer than';

  @override
  String get subfileCountLabel => 'Subfile count';

  @override
  String get selectDirectory => 'Select Directory';

  @override
  String get goUp => 'Go up';

  @override
  String get thisDirectoryIsEmpty => 'This directory is empty';

  @override
  String get selectThisDirectory => 'Select this directory';

  @override
  String loadDirectoryFailed(String error) {
    return 'Failed to read directory: $error';
  }

  @override
  String get pleaseAddAtLeastOnePath => 'Please add at least one path';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get permissionStatus => 'Permission';

  @override
  String get storagePermission => 'Storage Permission';

  @override
  String get fullAccessGranted => 'Full access granted';

  @override
  String get partialAccess => 'Partial access only';

  @override
  String get notGranted => 'Not granted';

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get checkingPermission => 'Checking permission...';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get avoidBatteryKill => 'Avoid being killed by system';

  @override
  String get systemInfo => 'System Info';

  @override
  String get systemType => 'System Type';

  @override
  String get detecting => 'Detecting...';

  @override
  String get cannotDetect => 'Cannot detect';

  @override
  String get version => 'Version';

  @override
  String get dataSection => 'Data';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get clearLogsDesc => 'Delete all cleanup history records';

  @override
  String get confirmClearLogsTitle => 'Confirm Clear';

  @override
  String get confirmClearLogsMessage =>
      'This action cannot be undone. Are you sure you want to clear all logs?';

  @override
  String get logsCleared => 'Logs cleared';

  @override
  String get cannotCheckPermission => 'Cannot check permission';

  @override
  String get autoTaskTitle => 'Auto Clean';

  @override
  String get newAutoTask => 'New Auto Task';

  @override
  String get editAutoTask => 'Edit Auto Task';

  @override
  String get newTask => 'New Task';

  @override
  String get taskName => 'Task Name';

  @override
  String get taskNameRequired => 'Please enter a task name';

  @override
  String get selectRules => 'Select Rules';

  @override
  String get selectRulesRequired => 'Please select at least one rule';

  @override
  String get executionPeriod => 'Execution Period';

  @override
  String get executionTime => 'Execution Time';

  @override
  String get onlyWhenCharging => 'Only when charging';

  @override
  String get minBatteryLevel => 'Minimum battery level';

  @override
  String get requirePreviewConfirm => 'Require preview confirmation';

  @override
  String get previewConfirmDesc =>
      'Notify and wait for confirmation before each execution';

  @override
  String get useForegroundService => 'Use foreground service';

  @override
  String get foregroundServiceDesc =>
      'Improve execution reliability on custom ROMs';

  @override
  String get saveTask => 'Save Task';

  @override
  String get taskSaved => 'Auto task saved';

  @override
  String get noAutoTasks => 'No auto clean tasks configured';

  @override
  String get daily => 'Daily';

  @override
  String get every3Days => 'Every 3 days';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String periodLabel(String period, String time) {
    return 'Period: $period · $time';
  }

  @override
  String nFiles(int count) {
    return '$count files';
  }

  @override
  String get executionAction => 'Execution Action';

  @override
  String get deleteRuleTitle => 'Delete Rule';

  @override
  String deleteRuleMessage(String name) {
    return 'Are you sure you want to delete the rule \"$name\"?';
  }

  @override
  String get ruleDeleted => 'Rule deleted';

  @override
  String deletedFilesTitle(int count) {
    return 'Deleted Files ($count)';
  }

  @override
  String get noDeletedFilesDetail => 'No file details available';
}
