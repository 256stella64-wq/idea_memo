import 'dart:convert';

class Memo {
  Memo({
    required this.id,
    required this.body,
    this.title = '',
    this.tags = const [],
    this.isLocked = false,
    this.handwritingDataJson,
    this.handwritingPreviewBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String title;
  String body;
  List<String> tags;
  bool isLocked;

  /// 編集用の手書きデータ(JSON)
  String? handwritingDataJson;

  /// 一覧表示・詳細表示用のプレビュー画像(base64 PNG)
  String? handwritingPreviewBase64;

  DateTime createdAt;
  DateTime updatedAt;

  Memo copyWith({
    String? id,
    String? title,
    String? body,
    List<String>? tags,
    bool? isLocked,
    String? handwritingDataJson,
    String? handwritingPreviewBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? List<String>.from(this.tags),
      isLocked: isLocked ?? this.isLocked,
      handwritingDataJson: handwritingDataJson ?? this.handwritingDataJson,
      handwritingPreviewBase64:
          handwritingPreviewBase64 ?? this.handwritingPreviewBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'tags': tags,
      'isLocked': isLocked,
      'handwritingDataJson': handwritingDataJson,
      'handwritingPreviewBase64': handwritingPreviewBase64,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    final legacyBase64 = map['handwritingPreviewBase64'] as String?;

    return Memo(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      tags: List<String>.from(map['tags'] ?? const []),
      isLocked: (map['isLocked'] ?? false) as bool,
      handwritingDataJson: map['handwritingDataJson'] as String?,
      handwritingPreviewBase64:
          (map['handwritingPreviewBase64'] as String?) ?? legacyBase64,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Memo.fromJson(String source) =>
      Memo.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class SearchHit {
  SearchHit({
    required this.memo,
    required this.query,
    required this.fieldName,
    required this.start,
    required this.end,
    required this.snippet,
  });

  final Memo memo;
  final String query;
  final String fieldName;
  final int start;
  final int end;
  final String snippet;
}