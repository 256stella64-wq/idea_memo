import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_database.dart';
import 'app_models.dart';

class BackupService {
  BackupService._();

  static final AppDatabase _db = AppDatabase.instance;

  static Future<File> createBackupFile() async {
    final memos = await _db.getAllMemos();

    final now = DateTime.now();
    final fileName = 'idea_memo_backup_${_formatDateForFileName(now)}.json';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    final payload = {
      'app': 'idea_memo',
      'schemaVersion': 1,
      'exportedAt': now.toIso8601String(),
      'memoCount': memos.length,
      'memos': memos.map(_memoToBackupMap).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(payload),
      flush: true,
    );

    return file;
  }

  static Future<void> shareBackupFile() async {
    final file = await createBackupFile();

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Idea Memo のバックアップです',
        subject: 'Idea Memo Backup',
      ),
    );
  }

  static Future<({int insertedCount, int updatedCount})> restoreFromPickedBackupFileUpsert() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('ファイルが選択されませんでした');
    }

    final picked = result.files.first;

    String content;
    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else {
      throw Exception('ファイルを読み込めませんでした');
    }

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('バックアップ形式が不正です');
    }

    final app = decoded['app'];
    final memosRaw = decoded['memos'];

    if (app != 'idea_memo') {
      throw Exception('Idea Memo のバックアップではありません');
    }
    if (memosRaw is! List) {
      throw Exception('memos データが不正です');
    }

    final restoredMemos = memosRaw
        .map((e) => Memo.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return await _db.importMemosUpsert(restoredMemos);
  }

  static Map<String, dynamic> _memoToBackupMap(Memo memo) {
    return {
      'id': memo.id,
      'title': memo.title,
      'body': memo.body,
      'tags': memo.tags,
      'isLocked': memo.isLocked,
      'handwritingDataJson': memo.handwritingDataJson,
      'handwritingPreviewBase64': memo.handwritingPreviewBase64,
      'createdAt': memo.createdAt.toIso8601String(),
      'updatedAt': memo.updatedAt.toIso8601String(),
    };
  }

  static String _formatDateForFileName(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }
}