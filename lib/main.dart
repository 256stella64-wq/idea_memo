import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'app_models.dart';
import 'app_store.dart';
import 'handwriting_input_screen.dart';
import 'help_screen.dart';
import 'idea_tools_screen.dart';
import 'memo_detail_screen.dart';
import 'notification_service.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final store = AppStore();
  await store.load();

  runApp(IdeaMemoApp(store: store));
}

class IdeaMemoApp extends StatelessWidget {
  const IdeaMemoApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'アイデアメモ',
          themeMode: store.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: HomeScreen(store: store),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: Colors.indigo,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamilyFallback: const [
        'Noto Sans JP',
        'Noto Sans CJK JP',
        'Hiragino Sans',
        'Yu Gothic',
        'Meiryo',
        'sans-serif',
      ]),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  final _focusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();

  List<String> _draftTags = [];
  bool _speechReady = false;
  bool _isListening = false;
  String? _draftHandwritingBase64;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      if (mounted) _focusNode.requestFocus();
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize();
    if (!mounted) return;
    setState(() {
      _speechReady = available;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final value = _tagController.text.trim();
    if (value.isEmpty) return;
    if (!_draftTags.contains(value)) {
      setState(() => _draftTags.add(value));
    }
    _tagController.clear();
  }

  Future<void> _toggleSpeech() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('音声入力が利用できません')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'ja_JP',
      onResult: (result) {
        final current = _bodyController.text.trimRight();
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;

        final next = current.isEmpty ? recognized : '$current $recognized';
        _bodyController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );

    Future.delayed(const Duration(seconds: 31), () {
      if (!mounted) return;
      setState(() => _isListening = false);
    });
  }

  Future<void> _openHandwriting() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => HandwritingInputScreen(
          initialBase64: _draftHandwritingBase64,
        ),
      ),
    );

    if (result == null) return;
    setState(() => _draftHandwritingBase64 = result);
  }

  Future<void> _saveMemo() async {
    final body = _bodyController.text.trim();
    final title = _titleController.text.trim();

    if (body.isEmpty && _draftHandwritingBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本文か手書きのどちらかを入力してください')),
      );
      return;
    }

    final now = DateTime.now();
    final memo = Memo(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      tags: [..._draftTags],
      handwritingBase64: _draftHandwritingBase64,
      isLocked: false,
      createdAt: now,
      updatedAt: now,
    );

    await widget.store.addMemo(memo);

    _titleController.clear();
    _bodyController.clear();
    _tagController.clear();

    setState(() {
      _draftTags = [];
      _draftHandwritingBase64 = null;
    });

    if (!mounted) return;
    _focusNode.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('メモを保存しました')),
    );
  }

  Future<void> _confirmDelete(Memo memo) async {
    if (memo.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このメモはロックされています')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('この操作は元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await widget.store.deleteMemo(memo.id);
    }
  }

  String _memoPreview(Memo memo) {
    if (memo.body.isNotEmpty) return memo.body;
    if (memo.handwritingBase64 != null) return '手書きメモあり';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final memos = widget.store.memos;

        return Scaffold(
          appBar: AppBar(
            title: const Text('アイデアメモ'),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(store: widget.store),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'help':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                      break;
                    case 'settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(store: widget.store),
                        ),
                      );
                      break;
                    case 'ideas':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IdeaToolsScreen(store: widget.store),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'help', child: Text('ヘルプ')),
                  PopupMenuItem(value: 'settings', child: Text('設定')),
                  PopupMenuItem(value: 'ideas', child: Text('アイデア拡張')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final form = _buildInputArea(context);
                final list = _buildMemoList(context, memos);

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 4, child: form),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 5, child: list),
                    ],
                  );
                }

                return Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.42, child: form),
                    const Divider(height: 1),
                    Expanded(child: list),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _saveMemo,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル（任意）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  focusNode: _focusNode,
                  minLines: 6,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: '思いついたことをすぐ入力',
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
                          labelText: 'タグ',
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _draftTags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () {
                              setState(() => _draftTags.remove(tag));
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (_draftHandwritingBase64 != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_draftHandwritingBase64!),
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _toggleSpeech,
                      icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                      label: Text(_isListening ? '音声停止' : '音声入力'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openHandwriting,
                      icon: const Icon(Icons.draw),
                      label: const Text('手書き入力'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _titleController.clear();
                        _bodyController.clear();
                        _tagController.clear();
                        setState(() {
                          _draftTags = [];
                          _draftHandwritingBase64 = null;
                        });
                        _focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('下書きをクリア'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoList(BuildContext context, List<Memo> memos) {
    if (memos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('まだメモがありません。上の入力欄から最初のアイデアを書いてみてください。'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: memos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final memo = memos[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              memo.title.isEmpty ? '無題' : memo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _memoPreview(memo),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...memo.tags.map((tag) => Chip(label: Text(tag))),
                      if (memo.isLocked)
                        const Chip(
                          avatar: Icon(Icons.lock, size: 16),
                          label: Text('ロック中'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoDetailScreen(
                    memo: memo,
                    store: widget.store,
                  ),
                ),
              );
            },
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'ロック切替',
                  onPressed: () => widget.store.toggleLock(memo.id),
                  icon: Icon(memo.isLocked ? Icons.lock : Icons.lock_open),
                ),
                IconButton(
                  tooltip: '削除',
                  onPressed: () => _confirmDelete(memo),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}