import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import 'dashboard_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, String>>((ref) {
  return SettingsNotifier(ref.watch(databaseProvider));
});

class SettingsNotifier extends StateNotifier<Map<String, String>> {
  final AppDatabase _db;

  SettingsNotifier(this._db) : super({}) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final all = await _db.select(_db.appSettings).get();
    state = {for (final row in all) row.key: row.value};
  }

  String? get(String key) => state[key];

  Future<void> set(String key, String value) async {
    await _db.setSetting(key, value);
    state = {...state, key: value};
  }
}
