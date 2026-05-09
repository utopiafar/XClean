# XClean

<p align="center">
  <b>一个轻量、强大、注重隐私的 Android 文件清理工具。</b><br>
  无广告。无追踪。开源。
</p>

<p align="center">
  <a href="https://github.com/utopiafar/XClean/releases">
    <img src="https://img.shields.io/github/v/release/utopiafar/XClean?include_prereleases" alt="Release">
  </a>
  <a href="https://github.com/utopiafar/XClean/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/utopiafar/XClean" alt="License">
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.41+-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Android-API_26+-green.svg" alt="Android">
</p>

---

> 🇺🇸 [English README](README.md)

## 为什么选择 XClean？

市面上大多数"清理大师"类应用充斥着广告、激进的付费推销和过度索取的权限。**XClean** 选择了另一条路：

- **基于规则的清理** — 精确定义清理什么、何时清理。
- **删除前预览** — 每个文件删除前都可查看，绝不误删重要内容。
- **无广告、无追踪** — 你的数据只存在于你的设备上。
- **开源透明** — 代码完全公开，可审计、可分叉、可贡献。
- **轻量无负担** — 极低的资源占用，没有后台臃肿服务。

---

## 功能特性

### 核心清理
| 功能 | 说明 |
|------|------|
| 🔍 **一键扫描** | 使用所有已启用规则扫描，清理前预览结果 |
| 📋 **规则系统** | 灵活的规则，支持作用范围、条件（文件名、扩展名、大小、修改时间、子文件数）和动作 |
| 🗑️ **预览与选择** | 网格预览，支持图片和视频缩略图；批量全选/全不选 |
| 📁 **预设规则** | 缩略图缓存、空文件夹、下载临时文件、日志文件、应用残留、APK 安装包 |
| ✏️ **自定义规则** | 创建你自己的规则，自定义路径、条件和引擎 |
| 🕒 **自动清理任务** | 周期性定时清理，支持自定义条件 |

### 分析工具
| 功能 | 说明 |
|------|------|
| 📊 **存储概览** | 环形图直观展示已用/可用空间 |
| 🐘 **大文件分析** | 按大小阈值查找大文件（默认 500MB，可调 100MB–5GB） |
| 📝 **清理历史** | 详细日志，包含删除文件名、释放空间和执行时间 |
| 🔧 **规则管理** | 启用/禁用规则、编辑优先级、切换引擎（普通/Shizuku/Root） |

### 高级功能
| 功能 | 说明 |
|------|------|
| 🎬 **视频缩略图** | 基于 Android 原生 MediaMetadataRetriever，支持 MP4/MKV/AVI/MOV 等预览 |
| 🛡️ **安全策略** | 最少匹配数、排除路径、首次执行要求预览 |
| 🔌 **多引擎** | 普通（标准文件系统）、Shizuku（ADB 级别）、Root（超级用户） |
| 🌍 **双语支持** | 简体中文 & English（通过 ARB + flutter_localizations） |

---

## 技术栈

| 层级 | 技术 |
|------|------|
| **框架** | Flutter 3.41+ / Dart 3.11+ |
| **状态管理** | flutter_riverpod |
| **数据库** | Drift (SQLite) + drift_flutter |
| **路由** | go_router |
| **序列化** | freezed + json_serializable |
| **权限** | permission_handler (MANAGE_EXTERNAL_STORAGE) |
| **后台任务** | WorkManager (Android) |
| **通知** | flutter_local_notifications |
| **原生桥接** | MethodChannel + EventChannel (Kotlin) |

---

## 安装

### 系统要求
- Android 8.0+ (API 26+)
- `MANAGE_EXTERNAL_STORAGE` 权限（用于访问完整 SD 卡）

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/utopiafar/XClean.git
cd XClean

# 安装依赖
flutter pub get

# 生成代码（freezed、drift、json_serializable、l10n）
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

# 构建调试 APK
flutter build apk --debug

# 构建发布 APK
flutter build apk --release
```

### 预编译 APK
从 [GitHub Releases](https://github.com/utopiafar/XClean/releases) 下载最新版本。

---

## 项目架构

```
lib/
├── core/           # 工具类（规则匹配器、大小格式化、本地化）
├── data/
│   ├── local/      # Drift 数据库（SQLite）
│   └── repositories/
├── domain/         # 实体（CleanRule、CleanLog、CleanResult）
├── platform/       # MethodChannel（文件、权限、后台）
├── presentation/
│   ├── providers/  # Riverpod 状态管理
│   ├── screens/    # UI 页面
│   └── widgets/    # 可复用组件
└── routing/        # go_router 路由配置
```

### 清理流程

```
用户点击"一键扫描"
    ↓
ScanNotifier.scanWithRules(已启用规则)
    ↓
对每个规则 → FileChannel.scanPath（Kotlin 原生扫描）
    ↓
Dart 规则匹配器过滤结果
    ↓
PreviewScreen 以网格展示匹配文件
    ↓
用户选择文件 → 点击"清理"
    ↓
FileChannel.deleteFiles(paths) + 写入数据库日志
    ↓
显示完成弹窗 + 刷新首页
```

---

## 测试

```bash
# 运行全部测试
flutter test

# 运行指定测试套件
flutter test test/core/utils/rule_matcher_test.dart
flutter test test/presentation/screens/
```

当前测试覆盖：
- ✅ 规则匹配器（30+ 种条件）
- ✅ 视频/图片文件类型检测
- ✅ 大文件过滤逻辑
- ✅ 日志详情解析
- ✅ Rule List、Preview、Large File 页面 Widget 测试

---

## 参与贡献

欢迎提交贡献！请先阅读 [Contributing Guide](CONTRIBUTING.md)（即将推出），然后提交 PR。

### 开发环境搭建

1. Fork 并克隆仓库
2. 运行 `flutter pub get`
3. 运行 `flutter gen-l10n` 生成本地化文件
4. 运行 `dart run build_runner build` 生成 freezed/drift 代码
5. 打开 Android 模拟器或连接已授予 `MANAGE_EXTERNAL_STORAGE` 权限的设备

### 代码规范
- 遵循现有 Flutter/Dart 编码风格
- 提交前运行 `flutter analyze`
- 新功能需附带测试

---

## 致谢

本项目深受以下优秀清理应用的启发：
- **SD Maid** — 深度清理理念和基于规则的清理方式
- **Files by Google** — 简洁、无干扰的界面设计
- **CCleaner** — 全面的系统监控概念

---

## 许可证

[MIT License](LICENSE) © UtopiaFar

---

<p align="center">
  使用 Flutter 构建 ❤️
</p>
