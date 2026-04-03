import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'rewarded_ad_service.dart';
import 'app_models.dart';
import 'app_store.dart';
import 'handwriting_input_screen.dart';
import 'help_screen.dart';
import 'idea_tools_screen.dart';
import 'notification_service.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'memo_list_screen.dart';
import 'ad_banner_weight.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await MobileAds.instance.initialize();

  await RewardedAdService.instance.load();


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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver{
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  final _focusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();

  List<String> _draftTags = [];
  bool _speechReady = false;
  bool _isListening = false;
  String? _draftHandwritingDataJson;
  String? _draftHandwritingPreviewBase64;

  bool _shouldKeepListening = false;
  String _lastRecognizedWords = '';

  static const _draftTitleKey = 'home_draft_title';
  static const _draftBodyKey = 'home_draft_body';
  static const _draftTagsKey = 'home_draft_tags';
  static const _draftHandwritingDataKey = 'home_draft_handwriting_data';
  static const _draftHandwritingPreviewKey = 'home_draft_handwriting_preview';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _restoreDraft();

    _titleController.addListener(_scheduleDraftSave);
    _bodyController.addListener(_scheduleDraftSave);
    _tagController.addListener(_scheduleDraftSave);

    scheduleMicrotask(() {
      if (mounted) _focusNode.requestFocus();
    });
    _initSpeech();
  }

  Timer? _draftSaveDebounce;

  bool get _hasDraftContent {
    return _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty ||
        _draftTags.isNotEmpty ||
        _draftHandwritingDataJson != null;
  }

  void _scheduleDraftSave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      _persistDraft();
    });
  }

  Future<void> _persistDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (!_hasDraftContent) {
      await prefs.remove(_draftTitleKey);
      await prefs.remove(_draftBodyKey);
      await prefs.remove(_draftTagsKey);
      await prefs.remove(_draftHandwritingDataKey);
      await prefs.remove(_draftHandwritingPreviewKey);
      return;
    }

    await prefs.setString(_draftTitleKey, title);
    await prefs.setString(_draftBodyKey, body);
    await prefs.setStringList(_draftTagsKey, _draftTags);

    if (_draftHandwritingDataJson != null) {
      await prefs.setString(_draftHandwritingDataKey, _draftHandwritingDataJson!);
    } else {
      await prefs.remove(_draftHandwritingDataKey);
    }

    if (_draftHandwritingPreviewBase64 != null) {
      await prefs.setString(
        _draftHandwritingPreviewKey,
        _draftHandwritingPreviewBase64!,
      );
    } else {
      await prefs.remove(_draftHandwritingPreviewKey);
    }
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();

    final title = prefs.getString(_draftTitleKey) ?? '';
    final body = prefs.getString(_draftBodyKey) ?? '';
    final tags = prefs.getStringList(_draftTagsKey) ?? <String>[];
    final handwritingData = prefs.getString(_draftHandwritingDataKey);
    final handwritingPreview = prefs.getString(_draftHandwritingPreviewKey);

    _titleController.text = title;
    _bodyController.text = body;

    if (!mounted) return;
    setState(() {
      _draftTags = tags;
      _draftHandwritingDataJson = handwritingData;
      _draftHandwritingPreviewBase64 = handwritingPreview;
    });
  }

  Future<void> _clearPersistedDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftBodyKey);
    await prefs.remove(_draftTagsKey);
    await prefs.remove(_draftHandwritingDataKey);
    await prefs.remove(_draftHandwritingPreviewKey);
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'notListening' || status == 'done') {
          if (_shouldKeepListening) {
            _restartListeningIfNeeded();
          } else {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        if (!mounted) return;

        if (_shouldKeepListening) {
          _restartListeningIfNeeded();
        } else {
          setState(() => _isListening = false);
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _speechReady = available;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveDebounce?.cancel();
    _persistDraft();
    _speech.stop();
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
      _scheduleDraftSave();
    }
    _tagController.clear();
  }

  Future<void> _startListening() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('音声入力が利用できません')),
      );
      return;
    }

    _shouldKeepListening = true;
    _lastRecognizedWords = '';

    if (!mounted) return;
    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'ja_JP',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;

        if (result.finalResult) {
          String textToAdd = recognized;

          if (_lastRecognizedWords.isNotEmpty &&
              recognized.startsWith(_lastRecognizedWords)) {
            textToAdd = recognized.substring(_lastRecognizedWords.length).trim();
          }

          if (textToAdd.isNotEmpty) {
            final current = _bodyController.text.trimRight();
            final next = current.isEmpty ? textToAdd : '$current $textToAdd';

            _bodyController.value = TextEditingValue(
              text: next,
              selection: TextSelection.collapsed(offset: next.length),
            );
          }

          _lastRecognizedWords = '';
        } else {
          _lastRecognizedWords = recognized;
        }
      },
    );
  }

  Future<void> _stopListening() async {
    _shouldKeepListening = false;
    _lastRecognizedWords = '';
    await _speech.stop();

    if (!mounted) return;
    setState(() => _isListening = false);
  }

  Future<void> _restartListeningIfNeeded() async {
    if (!_shouldKeepListening) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!_shouldKeepListening || !mounted) return;

    if (_speech.isListening) return;

    await _speech.listen(
      localeId: 'ja_JP',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;

        if (result.finalResult) {
          String textToAdd = recognized;

          if (_lastRecognizedWords.isNotEmpty &&
              recognized.startsWith(_lastRecognizedWords)) {
            textToAdd = recognized.substring(_lastRecognizedWords.length).trim();
          }

          if (textToAdd.isNotEmpty) {
            final current = _bodyController.text.trimRight();
            final next = current.isEmpty ? textToAdd : '$current $textToAdd';

            _bodyController.value = TextEditingValue(
              text: next,
              selection: TextSelection.collapsed(offset: next.length),
            );
          }

          _lastRecognizedWords = '';
        } else {
          _lastRecognizedWords = recognized;
        }
      },
    );

    if (!mounted) return;
    setState(() => _isListening = true);
  }

  Future<void> _toggleSpeech() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _openHandwriting() async {
    final result = await Navigator.push<Map<String, String?>?>(
      context,
      MaterialPageRoute(
        builder: (_) => HandwritingInputScreen(
          initialDataJson: _draftHandwritingDataJson,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _draftHandwritingDataJson = result['dataJson'];
      _draftHandwritingPreviewBase64 = result['previewBase64'];
    });
    _scheduleDraftSave();
  }

  Future<void> _saveMemo() async {
    final body = _bodyController.text.trim();
    final title = _titleController.text.trim();
    final now = DateTime.now();

    if (body.isEmpty && _draftHandwritingDataJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本文か手書きのどちらかを入力してください')),
      );
      return;
    }

    final memo = Memo(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      tags: [..._draftTags],
      handwritingDataJson: _draftHandwritingDataJson,
      handwritingPreviewBase64: _draftHandwritingPreviewBase64,
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
      _draftHandwritingDataJson = null;
      _draftHandwritingPreviewBase64 = null;
    });

    await _clearPersistedDraft();

    if (!mounted) return;
    _focusNode.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('メモを保存しました'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '一覧を見る',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemoListScreen(store: widget.store),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('アイデアメモ'),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemoListScreen(store: widget.store),
                    ),
                  );
                },
                icon: const Icon(Icons.folder_open),
                tooltip: '保存済みメモ',
              ),
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
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'help', child: Text('ヘルプ')),
                  PopupMenuItem(value: 'settings', child: Text('設定')),
                ],
              ),
            ],
          ),
          bottomNavigationBar: const BottomBannerAd(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: _buildInputArea(context),
            ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('下書きを削除しますか？'),
                          content: const Text('入力中の内容がすべて消えます。'),
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
                        ),
                      );

                      if (ok != true) return;

                      _titleController.clear();
                      _bodyController.clear();
                      _tagController.clear();
                      setState(() {
                        _draftTags = [];
                        _draftHandwritingDataJson = null;
                        _draftHandwritingPreviewBase64 = null;
                      });
                      await _clearPersistedDraft();
                      _focusNode.requestFocus();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('下書きをクリア'),
                  ),
                ),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _addTag,
                      child: const Text('タグを追加'),
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
                              _scheduleDraftSave();
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (_draftHandwritingPreviewBase64 != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_draftHandwritingPreviewBase64!),
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
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saveMemo,
                    icon: const Icon(Icons.save),
                    label: const Text('メモを保存'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'アイデアに詰まったとき',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  '視点を変えたり、発想を広げたりしたいときに使えます。',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IdeaToolsScreen(store: widget.store),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('アイデアを広げる'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}