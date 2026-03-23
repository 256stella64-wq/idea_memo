import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum CanvasMode {
  draw,
  move,
}

enum DrawingTool {
  pen,
  marker,
  pencil,
  eraser,
}

class Stroke {
  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final DrawingTool tool;

  Map<String, dynamic> toJson() {
    return {
      'points': points
          .map((p) => {'dx': p.dx, 'dy': p.dy})
          .toList(),
      'color': color.value,
      'width': width,
      'tool': tool.name,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map(
            (p) => Offset(
              (p['dx'] as num).toDouble(),
              (p['dy'] as num).toDouble(),
            ),
          )
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      tool: DrawingTool.values.firstWhere(
        (e) => e.name == json['tool'],
      ),
    );
  }
}

class CanvasTextBox {
  CanvasTextBox({
    required this.id,
    required this.controller,
    required this.position,
    this.width = 220,
  });

  final String id;
  final TextEditingController controller;
  Offset position;
  double width;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': controller.text,
      'dx': position.dx,
      'dy': position.dy,
      'width': width,
    };
  }

  factory CanvasTextBox.fromJson(Map<String, dynamic> json) {
    return CanvasTextBox(
      id: json['id'] as String,
      controller: TextEditingController(text: json['text'] as String? ?? ''),
      position: Offset(
        (json['dx'] as num).toDouble(),
        (json['dy'] as num).toDouble(),
      ),
      width: (json['width'] as num?)?.toDouble() ?? 220,
    );
  }
}

class HandwritingInputScreen extends StatefulWidget {
  const HandwritingInputScreen({
    super.key,
    this.initialDataJson,
  });

  final String? initialDataJson;

  @override
  State<HandwritingInputScreen> createState() => _HandwritingInputScreenState();
}

class _HandwritingInputScreenState extends State<HandwritingInputScreen> {
  static const double _canvasWidth = 1200;
  static const double _canvasHeight = 1600;

  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  Uint8List? _backgroundBytes;

  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _currentStroke;

  final List<CanvasTextBox> _textBoxes = [];
  int _textBoxCounter = 0;

  CanvasMode _canvasMode = CanvasMode.draw;
  DrawingTool _selectedTool = DrawingTool.pen;
  Color _selectedColor = Colors.black;
  double _selectedWidth = 4.0;

