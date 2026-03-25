import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'app_models.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'idea_memo.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE memos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL DEFAULT '',
            body TEXT NOT NULL DEFAULT '',
            tags_json TEXT NOT NULL DEFAULT '[]',
            is_locked INTEGER NOT NULL DEFAULT 0,
            handwriting_data_json TEXT,
            handwriting_preview_base64 TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Memo>> getAllMemos() async {
    final db = await database;
    final maps = await db.query(
      'memos',
      orderBy: 'updated_at DESC',
    );
    return maps.map(Memo.fromMap).toList();
  }

  Future<void> insertMemo(Memo memo) async {
    final db = await database;
    await db.insert(
      'memos',
      memo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMemo(Memo memo) async {
    final db = await database;
    await db.update(
      'memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<void> deleteMemo(String id) async {
    final db = await database;
    await db.delete(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllMemos() async {
    final db = await database;
    await db.delete('memos');
  }

  Future<bool> hasAnyMemo() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM memos');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<void> replaceAllMemos(List<Memo> memos) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('memos');

      final batch = txn.batch();
      for (final memo in memos) {
        batch.insert(
          'memos',
          memo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<({int addedCount, int skippedCount})> importMemosAppendOnly(
    List<Memo> memos,
  ) async {
    final db = await database;

    int addedCount = 0;
    int skippedCount = 0;

    await db.transaction((txn) async {
      for (final memo in memos) {
        final existing = await txn.query(
          'memos',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [memo.id],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          skippedCount++;
          continue;
        }

        await txn.insert(
          'memos',
          memo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        addedCount++;
      }
    });

    return (addedCount: addedCount, skippedCount: skippedCount);
  }

  Future<({int insertedCount, int updatedCount})> importMemosUpsert(
    List<Memo> memos,
  ) async {
    final db = await database;

    int insertedCount = 0;
    int updatedCount = 0;

    await db.transaction((txn) async {
      for (final memo in memos) {
        final existing = await txn.query(
          'memos',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [memo.id],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert(
            'memos',
            memo.toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          insertedCount++;
        } else {
          await txn.update(
            'memos',
            memo.toMap(),
            where: 'id = ?',
            whereArgs: [memo.id],
          );
          updatedCount++;
        }
      }
    });

    return (insertedCount: insertedCount, updatedCount: updatedCount);
  }
}