import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class HandwritingInput extends StatefulWidget {
  final Function(Uint8List?)? onImageSaved;
  final Uint8List? initialImage;
  final double height;
  final Color penColor;

  const HandwritingInput({
    super.key,
    this.onImageSaved,
    this.initialImage,
    this.height = 150,
    this.penColor = Colors.black,
  });

  @override
  State<HandwritingInput> createState() => _HandwritingInputState();
}

class _HandwritingInputState extends State<HandwritingInput> {
  late SignatureController _controller;
  Uint8List? _savedImage;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: widget.penColor,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _savedImage = null;
    });
    if (widget.onImageSaved != null) {
      widget.onImageSaved!(null);
    }
  }

  Future<void> _save() async {
    final image = await _controller.toImage();
    if (image != null) {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      setState(() {
        _savedImage = bytes?.buffer.asUint8List();
      });
      if (widget.onImageSaved != null) {
        widget.onImageSaved!(_savedImage);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('手写内容已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
            width: double.infinity,
            height: widget.height,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('清空'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('保存'),
            ),
          ],
        ),
        if (_savedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.memory(_savedImage!),
            ),
          ),
      ],
    );
  }
}