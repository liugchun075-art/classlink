import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/websocket_service.dart';

class StudentPaperScreen extends StatefulWidget {
  final String className;
  final String userName;
  final List<Map<String, dynamic>> questions;

  const StudentPaperScreen({Key? key, required this.className, required this.userName, required this.questions}) : super(key: key);
  @override
  _StudentPaperScreenState createState() => _StudentPaperScreenState();
}

class DrawingPoint {
  final Offset offset;
  final bool isEraser;
  final double strokeWidth;
  DrawingPoint({required this.offset, required this.isEraser, required this.strokeWidth});
}

class DrawingStroke {
  final List<DrawingPoint> points;
  final Color color;
  DrawingStroke({required this.points, required this.color});
}

class WhiteboardState {
  final List<DrawingStroke> _strokes = [];
  final ValueNotifier<List<DrawingStroke>> strokesNotifier = ValueNotifier([]);
  DrawingStroke? _currentStroke;

  void addPoint(DrawingPoint point, Color color) {
    if (_currentStroke == null) {
      _currentStroke = DrawingStroke(points: [point], color: color);
      _strokes.add(_currentStroke!);
    } else {
      _currentStroke!.points.add(point);
    }
    strokesNotifier.value = List.from(_strokes);
  }

  void endCurrentStroke() => _currentStroke = null;

  void clear() {
    _strokes.clear();
    _currentStroke = null;
    strokesNotifier.value = [];
  }

  List<DrawingStroke> get strokes => _strokes;
}

class WhiteboardPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  WhiteboardPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path();
      path.moveTo(stroke.points.first.offset.dx, stroke.points.first.offset.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].offset.dx, stroke.points[i].offset.dy);
      }
      final paint = Paint()..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
      if (stroke.points.first.isEraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
        paint.strokeWidth = 30.0;
      } else {
        paint.blendMode = BlendMode.srcOver;
        paint.color = stroke.color;
        paint.strokeWidth = stroke.points.first.strokeWidth;
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
}

class WhiteboardWidget extends StatefulWidget {
  final WhiteboardState whiteboardState;
  final bool isEraserMode;
  final Color currentColor;
  final double strokeWidth;
  const WhiteboardWidget({Key? key, required this.whiteboardState, required this.isEraserMode, required this.currentColor, required this.strokeWidth}) : super(key: key);
  @override
  _WhiteboardWidgetState createState() => _WhiteboardWidgetState();
}

class _WhiteboardWidgetState extends State<WhiteboardWidget> {
  void _addPoint(Offset localPosition) {
    widget.whiteboardState.addPoint(DrawingPoint(offset: localPosition, isEraser: widget.isEraserMode, strokeWidth: widget.strokeWidth), widget.currentColor);
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _addPoint(details.localPosition),
      onPanUpdate: (details) => _addPoint(details.localPosition),
      onPanEnd: (details) => widget.whiteboardState.endCurrentStroke(),
      child: Container(
        color: Colors.transparent,
        child: ValueListenableBuilder<List<DrawingStroke>>(
          valueListenable: widget.whiteboardState.strokesNotifier,
          builder: (context, strokes, child) => CustomPaint(painter: WhiteboardPainter(strokes), size: Size.infinite),
        ),
      ),
    );
  }
}

class QuestionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final int index;
  final int totalCount;
  final WhiteboardState whiteboardState;
  final bool isEraserMode;
  final GlobalKey repaintKey;
  final VoidCallback onAskAI;
  final VoidCallback onAskTeacher;
  final String? teacherAnnotation;
  final String? aiHint;
  final bool showTeacherAnnotation;
  final VoidCallback onToggleEraser;

  const QuestionCard({Key? key, required this.question, required this.index, required this.totalCount, required this.whiteboardState, required this.isEraserMode, required this.repaintKey, required this.onAskAI, required this.onAskTeacher, this.teacherAnnotation, this.aiHint, required this.showTeacherAnnotation, required this.onToggleEraser}) : super(key: key);

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? _getImageUrl() {
    if (widget.question['diagrams'] != null && widget.question['diagrams'] is List && widget.question['diagrams'].isNotEmpty) {
      return 'data:image/png;base64,${widget.question['diagrams'][0]['image_data']}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))]),
      child: Column(
        children: [
          // 核心画板区域
          RepaintBoundary(
            key: widget.repaintKey,
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // 底层：题目内容
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Text('第 ${widget.index + 1} 题', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                        ),
                        SizedBox(height: 16),
                        Text(widget.question['content'] ?? '', style: TextStyle(fontSize: 17, height: 1.6, color: Colors.black87)),
                        SizedBox(height: 20),
                        if (imageUrl != null)
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64.decode(imageUrl.split(',').last), fit: BoxFit.contain)),
                        SizedBox(height: 60), 
                      ],
                    ),
                  ),
                  // 画板层
                  Positioned.fill(child: WhiteboardWidget(whiteboardState: widget.whiteboardState, isEraserMode: widget.isEraserMode, currentColor: Colors.black87, strokeWidth: 3.0)),
                  
                  // 老师批注层
                  if (widget.showTeacherAnnotation && widget.teacherAnnotation != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.85,
                          // 【修复】：使用 contain 防止电脑全屏时被压扁
                          child: Image.memory(base64.decode(widget.teacherAnnotation!), fit: BoxFit.contain),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // AI 悬浮提示框
          if (widget.aiHint != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.auto_awesome, size: 20, color: Colors.purple), SizedBox(width: 8), Text('AI 辅导解析', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800))]),
                  SizedBox(height: 8),
                  Text(widget.aiHint!, style: TextStyle(color: Colors.purple.shade900, height: 1.5)),
                ],
              ),
            ),

          // 底部操作栏
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(widget.isEraserMode ? Icons.brush : Icons.auto_fix_high, widget.isEraserMode ? '换画笔' : '换橡皮', widget.onToggleEraser, widget.isEraserMode ? Colors.blue : Colors.grey.shade600),
                _buildActionButton(Icons.delete_outline, '清空', () => widget.whiteboardState.clear(), Colors.red.shade400),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                _buildActionButton(Icons.auto_awesome, 'AI辅导', widget.onAskAI, Colors.purple),
                _buildActionButton(Icons.school, '问老师', widget.onAskTeacher, Colors.orange.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [Icon(icon, color: color, size: 24), SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))],
        ),
      ),
    );
  }
}

