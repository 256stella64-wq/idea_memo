import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_store.dart';
import 'memo_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SearchHit> _results = [];

  void _runSearch(String value) {
    setState(() {
      _results = widget.store.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メモ検索')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                onChanged: _runSearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '単語を入力',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('該当するメモはありません'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final hit = _results[index];
                        return ListTile(
                          title: Text(
                            hit.memo.title.isEmpty ? '無題' : hit.memo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '[${hit.fieldName}] ...${hit.snippet}...',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MemoDetailScreen(
                                  memo: hit.memo,
                                  store: widget.store,
                                  initialHighlight: _controller.text.trim(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}