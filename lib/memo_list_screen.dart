import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_store.dart';
import 'memo_detail_screen.dart';

enum MemoListViewMode { list, byTag }

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  MemoListViewMode _viewMode = MemoListViewMode.list;

  Future<void> _confirmDelete(BuildContext context, Memo memo) async {
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
    if (memo.handwritingPreviewBase64 != null) return '手書きメモあり';
    return '';
  }

  Map<String, List<Memo>> _groupByTag(List<Memo> memos) {
    final grouped = <String, List<Memo>>{};

    for (final memo in memos) {
      if (memo.tags.isEmpty) {
        grouped.putIfAbsent('タグなし', () => []).add(memo);
        continue;
      }

      for (final rawTag in memo.tags) {
        final tag = rawTag.trim();
        if (tag.isEmpty) continue;
        grouped.putIfAbsent(tag, () => []).add(memo);
      }
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        if (a.key == 'タグなし' && b.key != 'タグなし') return 1;
        if (a.key != 'タグなし' && b.key == 'タグなし') return -1;

        final countCompare = b.value.length.compareTo(a.value.length);
        if (countCompare != 0) return countCompare;

        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return {for (final entry in sortedEntries) entry.key: entry.value};
  }

  Widget _buildViewModeSwitcher(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<MemoListViewMode>(
        segments: const [
          ButtonSegment<MemoListViewMode>(
            value: MemoListViewMode.list,
            icon: Icon(Icons.view_list),
            label: Text('一覧'),
          ),
          ButtonSegment<MemoListViewMode>(
            value: MemoListViewMode.byTag,
            icon: Icon(Icons.folder_open),
            label: Text('タグ別'),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (selection) {
          setState(() {
            _viewMode = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildMemoCard(BuildContext context, Memo memo) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.title.isEmpty ? '無題' : memo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'ロック切替',
                      onPressed: () => widget.store.toggleLock(memo.id),
                      icon: Icon(
                        memo.isLocked ? Icons.lock : Icons.lock_open,
                      ),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      tooltip: '削除',
                      onPressed: () => _confirmDelete(context, memo),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Memo> memos) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: memos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final memo = memos[index];
        return _buildMemoCard(context, memo);
      },
    );
  }

  Widget _buildGroupedByTagView(BuildContext context, List<Memo> memos) {
    final grouped = _groupByTag(memos);
    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final tag = entry.key;
        final tagMemos = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: const Icon(Icons.folder_open),
            title: Text(tag),
            subtitle: Text('${tagMemos.length}件'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              const SizedBox(height: 4),
              ...List.generate(tagMemos.length, (memoIndex) {
                final memo = tagMemos[memoIndex];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: memoIndex == tagMemos.length - 1 ? 0 : 8,
                  ),
                  child: _buildMemoCard(context, memo),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final memos = widget.store.memos;

        return Scaffold(
          appBar: AppBar(
            title: const Text('保存済みメモ'),
          ),
          body: SafeArea(
            child: memos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'まだメモがありません。ホーム画面から最初のアイデアを書いてみてください。',
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildViewModeSwitcher(context),
                      Expanded(
                        child: _viewMode == MemoListViewMode.list
                            ? _buildListView(context, memos)
                            : _buildGroupedByTagView(context, memos),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}