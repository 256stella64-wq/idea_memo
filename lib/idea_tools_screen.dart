import 'dart:async';
import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_store.dart';

class IdeaToolsScreen extends StatefulWidget {
  const IdeaToolsScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<IdeaToolsScreen> createState() => _IdeaToolsScreenState();
}

class _IdeaToolsScreenState extends State<IdeaToolsScreen> {
  List<Memo> _pair = [];
  int _remaining = 180;
  Timer? _timer;
  final List<String> _trainingPrompts = const [
    '既存のものを逆に不便にしたら？',
    '学生向けに作り変えるなら？',
    '1分で使える形にすると？',
    '音だけで成立させるなら？',
    '感情を強く動かすには？',
    '一人用を複数人向けにしたら？',
  ];
  String _currentPrompt = 'スタートするとお題が出ます';
  Memo? _selectedMemo;
  List<String> _copyResults = [];

  @override
  void initState() {
    super.initState();
    _refreshPair();
    if (widget.store.memos.isNotEmpty) {
      _selectedMemo = widget.store.memos.first;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshPair() {
    setState(() {
      _pair = widget.store.randomMemoPair();
    });
  }

  void _startTraining() {
    _timer?.cancel();
    setState(() {
      _remaining = 180;
      _currentPrompt = (_trainingPrompts..shuffle()).first;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _generateCatchCopies() {
    final memo = _selectedMemo;
    if (memo == null) return;

    final seed = memo.title.isNotEmpty
        ? memo.title
        : memo.body.trim().split('\n').first;

    final tagText = memo.tags.isEmpty ? '新しい視点' : memo.tags.first;

    setState(() {
      _copyResults = [
        'ひらめきを、今すぐ形に。',
        '$seed を、もっと面白く。',
        '$tagText から始まる新しいアイデア。',
        '思いつきを、作品の入口に。',
        '一瞬の発想を、次の一手へ。',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final memos = widget.store.memos;

    return Scaffold(
      appBar: AppBar(title: const Text('アイデア拡張')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '組み合わせ機能',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_pair.length < 2)
                      const Text('メモが2件以上あると使えます')
                    else ...[
                      Text('A: ${_pair[0].title.isEmpty ? _pair[0].body : _pair[0].title}'),
                      const SizedBox(height: 8),
                      Text('B: ${_pair[1].title.isEmpty ? _pair[1].body : _pair[1].title}'),
                      const SizedBox(height: 12),
                      Text(
                        '発想ヒント: この2つを混ぜると、どんな新しい企画になる？',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refreshPair,
                        child: const Text('別の組み合わせを見る'),
                      ),
                    ],
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
                    const Text(
                      '発想トレーニングモード',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('残り ${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}'),
                    const SizedBox(height: 8),
                    Text(_currentPrompt),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _startTraining,
                      child: const Text('3分スタート'),
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
                    const Text(
                      '1行キャッチコピー',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Memo>(
                      value: memos.contains(_selectedMemo) ? _selectedMemo : null,
                      items: memos
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m.title.isEmpty ? '無題' : m.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedMemo = value);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'メモを選択',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _generateCatchCopies,
                      child: const Text('生成'),
                    ),
                    const SizedBox(height: 12),
                    ..._copyResults.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('・$e'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}