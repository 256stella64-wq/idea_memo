import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import 'app_models.dart';
import 'notification_service.dart';
import 'backup_service.dart';

class AppStore extends ChangeNotifier {
  static const _memosKey = 'memos_v1';
  static const _darkModeKey = 'dark_mode_v1';
  static const _notificationKey = 'notification_enabled_v1';
  static const _migrationDoneKey = 'memos_sqlite_migrated_v1';

  final AppDatabase _db = AppDatabase.instance;

  List<Memo> _memos = [];
  bool _isDarkMode = false;
  bool _notificationsEnabled = false;

  List<Memo> get memos => List.unmodifiable(_memos);
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _notificationsEnabled = prefs.getBool(_notificationKey) ?? false;

    await _migrateLegacyMemosIfNeeded(prefs);

    _memos = await _db.getAllMemos();

    if (_notificationsEnabled) {
      await NotificationService.setDailyIdeaReminder(true);
    }

    notifyListeners();
  }

  Future<void> _migrateLegacyMemosIfNeeded(SharedPreferences prefs) async {
    final migrated = prefs.getBool(_migrationDoneKey) ?? false;
    if (migrated) return;

    final dbHasData = await _db.hasAnyMemo();
    if (dbHasData) {
      await prefs.setBool(_migrationDoneKey, true);
      return;
    }

    final raw = prefs.getStringList(_memosKey) ?? [];
    if (raw.isNotEmpty) {
      final legacyMemos = raw.map(Memo.fromJson).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      for (final memo in legacyMemos) {
        await _db.insertMemo(memo);
      }
    }

    await prefs.setBool(_migrationDoneKey, true);
  }

  Future<void> _reloadMemos() async {
    _memos = await _db.getAllMemos();
  }

  Future<void> addMemo(Memo memo) async {
    await _db.insertMemo(memo);
    await _reloadMemos();
    notifyListeners();
  }

  Future<void> updateMemo(Memo memo) async {
    final updated = memo.copyWith(updatedAt: DateTime.now());
    await _db.updateMemo(updated);
    await _reloadMemos();
    notifyListeners();
  }

  Future<void> deleteMemo(String id) async {
    await _db.deleteMemo(id);
    await _reloadMemos();
    notifyListeners();
  }

  Future<void> toggleLock(String id) async {
    final index = _memos.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final target = _memos[index];
    final updated = target.copyWith(
      isLocked: !target.isLocked,
      updatedAt: DateTime.now(),
    );

    await _db.updateMemo(updated);
    await _reloadMemos();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, value);
    await NotificationService.setDailyIdeaReminder(value);
    notifyListeners();
  }

  Future<void> exportAndShareBackup() async {
    await BackupService.shareBackupFile();
  }

  Future<({int insertedCount, int updatedCount})> restoreBackupUpsert() async {
    final result = await BackupService.restoreFromPickedBackupFileUpsert();
    await _reloadMemos();
    notifyListeners();
    return result;
  }

  List<SearchHit> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final List<SearchHit> hits = [];

    for (final memo in _memos) {
      void addIfFound(String field, String value) {
        final lower = value.toLowerCase();
        final index = lower.indexOf(q);
        if (index == -1) return;

        final start = index;
        final end = index + q.length;
        final snippetStart = (start - 20).clamp(0, value.length);
        final snippetEnd = (end + 20).clamp(0, value.length);
        final snippet = value.substring(snippetStart, snippetEnd);

        hits.add(
          SearchHit(
            memo: memo,
            query: query,
            fieldName: field,
            start: start,
            end: end,
            snippet: snippet,
          ),
        );
      }

      addIfFound('タイトル', memo.title);
      addIfFound('本文', memo.body);
      addIfFound('タグ', memo.tags.join(' '));
    }

    return hits;
  }

  List<Memo> randomMemoPair() {
    if (_memos.length < 2) return [];
    final sorted = [..._memos]..shuffle();
    return sorted.take(2).toList();
  }
}