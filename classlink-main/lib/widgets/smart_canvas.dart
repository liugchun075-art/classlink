import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';

enum DrawMode { pen, eraser }

class SmartCanvasController {
  late SignatureController _signatureController;
  final GlobalKey _canvasKey = GlobalKey();
  DrawMode _drawMode = DrawMode.pen;
  
  SmartCanvasController({Color penColor = Colors.black}) {
    _signatureController = SignatureController(
      penColor: penColor,
      penStrokeWidth: 3,
      exportBackgroundColor: Colors.transparent,
    );
  }

  SignatureController get controller => _signatureController;
  DrawMode get drawMode => _drawMode;
  
  void setDrawMode(DrawMode mode) {
    _drawMode = mode;
    // 由于不能动态修改，我们重新创建控制器
    final oldPoints = _signatureController.points;
    _signatureController.dispose();
    
    if (mode == DrawMode.eraser) {
      _signatureController = SignatureController(
        penColor: Colors.white,
        penStrokeWidth: 20,
        exportBackgroundColor: Colors.transparent,
      );
    } else {
      _signatureController = SignatureController(
        penColor: Colors.black,
        penStrokeWidth: 3,
        exportBackgroundColor: Colors.transparent,
      );
    }
    // 恢复原有的笔迹
    _signatureController.points = oldPoints;
  }
  
  void toggleEraser() {
    if (_drawMode == DrawMode.pen) {
      setDrawMode(DrawMode.eraser);
    } else {
      setDrawMode(DrawMode.pen);
    }
  }

  void clear() {
    _signatureController.clear();
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

  void dispose() {
    _signatureController.dispose();
  }
}

class SmartCanvas extends StatefulWidget {
  final double width;
  final double height;
  final Color backgroundColor;
  final Widget backgroundWidget;
  final Color penColor;
  final SmartCanvasController controller;
  final Uint8List? teacherMarkImage;
  final bool showTeacherMark;

  SmartCanvas({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.backgroundWidget,
    required this.penColor,
    required this.controller,
    this.teacherMarkImage,
    this.showTeacherMark = true,
  });

  @override
  _SmartCanvasState createState() => _SmartCanvasState();
}

class _SmartCanvasState extends State<SmartCanvas> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller._canvasKey,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
        child: Stack(
          children: [
            widget.backgroundWidget,
            Signature(
              controller: widget.controller.controller,
              width: widget.width,
              height: widget.height,
              backgroundColor: Colors.transparent,
            ),
            if (widget.teacherMarkImage != null && widget.showTeacherMark)
              Positioned.fill(
                child: Image.memory(widget.teacherMarkImage!, fit: BoxFit.fill),
              ),
          ],
        ),
      ),
    );
  }
}