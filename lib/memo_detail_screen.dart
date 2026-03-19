import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_store.dart';
import 'handwriting_input_screen.dart';

class MemoDetailScreen extends StatefulWidget {
  const MemoDetailScreen({
    super.key,
    required this.memo,
    required this.store,
    this.initialHighlight,
  });

  final Memo memo;
  final AppStore store;
  final String? initialHighlight;

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagController;
  late Memo _memo;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _memo = widget.memo;
    _titleController = TextEditingController(text: _memo.title);
    _bodyController = TextEditingController(text: _memo.body);
    _tagController = TextEditingController();
    _tags = [..._memo.tags];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = _memo.copyWith(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      tags: _tags,
      updatedAt: DateTime.now(),
    );
    await widget.store.updateMemo(updated);
    if (!mounted) return;
    setState(() => _memo = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました')),
    );
  }

  Future<void> _editHandwriting() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => HandwritingInputScreen(
          initialBase64: _memo.handwritingBase64,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _memo = _memo.copyWith(handwritingBase64: result);
    });
    await widget.store.updateMemo(_memo);
  }

  void _addTag() {
    final value = _tagController.text.trim();
    if (value.isEmpty) return;
    if (!_tags.contains(value)) {
      setState(() => _tags.add(value));
    }
    _tagController.clear();
  }

  Widget _buildHighlightedPreview() {
    final q = widget.initialHighlight;
    if (q == null || q.trim().isEmpty) return const SizedBox.shrink();

    final body = _bodyController.text;
    final lowerBody = body.toLowerCase();
    final lowerQ = q.toLowerCase();
    final index = lowerBody.indexOf(lowerQ);

    if (index == -1) return const SizedBox.shrink();

    final before = body.substring(0, index);
    final match = body.substring(index, index + q.length);
    final after = body.substring(index + q.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: '該当箇所: '),
              TextSpan(text: before),
              TextSpan(
                text: match,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.yellow,
                  color: Colors.black,
                ),
              ),
              TextSpan(text: after),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final handwriting = _memo.handwritingBase64;

    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ詳細'),
        actions: [
          IconButton(
            onPressed: () async {
              await widget.store.toggleLock(_memo.id);
              final refreshed = widget.store.memos.firstWhere((e) => e.id == _memo.id);
              if (!mounted) return;
              setState(() => _memo = refreshed);
            },
            icon: Icon(_memo.isLocked ? Icons.lock : Icons.lock_open),
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 700 ? 32.0 : 16.0;

            return ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                _buildHighlightedPreview(),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル（あとからでもOK）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  minLines: 8,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: '本文',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          labelText: 'タグ追加',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addTag,
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() => _tags.remove(tag));
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _editHandwriting,
                  icon: const Icon(Icons.draw),
                  label: const Text('手書きメモを編集'),
                ),
                if (handwriting != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(handwriting),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}