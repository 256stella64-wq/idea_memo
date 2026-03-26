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
              'このアプリは、思いついたアイデアをすぐに記録し、あとから整理・発展させるためのメモアプリです。\n'
              '文章だけでなく、音声や手書きでもアイデアを残すことができます。',
            ),

            const SizedBox(height: 24),
            Text('基本的な使い方', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・ホーム画面でアイデアをすぐ入力\n'
              '・タイトルはあとから追加可能\n'
              '・タグを付けて整理できます\n'
              '・保存すると一覧に追加されます',
            ),

            const SizedBox(height: 24),
            Text('入力機能', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・テキスト入力：思いついたことをそのまま記録\n'
              '・音声入力：話すだけでメモを作成\n'
              '・手書き入力：図やイメージもそのまま保存',
            ),

            const SizedBox(height: 24),
            Text('メモ管理', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・保存済みメモ一覧で確認できます\n'
              '・タグごとに整理・分類が可能\n'
              '・ロック機能で誤削除を防止\n'
              '・メモを編集・更新できます',
            ),

            const SizedBox(height: 24),
            Text('検索機能', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・キーワードでメモを検索できます\n'
              '・本文・タイトル・タグすべてが検索対象です',
            ),

            const SizedBox(height: 8),
            const Text(
              '※手書きメモの線や文字は画像として保存されます。\n'
              '手書き文字そのものは自動で文字認識されないため、検索対象にはなりません。',
            ),

            const SizedBox(height: 24),
            Text('アイデア拡張機能', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・質問に答えることでアイデアを深掘りできます\n'
              '・内容に応じて最適な質問が自動で選ばれます\n'
              '・ビジネス・動画・就活など様々な用途に対応',
            ),

            const SizedBox(height: 24),
            Text('バックアップ', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・メモをバックアップファイルとして保存できます\n'
              '・他の端末やGoogle Driveなどに共有可能\n'
              '・バックアップから復元もできます',
            ),

            const SizedBox(height: 24),
            Text('その他', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              '・ダークモードに対応しています\n'
              '・アプリはすべてオフラインで動作します',
            ),
          ],
        ),
      ),
    );
  }
}