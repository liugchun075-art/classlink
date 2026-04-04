import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';

class SmartCanvasController {
  final SignatureController _signatureController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.transparent,
  );
  final GlobalKey _canvasKey = GlobalKey();

  SignatureController get controller => _signatureController;

  void clear() {
    _signatureController.clear();
  }

  Future<Uint8List?> captureImage() async {
    final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void dispose() {
    _signatureController.dispose();
  }
}

class SmartCanvas extends StatefulWidget {
  final double width;
  final double height;
  final Color backgroundColor;
  final Widget backgroundWidget; // 题目文字等内容
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
  late SignatureController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller.controller;
    // penColor 是 final 的，不能在运行时修改
    // 如果需要不同颜色，需要创建新的控制器
  }

  @override
  void didUpdateWidget(SmartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // penColor 是 final 的，不能在运行时修改
    // 如果需要不同颜色，需要创建新的控制器
  }

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
            // 背景（试卷题目）
            widget.backgroundWidget,
            // 学生笔迹
            Signature(
              controller: _internalController,
              width: widget.width,
              height: widget.height,
              backgroundColor: Colors.transparent,
            ),
            // 老师批注叠加层（透明背景）
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