  @override
  void initState() {
    super.initState();

    if (widget.initialDataJson != null && widget.initialDataJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.initialDataJson!) as Map<String, dynamic>;

        final strokes = (decoded['strokes'] as List? ?? [])
            .map((e) => Stroke.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final textBoxes = (decoded['textBoxes'] as List? ?? [])
            .map((e) => CanvasTextBox.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _strokes.addAll(strokes);
        _textBoxes.addAll(textBoxes);

        _textBoxCounter = _textBoxes.length;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
     for (final textBox in _textBoxes) {
      textBox.controller.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _addTextBox() {
    setState(() {
      _textBoxCounter++;

      _textBoxes.add(
        CanvasTextBox(
          id: 'textbox_$_textBoxCounter',
          controller: TextEditingController(),
          position: Offset(
            80.0 + (_textBoxCounter * 20) % 200,
            80.0 + (_textBoxCounter * 20) % 300,
          ),
        ),
      );
    });
  }

  void _removeTextBox(String id) {
    final index = _textBoxes.indexWhere((e) => e.id == id);
    if (index == -1) return;

    setState(() {
      _textBoxes[index].controller.dispose();
      _textBoxes.removeAt(index);
    });
  }

  bool _isDraggingTextBox = false;

  bool get _hasUnsavedDrawingChanges => _strokes.isNotEmpty;

  bool get _hasUnsavedTextChanges =>
    _textBoxes.any((textBox) => textBox.controller.text.trim().isNotEmpty);

  bool get _hasUnsavedChanges =>
    _hasUnsavedDrawingChanges || _hasUnsavedTextChanges;

  bool get _hasAnyCanvasContent =>
      _strokes.isNotEmpty || _textBoxes.isNotEmpty;
  Color get _activeStrokeColor {
    switch (_selectedTool) {
      case DrawingTool.eraser:
        return Colors.transparent;
      case DrawingTool.pen:
      case DrawingTool.marker:
      case DrawingTool.pencil:
        return _selectedColor;
    }
  }

  double get _activeStrokeWidth {
    switch (_selectedTool) {
      case DrawingTool.eraser:
        return _selectedWidth * 2.4;
      case DrawingTool.marker:
        return _selectedWidth * 1.35;
      case DrawingTool.pen:
      case DrawingTool.pencil:
        return _selectedWidth;
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('保存せずに戻りますか？'),
        content: const Text('手書きや入力したテキストは保存されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  Future<void> _save() async {
    if (!_hasAnyCanvasContent) {
      Navigator.pop(context, null);
      return;
    }

    final data = {
      'strokes': _strokes.map((e) => e.toJson()).toList(),
      'textBoxes': _textBoxes.map((e) => e.toJson()).toList(),
    };

    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null || !mounted) return;

    final pngBytes = byteData.buffer.asUint8List();

    Navigator.pop(context, {
      'dataJson': jsonEncode(data),
      'previewBase64': base64Encode(pngBytes),
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
      _currentStroke = null;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
      _currentStroke = null;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _setTool(DrawingTool tool) {
    setState(() {
      _selectedTool = tool;
      if (tool == DrawingTool.eraser) {
        _canvasMode = CanvasMode.draw;
      }
    });
  }

  void _setColor(Color color) {
    setState(() {
      _selectedColor = color;
      if (_selectedTool == DrawingTool.eraser) {
        _selectedTool = DrawingTool.pen;
      }
    });
  }

  void _setWidth(double width) {
    setState(() {
      _selectedWidth = width;
    });
  }

  Offset _clampToCanvas(Offset point) {
    final dx = point.dx.clamp(0.0, _canvasWidth);
    final dy = point.dy.clamp(0.0, _canvasHeight);
    return Offset(dx, dy);
  }

  void _onPanStart(DragStartDetails details) {
    if (_canvasMode != CanvasMode.draw) return;

    final point = _clampToCanvas(details.localPosition);

    final stroke = Stroke(
      points: [point],
      color: _activeStrokeColor,
      width: _activeStrokeWidth,
      tool: _selectedTool,
    );

    setState(() {
      _currentStroke = stroke;
      _strokes.add(stroke);
      _redoStack.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_canvasMode != CanvasMode.draw) return;
    if (_currentStroke == null) return;

    final point = _clampToCanvas(details.localPosition);

    setState(() {
      _currentStroke!.points.add(point);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_canvasMode != CanvasMode.draw) return;

    setState(() {
      if (_currentStroke != null && _currentStroke!.points.length == 1) {
        _currentStroke!.points.add(_currentStroke!.points.first);
      }
      _currentStroke = null;
    });
  }

  Widget _buildColorButton(Color color) {
    final selected = _selectedColor == color && _selectedTool != DrawingTool.eraser;

    return InkWell(
      onTap: () => _setColor(color),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
            width: selected ? 3 : 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildToolChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToolChip(
                  label: '描画',
                  selected: _canvasMode == CanvasMode.draw,
                  onTap: () {
                    setState(() {
                      _canvasMode = CanvasMode.draw;
                    });
                  },
                ),
                _buildToolChip(
                  label: '移動/拡大',
                  selected: _canvasMode == CanvasMode.move,
                  onTap: () {
                    setState(() {
                      _canvasMode = CanvasMode.move;
                    });
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _resetZoom,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('表示を戻す'),
                ),

                OutlinedButton.icon(
                  onPressed: _addTextBox,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('テキスト追加'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToolChip(
                  label: 'ペン',
                  selected: _selectedTool == DrawingTool.pen,
                  onTap: () => _setTool(DrawingTool.pen),
                ),
                _buildToolChip(
                  label: 'マーカー',
                  selected: _selectedTool == DrawingTool.marker,
                  onTap: () => _setTool(DrawingTool.marker),
                ),
                _buildToolChip(
                  label: 'えんぴつ',
                  selected: _selectedTool == DrawingTool.pencil,
                  onTap: () => _setTool(DrawingTool.pencil),
                ),
                _buildToolChip(
                  label: '消しゴム',
                  selected: _selectedTool == DrawingTool.eraser,
                  onTap: () => _setTool(DrawingTool.eraser),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('色'),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.blue),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.orange),
                const SizedBox(width: 8),
                const Text('太さ'),
                DropdownButton<double>(
                  value: _selectedWidth,
                  items: const [
                    DropdownMenuItem<double>(value: 2.0, child: Text('細')),
                    DropdownMenuItem<double>(value: 4.0, child: Text('中')),
                    DropdownMenuItem<double>(value: 8.0, child: Text('太')),
                    DropdownMenuItem<double>(value: 12.0, child: Text('極太')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _setWidth(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _canvasMode == CanvasMode.draw
                  ? '描画モードです。1本指で書けます。'
                  : '移動/拡大モードです。ドラッグで移動、ピンチで拡大縮小できます。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 5.0,
      panEnabled: _canvasMode == CanvasMode.move && !_isDraggingTextBox,
      scaleEnabled: _canvasMode == CanvasMode.move && !_isDraggingTextBox,
      child: RepaintBoundary(
        key: _canvasKey,
        child: SizedBox(
          width: _canvasWidth,
          height: _canvasHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.white),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _canvasMode == CanvasMode.draw ? _onPanStart : null,
                onPanUpdate: _canvasMode == CanvasMode.draw ? _onPanUpdate : null,
                onPanEnd: _canvasMode == CanvasMode.draw ? _onPanEnd : null,
                child: CustomPaint(
                  painter: _HandwritingPainter(strokes: _strokes),
                  size: const Size(_canvasWidth, _canvasHeight),
                  isComplex: true,
                  willChange: true,
                ),
              ),
              ..._textBoxes.map((textBox) {
                return Positioned(
                  key: ValueKey(textBox.id),
                  left: textBox.position.dx,
                  top: textBox.position.dy,
                  child: _buildCanvasTextBox(textBox),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasTextBox(CanvasTextBox textBox) {
    return GestureDetector(
      onPanStart: (_) {
        setState(() {
          _isDraggingTextBox = true;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          final newDx = (textBox.position.dx + details.delta.dx)
              .clamp(0.0, _canvasWidth - textBox.width);
          final newDy = (textBox.position.dy + details.delta.dy)
              .clamp(0.0, _canvasHeight - 120.0);

          textBox.position = Offset(newDx, newDy);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _isDraggingTextBox = false;
        });
      },
      onPanCancel: () {
        setState(() {
          _isDraggingTextBox = false;
        });
      },
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: textBox.width,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: TextField(
                controller: textBox.controller,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'テキストを入力',
                  border: InputBorder.none, // ←これでスッキリ
                  isDense: true,
                ),
              ),
            ),

            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeTextBox(textBox.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLeave = await _confirmDiscardIfNeeded();
        if (!mounted || !shouldLeave) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('手書き入力'),
          leading: IconButton(
            tooltip: '戻る',
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await _confirmDiscardIfNeeded();
              if (!mounted || !shouldLeave) return;
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: _strokes.isEmpty ? null : _undo,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: _redoStack.isEmpty ? null : _redo,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: '保存',
              onPressed: _save,
              icon: const Icon(Icons.check),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Text(
                  _backgroundBytes != null
                      ? '既存の手書きメモに追記できます。保存すると追記後の内容で上書きされます。'
                      : '自由に手書きしてください。保存するとメモに画像として添付されます。',
                ),
              ),
              _buildToolbar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _buildCanvas(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandwritingPainter extends CustomPainter {
  const _HandwritingPainter({
    required this.strokes,
  });

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      switch (stroke.tool) {
        case DrawingTool.pen:
          paint.color = stroke.color;
          break;
        case DrawingTool.marker:
          paint.color = stroke.color.withOpacity(0.45);
          break;
        case DrawingTool.pencil:
          paint.color = stroke.color.withOpacity(0.7);
          break;
        case DrawingTool.eraser:
          paint.blendMode = BlendMode.clear;
          paint.color = Colors.transparent;
          break;
      }

      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
        continue;
      }

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final previous = stroke.points[i - 1];
        final current = stroke.points[i];
        final midPoint = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(previous.dx, previous.dy, midPoint.dx, midPoint.dy);
      }

      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return true;
  }
}