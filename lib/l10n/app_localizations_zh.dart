// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'XClean';

  @override
  String get storagePermissionRequired => 'XClean 需要访问所有文件才能执行清理';

  @override
  String get grantPermission => '授权';

  @override
  String get storagePermissionNeeded => '需要存储权限';

  @override
  String get oneKeyScan => '一键扫描';

  @override
  String get ruleManagement => '规则管理';

  @override
  String get autoClean => '自动清理';

  @override
  String get largeFiles => '大文件';

  @override
  String get quickActions => '快捷操作';

  @override
  String get enabledRules => '已启用规则';

  @override
  String get viewAll => '查看全部';

  @override
  String get recentCleanups => '最近清理';

  @override
  String get available => '可用';

  @override
  String get used => '已用';

  @override
  String get total => '总计';

  @override
  String get scanning => '扫描中...';

  @override
  String get noEnabledRules => '没有启用的规则，请先启用规则';

  @override
  String get noMatchedFiles => '没有匹配到可清理的文件';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String moreRules(int count) {
    return '还有 $count 条规则...';
  }

  @override
  String storageInfoError(String error) {
    return '无法获取存储信息: $error';
  }

  @override
  String romDetected(String rom) {
    return '检测到系统: $rom';
  }

  @override
  String get settings => '设置';

  @override
  String get thumbnailCache => '缩略图缓存';

  @override
  String get thumbnailCacheDesc => '清理 .thumbnails 目录中的图片缓存';

  @override
  String get emptyFolders => '空文件夹';

  @override
  String get emptyFoldersDesc => '递归清理空目录';

  @override
  String get downloadTempFiles => '下载临时文件';

  @override
  String get downloadTempFilesDesc => '清理下载目录中的临时文件';

  @override
  String get logFiles => '日志文件';

  @override
  String get logFilesDesc => '清理应用日志文件';

  @override
  String get appResidual => '应用残留';

  @override
  String get appResidualDesc => '清理已卸载应用的残留目录';

  @override
  String get cleanPreview => '清理预览';

  @override
  String get selectAll => '全选';

  @override
  String get selectNone => '全不选';

  @override
  String selectedCount(int selected, int total) {
    return '已选择 $selected / $total 个文件';
  }

  @override
  String releasable(String size) {
    return '可释放 $size';
  }

  @override
  String get noMatchedFilesPreview => '没有匹配的文件';

  @override
  String get directory => '目录';

  @override
  String get cancel => '取消';

  @override
  String cleanWithSize(String size) {
    return '清理 ($size)';
  }

  @override
  String get cleaning => '正在清理...';

  @override
  String get cleanComplete => '清理完成';

  @override
  String releasedSpace(String size) {
    return '释放空间: $size';
  }

  @override
  String fileCount(int count) {
    return '文件数量: $count';
  }

  @override
  String successFailCount(int success, int fail) {
    return '成功: $success  失败: $fail';
  }

  @override
  String duration(String duration) {
    return '耗时: $duration';
  }

  @override
  String cleanFailed(String error) {
    return '清理失败: $error';
  }

  @override
  String get confirm => '确定';

  @override
  String get largeFileAnalysis => '大文件分析';

  @override
  String minFileSize(int size) {
    return '最小文件大小: $size MB';
  }

  @override
  String get sortBySize => '按大小排序';

  @override
  String get sortByTime => '按时间排序';

  @override
  String get sortByName => '按名称排序';

  @override
  String get noLargeFiles => '没有找到符合条件的大文件';

  @override
  String get videoThumbnailError => '视频缩略图不可用';

  @override
  String scanFailed(String error) {
    return '扫描失败: $error';
  }

  @override
  String get deleteThisFile => '删除此文件';

  @override
  String get deleted => '已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get viewDirectory => '查看所在目录';

  @override
  String get ruleListTitle => '清理规则';

  @override
  String get newRule => '新建规则';

  @override
  String get presetRules => '预设规则';

  @override
  String get customRules => '自定义规则';

  @override
  String get noRules => '暂无规则';

  @override
  String get auto => '自动';

  @override
  String loadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String priorityLabel(int priority) {
    return '优先级 $priority';
  }

  @override
  String get normalPermission => '普通权限';

  @override
  String get editRule => '编辑规则';

  @override
  String get newRuleTitle => '新建规则';

  @override
  String get editRuleTitle => '编辑规则';

  @override
  String get save => '保存';

  @override
  String get ruleSaved => '规则已保存';

  @override
  String get basicInfo => '基本信息';

  @override
  String get ruleName => '规则名称';

  @override
  String get ruleNameHint => '例如：清理日志文件';

  @override
  String get nameRequired => '请输入名称';

  @override
  String get description => '描述（可选）';

  @override
  String get enableThisRule => '启用此规则';

  @override
  String get priority => '优先级';

  @override
  String priorityDesc(int priority) {
    return '$priority（数字越小优先级越高）';
  }

  @override
  String get scope => '作用范围';

  @override
  String pathLabel(int index) {
    return '路径 $index';
  }

  @override
  String get pathHint => '/storage/emulated/0/...';

  @override
  String get pathRequired => '请输入路径';

  @override
  String get addPath => '添加路径';

  @override
  String get recursiveSubdirs => '递归子目录';

  @override
  String get permissionEngine => '权限引擎';

  @override
  String get browseDirectory => '浏览目录';

  @override
  String get matchConditions => '匹配条件';

  @override
  String get noConditions => '未添加条件（将匹配所有文件）';

  @override
  String get addCondition => '添加条件';

  @override
  String get filenameCondition => '文件名';

  @override
  String get extensionCondition => '扩展名';

  @override
  String get fileSizeCondition => '文件大小';

  @override
  String get modifiedTimeCondition => '修改时间';

  @override
  String get subfileCountCondition => '子文件数量';

  @override
  String get actionType => '动作类型';

  @override
  String get deleteAction => '删除';

  @override
  String get shredAction => '粉碎删除';

  @override
  String get passesCount => '覆写次数';

  @override
  String passesCountLabel(int count) {
    return '$count 次';
  }

  @override
  String get safetyPolicy => '安全策略';

  @override
  String get requirePreview => '首次执行要求预览';

  @override
  String get minMatchCount => '最少匹配数量';

  @override
  String get addExcludedPath => '添加排除路径';

  @override
  String excludedPathLabel(int index) {
    return '排除路径 $index';
  }

  @override
  String conditionLabel(int index) {
    return '条件 $index';
  }

  @override
  String get filenamePattern => '文件名模式';

  @override
  String get filenamePatternHint => '*.log';

  @override
  String get matchMode => '匹配模式';

  @override
  String get wildcardMode => '通配符 (*, ?)';

  @override
  String get regexMode => '正则表达式';

  @override
  String get containsMode => '包含文本';

  @override
  String get exactMode => '精确匹配';

  @override
  String get extensionsLabel => '扩展名（逗号分隔）';

  @override
  String get extensionsHint => 'log, tmp, txt';

  @override
  String get compareMethod => '比较方式';

  @override
  String get greaterThan => '大于';

  @override
  String get greaterThanOrEqual => '大于等于';

  @override
  String get lessThan => '小于';

  @override
  String get lessThanOrEqual => '小于等于';

  @override
  String get equal => '等于';

  @override
  String get sizeInBytes => '大小（字节）';

  @override
  String get timeFormatHint => '时间（如 7d, 24h, 30m）';

  @override
  String get olderThan => '早于';

  @override
  String get newerThan => '晚于';

  @override
  String get subfileCountLabel => '子文件数量';

  @override
  String get selectDirectory => '选择目录';

  @override
  String get goUp => '上级目录';

  @override
  String get thisDirectoryIsEmpty => '此目录为空';

  @override
  String get selectThisDirectory => '选择此目录';

  @override
  String loadDirectoryFailed(String error) {
    return '读取目录失败: $error';
  }

  @override
  String get pleaseAddAtLeastOnePath => '请至少添加一个路径';

  @override
  String get settingsTitle => '设置';

  @override
  String get permissionStatus => '权限';

  @override
  String get storagePermission => '存储权限';

  @override
  String get fullAccessGranted => '已授权全部文件访问';

  @override
  String get partialAccess => '仅部分授权';

  @override
  String get notGranted => '未授权';

  @override
  String get unknownStatus => '未知';

  @override
  String get checkingPermission => '检查权限中...';

  @override
  String get batteryOptimization => '电池优化';

  @override
  String get avoidBatteryKill => '避免被系统后台清理';

  @override
  String get systemInfo => '系统信息';

  @override
  String get systemType => '系统类型';

  @override
  String get detecting => '检测中...';

  @override
  String get cannotDetect => '无法检测';

  @override
  String get version => '版本';

  @override
  String get dataSection => '数据';

  @override
  String get clearLogs => '清空日志';

  @override
  String get clearLogsDesc => '删除所有清理历史记录';

  @override
  String get confirmClearLogsTitle => '确认清空';

  @override
  String get confirmClearLogsMessage => '此操作不可恢复，确定要清空所有日志吗？';

  @override
  String get logsCleared => '日志已清空';

  @override
  String get cannotCheckPermission => '无法检查权限';

  @override
  String get autoTaskTitle => '自动清理';

  @override
  String get newAutoTask => '新建自动任务';

  @override
  String get editAutoTask => '编辑自动任务';

  @override
  String get newTask => '新建任务';

  @override
  String get taskName => '任务名称';

  @override
  String get taskNameRequired => '请输入任务名称';

  @override
  String get selectRules => '选择规则';

  @override
  String get selectRulesRequired => '请至少选择一条规则';

  @override
  String get executionPeriod => '执行周期';

  @override
  String get executionTime => '执行时间';

  @override
  String get onlyWhenCharging => '仅充电时执行';

  @override
  String get minBatteryLevel => '最低电量';

  @override
  String get requirePreviewConfirm => '要求预览确认';

  @override
  String get previewConfirmDesc => '每次执行前通知并等待确认';

  @override
  String get useForegroundService => '使用前台服务保活';

  @override
  String get foregroundServiceDesc => '提升国产 ROM 上的执行可靠性';

  @override
  String get saveTask => '保存任务';

  @override
  String get taskSaved => '自动任务已保存';

  @override
  String get noAutoTasks => '没有配置自动清理任务';

  @override
  String get daily => '每天';

  @override
  String get every3Days => '每3天';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String periodLabel(String period, String time) {
    return '周期: $period · $time';
  }

  @override
  String nFiles(int count) {
    return '$count 个文件';
  }

  @override
  String get executionAction => '执行动作';

  @override
  String get deleteRuleTitle => '删除规则';

  @override
  String deleteRuleMessage(String name) {
    return '确定要删除规则 \"$name\" 吗？';
  }

  @override
  String get ruleDeleted => '规则已删除';

  @override
  String deletedFilesTitle(int count) {
    return '已删除文件 ($count)';
  }

  @override
  String get noDeletedFilesDetail => '没有可用的文件详情';
}
