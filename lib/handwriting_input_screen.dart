import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class HandwritingInputScreen extends StatefulWidget {
  const HandwritingInputScreen({super.key, this.initialBase64});

  final String? initialBase64;

  @override
  State<HandwritingInputScreen> createState() => _HandwritingInputScreenState();
}

class _HandwritingInputScreenState extends State<HandwritingInputScreen> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final Uint8List? png = await _controller.toPngBytes();
    if (png == null || !mounted) return;

    Navigator.pop(context, base64Encode(png));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手書き入力'),
        actions: [
          IconButton(
            onPressed: () => _controller.clear(),
            icon: const Icon(Icons.clear),
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('自由に手書きしてください。保存するとメモに画像として添付されます。'),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Signature(
                      controller: _controller,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}