class _StudentPaperScreenState extends State<StudentPaperScreen> {
  final Map<int, WhiteboardState> _whiteboards = {};
  final Map<int, GlobalKey> _keys = {};
  final Map<int, String?> _teacherAnnotations = {};
  final Map<int, String?> _aiHints = {};

  bool _showTeacherAnnotations = true;
  late WebSocketService _wsService;
  bool _isEraserMode = false;

  @override
  void initState() {
    super.initState();
    _wsService = WebSocketService(className: widget.className, role: 'student', userName: widget.userName);
    _wsService.onTeacherReply = (content, idx, img) => _safe(() => setState(() { _teacherAnnotations[idx] = img; _showTeacherAnnotations = true; }));
    _wsService.connect();
    for (int i = 0; i < widget.questions.length; i++) { _whiteboards[i] = WhiteboardState(); _keys[i] = GlobalKey(); }
  }

  void _safe(Function cb) => WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) cb(); });
  void _toast(String msg) => _safe(() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating)));

  Future<void> _askAI(int idx) async {
    // 检查是否已经获得过AI辅导
    if (_aiHints[idx] != null && _aiHints[idx]!.isNotEmpty) {
      _toast('该题已获得 AI 辅导，请参考下方解析，不可重复提问。');
      return;
    }
    
    final img = await _capture(_keys[idx]!);
    if (img == null) return;
    _toast('AI分析中，请稍候...');
    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/ai-hint'),
        headers: {'Content-Type': 'application/json'}, 
        body: json.encode({
          'question': widget.questions[idx]['content'] ?? '', 
          'image': img,
          'class_code': widget.className  // 添加班级代码
        })
      );
      if (res.statusCode == 200) {
        final response = json.decode(res.body);
        if (response['success']) {
          _safe(() => setState(() => _aiHints[idx] = response['hint']));
          _toast('✅ AI辅导已送达');
        } else {
          _toast(response['hint'] ?? 'AI辅导请求失败');
        }
      }
    } catch (e) {
      _toast('网络连接失败，请稍后重试');
    }
  }

  Future<void> _askTeacher(int idx) async {
    final img = await _capture(_keys[idx]!);
    _wsService.sendAsk(questionIndex: idx, questionText: widget.questions[idx]['content'] ?? '', imageBase64: img ?? '');
    _toast('✅ 已发送给老师，请等待批注');
  }

  Future<String?> _capture(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final img = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes != null ? base64.encode(bytes.buffer.asUint8List()) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className}班 - ${widget.userName}'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: Icon(_showTeacherAnnotations ? Icons.visibility : Icons.visibility_off, color: Colors.white),
            label: Text(_showTeacherAnnotations ? '隐藏批注' : '查看批注', style: TextStyle(color: Colors.white)),
            onPressed: () => setState(() => _showTeacherAnnotations = !_showTeacherAnnotations),
          ),
        ],
      ),
      // 【修复】：使用 ListView.builder，哪怕 100 道题也能顺滑往下滚！
      body: ListView.builder(
        padding: EdgeInsets.only(top: 16, bottom: 40),
        itemCount: widget.questions.length,
        itemBuilder: (ctx, i) => QuestionCard(
          question: widget.questions[i], index: i, totalCount: widget.questions.length,
          whiteboardState: _whiteboards[i]!, isEraserMode: _isEraserMode, repaintKey: _keys[i]!,
          onAskAI: () => _askAI(i), onAskTeacher: () => _askTeacher(i),
          teacherAnnotation: _teacherAnnotations[i], aiHint: _aiHints[i], showTeacherAnnotation: _showTeacherAnnotations,
          onToggleEraser: () => setState(() => _isEraserMode = !_isEraserMode),
        ),
      ),
    );
  }
}