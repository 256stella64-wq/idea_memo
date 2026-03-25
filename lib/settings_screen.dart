import 'package:flutter/material.dart';
import 'app_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('通知を有効にする'),
                  subtitle: const Text('毎日21:00にアイデア見返し通知'),
                  value: store.notificationsEnabled,
                  onChanged: (value) async {
                    await store.setNotificationsEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('ダークモード'),
                  value: store.isDarkMode,
                  onChanged: (value) async {
                    await store.setDarkMode(value);
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'バックアップ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'メモをバックアップファイルとして書き出し、Google Driveなどに共有できます。',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await store.exportAndShareBackup();

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('バックアップファイルを共有しました'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('バックアップ共有に失敗しました: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.backup),
                          label: const Text('バックアップを書き出して共有'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('バックアップを復元'),
                                  content: const Text(
                                    'バックアップ内のメモを取り込みます。同じメモIDのものは上書き更新されるため、手書き内容も復元されます。',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('復元する'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (ok != true) return;

                            try {
                              final result = await store.restoreBackupUpsert();

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${result.insertedCount}件追加、${result.updatedCount}件更新しました',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('復元に失敗しました: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('バックアップから復元'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}