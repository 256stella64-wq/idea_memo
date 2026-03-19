import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ヘルプ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('アイデアメモアプリについて', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              'このアプリは、思いついたアイデアをすぐに記録し、あとから育てたり、'
              '組み合わせたりして発想を広げるためのメモアプリです。',
            ),
            const SizedBox(height: 24),
            Text('使い方', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・ホーム画面でメモをすぐ記入できます\n'
              '・タイトルはあとから追加できます\n'
              '・音声入力、手書き入力にも対応しています\n'
              '・タグを付けて整理できます\n'
              '・ロックしたメモは誤削除を防げます\n'
              '・検索画面で本文中の単語を探せます\n'
              '・アイデア拡張画面で組み合わせや発想トレーニングができます',
            ),
            const SizedBox(height: 24),
            Text('補足', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '通知をONにすると、毎日21:00にアイデアを見返すための通知を送ります。',
            ),
          ],
        ),
      ),
    );
  }
}