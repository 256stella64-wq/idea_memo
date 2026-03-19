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
              ],
            );
          },
        ),
      ),
    );
  }
}