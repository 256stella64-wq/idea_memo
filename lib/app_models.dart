import 'dart:convert';

class Memo {
  Memo({
    required this.id,
    required this.body,
    this.title = '',
    this.tags = const [],
    this.isLocked = false,
    this.handwritingBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String title;
  String body;
  List<String> tags;
  bool isLocked;
  String? handwritingBase64;
  DateTime createdAt;
  DateTime updatedAt;

  Memo copyWith({
    String? id,
    String? title,
    String? body,
    List<String>? tags,
    bool? isLocked,
    String? handwritingBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      isLocked: isLocked ?? this.isLocked,
      handwritingBase64: handwritingBase64 ?? this.handwritingBase64,
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
      'handwritingBase64': handwritingBase64,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      tags: List<String>.from(map['tags'] ?? const []),
      isLocked: (map['isLocked'] ?? false) as bool,
      handwritingBase64: map['handwritingBase64'] as String?,
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