import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_store.dart';
import 'handwriting_input_screen.dart';
import 'ad_banner_weight.dart';

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

  late final FocusNode _bodyFocusNode;
  late final ScrollController _bodyScrollController;

  @override
  void initState() {
    super.initState();
    _memo = widget.memo;
    _titleController = TextEditingController(text: _memo.title);
    _bodyController = TextEditingController(text: _memo.body);
    _tagController = TextEditingController();
    _tags = [..._memo.tags];

    _bodyFocusNode = FocusNode();
    _bodyScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _highlightMatchInBody();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _bodyFocusNode.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  void _highlightMatchInBody() {
    final q = widget.initialHighlight;
    if (q == null || q.trim().isEmpty) return;

    final body = _bodyController.text;
    final lowerBody = body.toLowerCase();
    final lowerQ = q.toLowerCase();
    final index = lowerBody.indexOf(lowerQ);

    if (index == -1) return;

    _bodyController.selection = TextSelection(
      baseOffset: index,
      extentOffset: index + q.length,
    );

    _bodyFocusNode.requestFocus();

    final textBefore = body.substring(0, index);
    final lineCountBefore = '\n'.allMatches(textBefore).length;
    final estimatedOffset = lineCountBefore * 28.0;

    if (_bodyScrollController.hasClients) {
      _bodyScrollController.jumpTo(
        estimatedOffset.clamp(
          0.0,
          _bodyScrollController.position.maxScrollExtent,
        ),
      );
    }
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
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました')),
    );
  }

  Future<void> _editHandwriting() async {
    final result = await Navigator.push<Map<String, String?>?>(
      context,
      MaterialPageRoute(
        builder: (_) => HandwritingInputScreen(
          initialDataJson: _memo.handwritingDataJson,
        ),
      ),
    );

    if (result == null) return;

    final updated = _memo.copyWith(
      handwritingDataJson: result['dataJson'],
      handwritingPreviewBase64: result['previewBase64'],
      updatedAt: DateTime.now(),
    );

    setState(() {
      _memo = updated;
    });

    await widget.store.updateMemo(updated);
  }

  void _addTag() {
    final value = _tagController.text.trim();
    if (value.isEmpty) return;
    if (!_tags.contains(value)) {
      setState(() => _tags.add(value));
    }
    _tagController.clear();
  }

  bool get _hasUnsavedChanges {
    final currentTitle = _titleController.text.trim();
    final currentBody = _bodyController.text.trim();

    final sameTags =
        _tags.length == _memo.tags.length &&
        _tags.every((tag) => _memo.tags.contains(tag));

    return currentTitle != _memo.title ||
        currentBody != _memo.body ||
        !sameTags;
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('保存せずに戻りますか？'),
        content: const Text('編集した内容は保存されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final handwritingPreview = _memo.handwritingPreviewBase64;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldLeave = await _confirmDiscardIfNeeded();
        if (!mounted || !shouldLeave) return;

        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('メモ詳細'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await _confirmDiscardIfNeeded();
              if (!mounted || !shouldLeave) return;
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await widget.store.toggleLock(_memo.id);
                final refreshed =
                    widget.store.memos.firstWhere((e) => e.id == _memo.id);
                if (!mounted) return;
                setState(() => _memo = refreshed);
              },
              icon: Icon(_memo.isLocked ? Icons.lock : Icons.lock_open),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth > 700 ? 32.0 : 16.0;

                return ListView(
                  padding: EdgeInsets.all(horizontalPadding),
                  children: [
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
                      focusNode: _bodyFocusNode,
                      scrollController: _bodyScrollController,
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
                        const SizedBox(width: 16),
                        FilledButton(
                          onPressed: _addTag,
                          child: const Text('タグを追加'),
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('変更を保存'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _editHandwriting,
                        icon: const Icon(Icons.draw),
                        label: const Text('手書きメモを編集'),
                      ),
                    ),
                    if (handwritingPreview != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(handwritingPreview),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: const BottomBannerAd(),
      ),
    );
  }
}