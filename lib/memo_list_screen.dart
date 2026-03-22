import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_store.dart';
import 'memo_detail_screen.dart';

class MemoListScreen extends StatelessWidget {
  const MemoListScreen({super.key, required this.store});

  final AppStore store;

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
      await store.deleteMemo(memo.id);
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
      animation: store,
      builder: (context, _) {
        final memos = store.memos;

        return Scaffold(
          appBar: AppBar(
            title: const Text('保存済みメモ'),
          ),
          body: SafeArea(
            child: memos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('まだメモがありません。ホーム画面から最初のアイデアを書いてみてください。'),
                    ),
                  )
                : ListView.separated(
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
                                  store: store,
                                ),
                              ),
                            );
                          },
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                tooltip: 'ロック切替',
                                onPressed: () => store.toggleLock(memo.id),
                                icon: Icon(
                                  memo.isLocked ? Icons.lock : Icons.lock_open,
                                ),
                              ),
                              IconButton(
                                tooltip: '削除',
                                onPressed: () => _confirmDelete(context, memo),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}