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
  String? handwritingDataJson;
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
      'tags_json': jsonEncode(tags),
      'is_locked': isLocked ? 1 : 0,
      'handwriting_data_json': handwritingDataJson,
      'handwriting_preview_base64': handwritingPreviewBase64,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags_json'];
    List<String> parsedTags = [];

    if (rawTags is String && rawTags.isNotEmpty) {
      try {
        parsedTags = List<String>.from(jsonDecode(rawTags) as List);
      } catch (_) {
        parsedTags = [];
      }
    } else if (map['tags'] is List) {
        // 旧形式にも一応対応
      parsedTags = List<String>.from(map['tags'] as List);
    }

    return Memo(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      tags: parsedTags,
      isLocked: ((map['is_locked'] ?? map['isLocked'] ?? 0) == 1) ||
          ((map['isLocked'] ?? false) == true),
      handwritingDataJson:
          map['handwriting_data_json'] as String? ??
          map['handwritingDataJson'] as String?,
      handwritingPreviewBase64:
          map['handwriting_preview_base64'] as String? ??
          map['handwritingPreviewBase64'] as String?,
      createdAt: DateTime.parse(
        (map['created_at'] ?? map['createdAt']) as String,
      ),
      updatedAt: DateTime.parse(
        (map['updated_at'] ?? map['updatedAt']) as String,
      ),
    );
  }

  String toJson() => jsonEncode({
        'id': id,
        'title': title,
        'body': body,
        'tags': tags,
        'isLocked': isLocked,
        'handwritingDataJson': handwritingDataJson,
        'handwritingPreviewBase64': handwritingPreviewBase64,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      });

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