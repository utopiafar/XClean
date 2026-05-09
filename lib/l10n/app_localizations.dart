import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'XClean'**
  String get appName;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'XClean needs access to all files to perform cleanup'**
  String get storagePermissionRequired;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grantPermission;

  /// No description provided for @storagePermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required'**
  String get storagePermissionNeeded;

  /// No description provided for @oneKeyScan.
  ///
  /// In en, this message translates to:
  /// **'One-Key Scan'**
  String get oneKeyScan;

  /// No description provided for @ruleManagement.
  ///
  /// In en, this message translates to:
  /// **'Rule Management'**
  String get ruleManagement;

  /// No description provided for @autoClean.
  ///
  /// In en, this message translates to:
  /// **'Auto Clean'**
  String get autoClean;

  /// No description provided for @largeFiles.
  ///
  /// In en, this message translates to:
  /// **'Large Files'**
  String get largeFiles;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @enabledRules.
  ///
  /// In en, this message translates to:
  /// **'Enabled Rules'**
  String get enabledRules;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @recentCleanups.
  ///
  /// In en, this message translates to:
  /// **'Recent Cleanups'**
  String get recentCleanups;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @noEnabledRules.
  ///
  /// In en, this message translates to:
  /// **'No enabled rules, please enable a rule first'**
  String get noEnabledRules;

  /// No description provided for @noMatchedFiles.
  ///
  /// In en, this message translates to:
  /// **'No cleanable files matched'**
  String get noMatchedFiles;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @moreRules.
  ///
  /// In en, this message translates to:
  /// **'{count} more rules...'**
  String moreRules(int count);

  /// No description provided for @storageInfoError.
  ///
  /// In en, this message translates to:
  /// **'Unable to get storage info: {error}'**
  String storageInfoError(String error);

  /// No description provided for @romDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected system: {rom}'**
  String romDetected(String rom);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @thumbnailCache.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail Cache'**
  String get thumbnailCache;

  /// No description provided for @thumbnailCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean image cache in .thumbnails directory'**
  String get thumbnailCacheDesc;

  /// No description provided for @emptyFolders.
  ///
  /// In en, this message translates to:
  /// **'Empty Folders'**
  String get emptyFolders;

  /// No description provided for @emptyFoldersDesc.
  ///
  /// In en, this message translates to:
  /// **'Recursively clean empty directories'**
  String get emptyFoldersDesc;

  /// No description provided for @downloadTempFiles.
  ///
  /// In en, this message translates to:
  /// **'Download Temp Files'**
  String get downloadTempFiles;

  /// No description provided for @downloadTempFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean temporary files in download directory'**
  String get downloadTempFilesDesc;

  /// No description provided for @logFiles.
  ///
  /// In en, this message translates to:
  /// **'Log Files'**
  String get logFiles;

  /// No description provided for @logFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean application log files'**
  String get logFilesDesc;

  /// No description provided for @appResidual.
  ///
  /// In en, this message translates to:
  /// **'App Residual'**
  String get appResidual;

  /// No description provided for @appResidualDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean residual directories of uninstalled apps'**
  String get appResidualDesc;

  /// No description provided for @apkInstallerFiles.
  ///
  /// In en, this message translates to:
  /// **'APK Installer Files'**
  String get apkInstallerFiles;

  /// No description provided for @apkInstallerFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean leftover APK installer packages in download directory'**
  String get apkInstallerFilesDesc;

  /// No description provided for @cleanPreview.
  ///
  /// In en, this message translates to:
  /// **'Clean Preview'**
  String get cleanPreview;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'Select None'**
  String get selectNone;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected {selected} / {total} files'**
  String selectedCount(int selected, int total);

  /// No description provided for @releasable.
  ///
  /// In en, this message translates to:
  /// **'Releasable {size}'**
  String releasable(String size);

  /// No description provided for @noMatchedFilesPreview.
  ///
  /// In en, this message translates to:
  /// **'No matched files'**
  String get noMatchedFilesPreview;

  /// No description provided for @directory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cleanWithSize.
  ///
  /// In en, this message translates to:
  /// **'Clean ({size})'**
  String cleanWithSize(String size);

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning...'**
  String get cleaning;

  /// No description provided for @cleanComplete.
  ///
  /// In en, this message translates to:
  /// **'Clean Complete'**
  String get cleanComplete;

  /// No description provided for @cleanFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean Failed'**
  String get cleanFailedTitle;

  /// No description provided for @cleanPartialSuccess.
  ///
  /// In en, this message translates to:
  /// **'Partially Cleaned'**
  String get cleanPartialSuccess;

  /// No description provided for @releasedSpace.
  ///
  /// In en, this message translates to:
  /// **'Released space: {size}'**
  String releasedSpace(String size);

  /// No description provided for @fileCount.
  ///
  /// In en, this message translates to:
  /// **'File count: {count}'**
  String fileCount(int count);

  /// No description provided for @successFailCount.
  ///
  /// In en, this message translates to:
  /// **'Success: {success}  Fail: {fail}'**
  String successFailCount(int success, int fail);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration(String duration);

  /// No description provided for @cleanFailed.
  ///
  /// In en, this message translates to:
  /// **'Clean failed: {error}'**
  String cleanFailed(String error);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @largeFileAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Large File Analysis'**
  String get largeFileAnalysis;

  /// No description provided for @minFileSize.
  ///
  /// In en, this message translates to:
  /// **'Min file size: {size} MB'**
  String minFileSize(int size);

  /// No description provided for @sortBySize.
  ///
  /// In en, this message translates to:
  /// **'Sort by size'**
  String get sortBySize;

  /// No description provided for @sortByTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by time'**
  String get sortByTime;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get sortByName;

  /// No description provided for @noLargeFiles.
  ///
  /// In en, this message translates to:
  /// **'No large files found matching criteria'**
  String get noLargeFiles;

  /// No description provided for @videoThumbnailError.
  ///
  /// In en, this message translates to:
  /// **'Video thumbnail unavailable'**
  String get videoThumbnailError;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String scanFailed(String error);

  /// No description provided for @deleteThisFile.
  ///
  /// In en, this message translates to:
  /// **'Delete this file'**
  String get deleteThisFile;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @viewDirectory.
  ///
  /// In en, this message translates to:
  /// **'View directory'**
  String get viewDirectory;

  /// No description provided for @ruleListTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean Rules'**
  String get ruleListTitle;

  /// No description provided for @newRule.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get newRule;

  /// No description provided for @presetRules.
  ///
  /// In en, this message translates to:
  /// **'Preset Rules'**
  String get presetRules;

  /// No description provided for @customRules.
  ///
  /// In en, this message translates to:
  /// **'Custom Rules'**
  String get customRules;

  /// No description provided for @noRules.
  ///
  /// In en, this message translates to:
  /// **'No rules yet'**
  String get noRules;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailed(String error);

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority {priority}'**
  String priorityLabel(int priority);

  /// No description provided for @normalPermission.
  ///
  /// In en, this message translates to:
  /// **'Normal Permission'**
  String get normalPermission;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get editRule;

  /// No description provided for @newRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get newRuleTitle;

  /// No description provided for @editRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get editRuleTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ruleSaved.
  ///
  /// In en, this message translates to:
  /// **'Rule saved'**
  String get ruleSaved;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @ruleName.
  ///
  /// In en, this message translates to:
  /// **'Rule Name'**
  String get ruleName;

  /// No description provided for @ruleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Clean log files'**
  String get ruleNameHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description;

  /// No description provided for @enableThisRule.
  ///
  /// In en, this message translates to:
  /// **'Enable this rule'**
  String get enableThisRule;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityDesc.
  ///
  /// In en, this message translates to:
  /// **'{priority} (lower number = higher priority)'**
  String priorityDesc(int priority);

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scope;

  /// No description provided for @pathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path {index}'**
  String pathLabel(int index);

  /// No description provided for @pathHint.
  ///
  /// In en, this message translates to:
  /// **'/storage/emulated/0/...'**
  String get pathHint;

  /// No description provided for @pathRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a path'**
  String get pathRequired;

  /// No description provided for @addPath.
  ///
  /// In en, this message translates to:
  /// **'Add Path'**
  String get addPath;

  /// No description provided for @recursiveSubdirs.
  ///
  /// In en, this message translates to:
  /// **'Recursive subdirectories'**
  String get recursiveSubdirs;

  /// No description provided for @permissionEngine.
  ///
  /// In en, this message translates to:
  /// **'Permission Engine'**
  String get permissionEngine;

  /// No description provided for @browseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Browse directory'**
  String get browseDirectory;

  /// No description provided for @matchConditions.
  ///
  /// In en, this message translates to:
  /// **'Match Conditions'**
  String get matchConditions;

  /// No description provided for @noConditions.
  ///
  /// In en, this message translates to:
  /// **'No conditions added (will match all files)'**
  String get noConditions;

  /// No description provided for @addCondition.
  ///
  /// In en, this message translates to:
  /// **'Add Condition'**
  String get addCondition;

  /// No description provided for @filenameCondition.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get filenameCondition;

  /// No description provided for @extensionCondition.
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get extensionCondition;

  /// No description provided for @fileSizeCondition.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSizeCondition;

  /// No description provided for @modifiedTimeCondition.
  ///
  /// In en, this message translates to:
  /// **'Modified Time'**
  String get modifiedTimeCondition;

  /// No description provided for @subfileCountCondition.
  ///
  /// In en, this message translates to:
  /// **'Subfile Count'**
  String get subfileCountCondition;

  /// No description provided for @actionType.
  ///
  /// In en, this message translates to:
  /// **'Action Type'**
  String get actionType;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @shredAction.
  ///
  /// In en, this message translates to:
  /// **'Shred Delete'**
  String get shredAction;

  /// No description provided for @passesCount.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Passes'**
  String get passesCount;

  /// No description provided for @passesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} passes'**
  String passesCountLabel(int count);

  /// No description provided for @safetyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Safety Policy'**
  String get safetyPolicy;

  /// No description provided for @requirePreview.
  ///
  /// In en, this message translates to:
  /// **'Require preview on first run'**
  String get requirePreview;

  /// No description provided for @minMatchCount.
  ///
  /// In en, this message translates to:
  /// **'Minimum match count'**
  String get minMatchCount;

  /// No description provided for @addExcludedPath.
  ///
  /// In en, this message translates to:
  /// **'Add excluded path'**
  String get addExcludedPath;

  /// No description provided for @excludedPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Excluded path {index}'**
  String excludedPathLabel(int index);

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition {index}'**
  String conditionLabel(int index);

  /// No description provided for @filenamePattern.
  ///
  /// In en, this message translates to:
  /// **'Filename pattern'**
  String get filenamePattern;

  /// No description provided for @filenamePatternHint.
  ///
  /// In en, this message translates to:
  /// **'*.log'**
  String get filenamePatternHint;

  /// No description provided for @matchMode.
  ///
  /// In en, this message translates to:
  /// **'Match mode'**
  String get matchMode;

  /// No description provided for @wildcardMode.
  ///
  /// In en, this message translates to:
  /// **'Wildcard (*, ?)'**
  String get wildcardMode;

  /// No description provided for @regexMode.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get regexMode;

  /// No description provided for @containsMode.
  ///
  /// In en, this message translates to:
  /// **'Contains text'**
  String get containsMode;

  /// No description provided for @exactMode.
  ///
  /// In en, this message translates to:
  /// **'Exact match'**
  String get exactMode;

  /// No description provided for @extensionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Extensions (comma separated)'**
  String get extensionsLabel;

  /// No description provided for @extensionsHint.
  ///
  /// In en, this message translates to:
  /// **'log, tmp, txt'**
  String get extensionsHint;

  /// No description provided for @compareMethod.
  ///
  /// In en, this message translates to:
  /// **'Compare method'**
  String get compareMethod;

  /// No description provided for @greaterThan.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get greaterThan;

  /// No description provided for @greaterThanOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Greater than or equal'**
  String get greaterThanOrEqual;

  /// No description provided for @lessThan.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get lessThan;

  /// No description provided for @lessThanOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Less than or equal'**
  String get lessThanOrEqual;

  /// No description provided for @equal.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get equal;

  /// No description provided for @sizeInBytes.
  ///
  /// In en, this message translates to:
  /// **'Size (bytes)'**
  String get sizeInBytes;

  /// No description provided for @timeFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Time (e.g. 7d, 24h, 30m)'**
  String get timeFormatHint;

  /// No description provided for @olderThan.
  ///
  /// In en, this message translates to:
  /// **'Older than'**
  String get olderThan;

  /// No description provided for @newerThan.
  ///
  /// In en, this message translates to:
  /// **'Newer than'**
  String get newerThan;

  /// No description provided for @subfileCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Subfile count'**
  String get subfileCountLabel;

  /// No description provided for @selectDirectory.
  ///
  /// In en, this message translates to:
  /// **'Select Directory'**
  String get selectDirectory;

  /// No description provided for @goUp.
  ///
  /// In en, this message translates to:
  /// **'Go up'**
  String get goUp;

  /// No description provided for @thisDirectoryIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This directory is empty'**
  String get thisDirectoryIsEmpty;

  /// No description provided for @selectThisDirectory.
  ///
  /// In en, this message translates to:
  /// **'Select this directory'**
  String get selectThisDirectory;

  /// No description provided for @loadDirectoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read directory: {error}'**
  String loadDirectoryFailed(String error);

  /// No description provided for @pleaseAddAtLeastOnePath.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one path'**
  String get pleaseAddAtLeastOnePath;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @permissionStatus.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permissionStatus;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storagePermission;

  /// No description provided for @fullAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Full access granted'**
  String get fullAccessGranted;

  /// No description provided for @partialAccess.
  ///
  /// In en, this message translates to:
  /// **'Partial access only'**
  String get partialAccess;

  /// No description provided for @notGranted.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get notGranted;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownStatus;

  /// No description provided for @checkingPermission.
  ///
  /// In en, this message translates to:
  /// **'Checking permission...'**
  String get checkingPermission;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @avoidBatteryKill.
  ///
  /// In en, this message translates to:
  /// **'Avoid being killed by system'**
  String get avoidBatteryKill;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Info'**
  String get systemInfo;

  /// No description provided for @systemType.
  ///
  /// In en, this message translates to:
  /// **'System Type'**
  String get systemType;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @cannotDetect.
  ///
  /// In en, this message translates to:
  /// **'Cannot detect'**
  String get cannotDetect;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @viewLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse all cleanup history'**
  String get viewLogsDesc;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @clearLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete all cleanup history records'**
  String get clearLogsDesc;

  /// No description provided for @confirmClearLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get confirmClearLogsTitle;

  /// No description provided for @confirmClearLogsMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Are you sure you want to clear all logs?'**
  String get confirmClearLogsMessage;

  /// No description provided for @logsCleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// No description provided for @cannotCheckPermission.
  ///
  /// In en, this message translates to:
  /// **'Cannot check permission'**
  String get cannotCheckPermission;

  /// No description provided for @autoTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Clean'**
  String get autoTaskTitle;

  /// No description provided for @newAutoTask.
  ///
  /// In en, this message translates to:
  /// **'New Auto Task'**
  String get newAutoTask;

  /// No description provided for @editAutoTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Auto Task'**
  String get editAutoTask;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskName;

  /// No description provided for @taskNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task name'**
  String get taskNameRequired;

  /// No description provided for @selectRules.
  ///
  /// In en, this message translates to:
  /// **'Select Rules'**
  String get selectRules;

  /// No description provided for @selectRulesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one rule'**
  String get selectRulesRequired;

  /// No description provided for @executionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Execution Period'**
  String get executionPeriod;

  /// No description provided for @executionTime.
  ///
  /// In en, this message translates to:
  /// **'Execution Time'**
  String get executionTime;

  /// No description provided for @onlyWhenCharging.
  ///
  /// In en, this message translates to:
  /// **'Only when charging'**
  String get onlyWhenCharging;

  /// No description provided for @minBatteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Minimum battery level'**
  String get minBatteryLevel;

  /// No description provided for @requirePreviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Require preview confirmation'**
  String get requirePreviewConfirm;

  /// No description provided for @previewConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify and wait for confirmation before each execution'**
  String get previewConfirmDesc;

  /// No description provided for @useForegroundService.
  ///
  /// In en, this message translates to:
  /// **'Use foreground service'**
  String get useForegroundService;

  /// No description provided for @foregroundServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Improve execution reliability on custom ROMs'**
  String get foregroundServiceDesc;

  /// No description provided for @saveTask.
  ///
  /// In en, this message translates to:
  /// **'Save Task'**
  String get saveTask;

  /// No description provided for @taskSaved.
  ///
  /// In en, this message translates to:
  /// **'Auto task saved'**
  String get taskSaved;

  /// No description provided for @noAutoTasks.
  ///
  /// In en, this message translates to:
  /// **'No auto clean tasks configured'**
  String get noAutoTasks;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @every3Days.
  ///
  /// In en, this message translates to:
  /// **'Every 3 days'**
  String get every3Days;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period: {period} · {time}'**
  String periodLabel(String period, String time);

  /// No description provided for @nFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String nFiles(int count);

  /// No description provided for @executionAction.
  ///
  /// In en, this message translates to:
  /// **'Execution Action'**
  String get executionAction;

  /// No description provided for @deleteRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Rule'**
  String get deleteRuleTitle;

  /// No description provided for @deleteRuleMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the rule \"{name}\"?'**
  String deleteRuleMessage(String name);

  /// No description provided for @ruleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Rule deleted'**
  String get ruleDeleted;

  /// No description provided for @deletedFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted Files ({count})'**
  String deletedFilesTitle(int count);

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No cleanup history yet'**
  String get noLogs;

  /// No description provided for @noDeletedFilesDetail.
  ///
  /// In en, this message translates to:
  /// **'No file details available'**
  String get noDeletedFilesDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
