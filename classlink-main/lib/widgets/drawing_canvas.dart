import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum DrawMode { pen, eraser }

class DrawingPoint {
  Offset offset;
  Paint paint;
  
  DrawingPoint(this.offset, this.paint);
}

class DrawingCanvasController {
  final GlobalKey _canvasKey = GlobalKey();
  List<List<DrawingPoint>> _paths = [];
  List<List<DrawingPoint>> _redoPaths = [];
  DrawMode _drawMode = DrawMode.pen;
  Color _penColor = Colors.black;
  double _penWidth = 3.0;
  double _eraserWidth = 20.0;
  
  List<List<DrawingPoint>> get paths => _paths;
  DrawMode get drawMode => _drawMode;
  
  void setDrawMode(DrawMode mode) {
    _drawMode = mode;
  }
  
  void toggleEraser() {
    _drawMode = _drawMode == DrawMode.pen ? DrawMode.eraser : DrawMode.pen;
  }
  
  void addPoint(Offset point) {
    if (_paths.isEmpty || _paths.last.isEmpty) {
      _paths.add([]);
    }
    
    Paint paint;
    if (_drawMode == DrawMode.pen) {
      paint = Paint()
        ..color = _penColor
        ..strokeWidth = _penWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
    } else {
      paint = Paint()
        ..color = Colors.white
        ..strokeWidth = _eraserWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.clear;
    }
    
    _paths.last.add(DrawingPoint(point, paint));
    _redoPaths.clear();
  }
  
  void startNewPath() {
    _paths.add([]);
  }
  
  void undo() {
    if (_paths.isNotEmpty) {
      _redoPaths.add(_paths.removeLast());
    }
  }
  
  void redo() {
    if (_redoPaths.isNotEmpty) {
      _paths.add(_redoPaths.removeLast());
    }
  }
  
  void clear() {
    _paths.clear();
    _redoPaths.clear();
  }
  
  Future<Uint8List?> captureImage() async {
    try {
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }
  
  void dispose() {}
}

class DrawingCanvas extends StatefulWidget {
  final double width;
  final double height;
  final Color backgroundColor;
  final Widget backgroundWidget;
  final DrawingCanvasController controller;
  final Uint8List? teacherMarkImage;
  final bool showTeacherMark;
  final Color penColor;
  final double penWidth;
  final double eraserWidth;

  DrawingCanvas({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.backgroundWidget,
    required this.controller,
    this.teacherMarkImage,
    this.showTeacherMark = true,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
    this.eraserWidth = 20.0,
  });

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Offset? _lastPoint;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: RepaintBoundary(
        key: widget.controller._canvasKey,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: widget.backgroundColor,
          child: Stack(
            children: [
              widget.backgroundWidget,
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: DrawingPainter(
                  paths: widget.controller.paths,
                ),
              ),
              if (widget.teacherMarkImage != null && widget.showTeacherMark)
                Positioned.fill(
                  child: Image.memory(widget.teacherMarkImage!, fit: BoxFit.fill),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _onPanStart(DragStartDetails details) {
    final localPosition = (context.findRenderObject() as RenderBox)
        .globalToLocal(details.globalPosition);
    widget.controller.startNewPath();
    widget.controller.addPoint(localPosition);
    _lastPoint = localPosition;
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    final localPosition = (context.findRenderObject() as RenderBox)
        .globalToLocal(details.globalPosition);
    if (_lastPoint != null) {
      double distance = (_lastPoint! - localPosition).distance;
      if (distance > 2.0) {
        int steps = (distance / 2).ceil();
        for (int i = 1; i <= steps; i++) {
          double t = i / steps;
          Offset intermediate = Offset(
            _lastPoint!.dx + (localPosition.dx - _lastPoint!.dx) * t,
            _lastPoint!.dy + (localPosition.dy - _lastPoint!.dy) * t,
          );
          widget.controller.addPoint(intermediate);
        }
      }
    }
    widget.controller.addPoint(localPosition);
    _lastPoint = localPosition;
    setState(() {});
  }
  
  void _onPanEnd(DragEndDetails details) {
    _lastPoint = null;
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> paths;
  
  DrawingPainter({required this.paths});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var pathPoints in paths) {
      if (pathPoints.isEmpty) continue;
      
      Path path = Path();
      path.moveTo(pathPoints[0].offset.dx, pathPoints[0].offset.dy);
      
      for (int i = 1; i < pathPoints.length; i++) {
        final point = pathPoints[i];
        final prevPoint = pathPoints[i - 1];
        
        final midPoint = Offset(
          (prevPoint.offset.dx + point.offset.dx) / 2,
          (prevPoint.offset.dy + point.offset.dy) / 2,
        );
        path.quadraticBezierTo(
          prevPoint.offset.dx,
          prevPoint.offset.dy,
          midPoint.dx,
          midPoint.dy,
        );
      }
      
      canvas.drawPath(path, pathPoints[0].paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}