# XClean

<p align="center">
  <img src="assets/icon.png" width="120" alt="XClean Logo">
</p>

<p align="center">
  <b>A lightweight, powerful, and privacy-focused file cleaner for Android.</b><br>
  No ads. No tracking. Open source.
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

## Why XClean?

Most "cleaner" apps on the Play Store are bloated with ads, aggressive upselling, and excessive permissions. **XClean** takes a different approach:

- **Rule-based cleaning** – Define exactly what gets cleaned and when.
- **Preview before delete** – See every file before it's removed. Never accidentally delete something important.
- **No ads, no tracking** – Your data stays on your device.
- **Open source** – Fully transparent. Audit the code, fork it, contribute.
- **Lightweight** – Minimal resource usage, no background bloat.

---

## Features

### Core Cleaning
| Feature | Description |
|---------|-------------|
| 🔍 **One-Key Scan** | Scan with all enabled rules and preview results before cleaning |
| 📋 **Rule System** | Flexible rules with scope, conditions (filename, extension, size, modified time, subfile count), and actions |
| 🗑️ **Preview & Select** | Grid preview with thumbnails for images and videos; bulk select/deselect |
| 📁 **Preset Rules** | Thumbnail cache, empty folders, download temp files, log files, app residual |
| ✏️ **Custom Rules** | Create your own rules with custom paths, conditions, and engines |
| 🕒 **Auto Clean Tasks** | Schedule periodic cleaning with customizable conditions |

### Analysis Tools
| Feature | Description |
|---------|-------------|
| 📊 **Storage Overview** | Visual ring chart showing used/available space |
| 🐘 **Large File Analysis** | Find files by size threshold (default 500MB, adjustable 100MB–5GB) |
| 📝 **Cleanup History** | Detailed logs with deleted file names, freed space, and execution time |
| 🔧 **Rule Management** | Enable/disable rules, edit priorities, switch engines (Normal/Shizuku/Root) |

### Advanced
| Feature | Description |
|---------|-------------|
| 🎬 **Video Thumbnails** | Native Android MediaMetadataRetriever for MP4/MKV/AVI/MOV preview |
| 🛡️ **Safety Policy** | Minimum match count, excluded paths, require-preview-on-first-run |
| 🔌 **Multi-Engine** | Normal (standard FS), Shizuku (ADB-level), Root (superuser) |
| 🌍 **Bilingual** | English & 简体中文 (via ARB + flutter_localizations) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.41+ / Dart 3.11+ |
| **State Management** | flutter_riverpod |
| **Database** | Drift (SQLite) + drift_flutter |
| **Routing** | go_router |
| **Serialization** | freezed + json_serializable |
| **Permissions** | permission_handler (MANAGE_EXTERNAL_STORAGE) |
| **Background Tasks** | WorkManager (Android) |
| **Notifications** | flutter_local_notifications |
| **Native Bridge** | MethodChannel + EventChannel (Kotlin) |

---

## Installation

### Requirements
- Android 8.0+ (API 26+)
- `MANAGE_EXTERNAL_STORAGE` permission (for full SD card access)

### Build from Source

```bash
# Clone
git clone https://github.com/utopiafar/XClean.git
cd XClean

# Install dependencies
flutter pub get

# Generate code (freezed, drift, json_serializable, l10n)
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Pre-built APK
Download the latest release from [GitHub Releases](https://github.com/utopiafar/XClean/releases).

---

## Architecture

```
lib/
├── core/           # Utilities (rule matcher, size formatter, localization)
├── data/
│   ├── local/      # Drift database (SQLite)
│   └── repositories/
├── domain/         # Entities (CleanRule, CleanLog, CleanResult)
├── platform/       # MethodChannels (File, Permission, Background)
├── presentation/
│   ├── providers/  # Riverpod providers
│   ├── screens/    # UI screens
│   └── widgets/    # Reusable widgets
└── routing/        # go_router configuration
```

### Clean Flow

```
User taps "One-Key Scan"
    ↓
ScanNotifier.scanWithRules(enabledRules)
    ↓
For each rule → FileChannel.scanPath (Kotlin native scan)
    ↓
Dart rule matcher filters results
    ↓
PreviewScreen shows grid of matched files
    ↓
User selects files → taps "Clean"
    ↓
FileChannel.deleteFiles(paths) + log to database
    ↓
Show completion dialog + refresh dashboard
```

---

## Roadmap

Based on research of top Android cleaners (CCleaner, SD Maid, Files by Google, Avast Cleanup), here are planned features:

### Short Term
- [ ] **Duplicate File Finder** – Detect duplicate images/videos/documents regardless of name or location
- [ ] **Storage Analyzer** – Tree-map / sunburst visualization of storage by directory
- [ ] **APK Installer Cleanup** – Scan and list leftover APK files in Downloads
- [ ] **CorpseFinder** – Detect residual files left by uninstalled apps
- [ ] **Quick Clean Widget** – Home screen 1-tap clean widget

### Medium Term
- [ ] **Similar Photo Detection** – AI-powered grouping of similar/blurry/duplicate photos
- [ ] **App Manager** – View apps by size, last used date; batch uninstall; sort by storage hog
- [ ] **Social App Cleaners** – Dedicated cleaners for WhatsApp, Telegram, WeChat caches
- [ ] **Database Optimization** – `VACUUM`-style optimization for app databases
- [ ] **Trash / Recycle Bin** – Move deleted files to a recoverable trash folder for N days
- [ ] **Dark Theme** – Full Material 3 dynamic theming support

### Long Term
- [ ] **Cloud Backup Suggestions** – Identify files already backed up to cloud and safe to delete
- [ ] **Usage-Based Auto Clean** – Auto-clean apps not used in N days (like Files by Google)
- [ ] **Shizuku Full Integration** – Complete Shizuku engine for system-level cleaning without root
- [ ] **i18n Expansion** – Japanese, Korean, Spanish, Portuguese
- [ ] **Wear OS Companion** – Quick clean trigger from smartwatch

---

## Testing

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/core/utils/rule_matcher_test.dart
flutter test test/presentation/screens/
```

Current test coverage:
- ✅ Rule matcher (30+ conditions)
- ✅ Video/image file type detection
- ✅ Large file filtering logic
- ✅ Log detail parsing
- ✅ Widget tests for Rule List, Preview, Large File screens

---

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) (coming soon) and submit PRs.

### Development Setup

1. Fork and clone the repo
2. Run `flutter pub get`
3. Run `flutter gen-l10n` to generate localizations
4. Run `dart run build_runner build` to generate freezed/drift code
5. Open Android emulator or connect a device with `MANAGE_EXTERNAL_STORAGE` granted

### Code Style
- Follow existing Flutter/Dart conventions
- Run `flutter analyze` before committing
- Add tests for new features

---

## Acknowledgements

Inspired by the best of the cleaner app ecosystem:
- **SD Maid** – For the deep-cleaning philosophy and rule-based approach
- **Files by Google** – For the clean, no-nonsense UI design
- **CCleaner** – For the comprehensive system monitoring concept

---

## License

[MIT License](LICENSE) © UtopiaFar

---

<p align="center">
  Built with ❤️ using Flutter
</p>
