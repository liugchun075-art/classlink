import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/websocket_service.dart';

class TeacherScreen extends StatefulWidget {
  final String className;
  final String userName;

  TeacherScreen({required this.className, required this.userName});

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  late WebSocketService _wsService;
  List<Map<String, dynamic>> _asks = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _wsService = WebSocketService(
      className: widget.className,
      role: 'teacher',
      userName: widget.userName,
    );
    _wsService.connect();
    _wsService.onStudentAsk = (studentName, questionIndex, questionText, imageBase64) {
      setState(() {
        _asks.add({
          'studentName': studentName,
          'questionIndex': questionIndex,
          'questionText': questionText,
          'imageBase64': imageBase64
        });
      });
    };
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  Future<void> _uploadPaper() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    await _uploadFile(pickedFile);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    await _uploadFile(pickedFile);
  }

  Future<void> _uploadFile(XFile pickedFile) async {
    setState(() => _isUploading = true);
    try {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      var uri = Uri.parse('http://127.0.0.1:8000/api/analyze-paper?class_code=${widget.className}');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'paper.jpg'));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = jsonDecode(responseData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['success'] ? '上传成功！' : '上传失败：${result['message']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败：$e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _openMarkDialog(Map<String, dynamic> ask) {
    showDialog(
      context: context,
      builder: (context) => TeacherMarkDialog(
        studentName: ask['studentName'],
        questionText: ask['questionText'],
        studentImageBase64: ask['imageBase64'],
        onSend: (imageBase64) {
          _wsService.sendReply(ask['studentName'], imageBase64, questionIndex: ask['questionIndex']);
          setState(() => _asks.remove(ask));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('老师端 - ${widget.className}'),
        actions: [
          IconButton(icon: Icon(Icons.upload_file), onPressed: _uploadPaper, tooltip: '上传试卷'),
          IconButton(icon: Icon(Icons.camera_alt), onPressed: _takePhoto, tooltip: '拍照上传'),
        ],
      ),
      body: _asks.isEmpty
          ? Center(child: Text('暂无求助'))
          : ListView.builder(
              itemCount: _asks.length,
              itemBuilder: (context, index) {
                final ask = _asks[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${ask['questionIndex'] ?? '?'}')),
                    title: Text(ask['studentName']),
                    subtitle: Text(ask['questionText'] ?? '题目'),
                    trailing: ElevatedButton(
                      child: Text('批注'),
                      onPressed: () => _openMarkDialog(ask),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TeacherMarkDialog extends StatefulWidget {
  final String studentName;
  final String? questionText;
  final String studentImageBase64;
  final Function(String) onSend;

  const TeacherMarkDialog({
    Key? key,
    required this.studentName,
    this.questionText,
    required this.studentImageBase64,
    required this.onSend,
  }) : super(key: key);

  @override
  _TeacherMarkDialogState createState() => _TeacherMarkDialogState();
}

class _TeacherMarkDialogState extends State<TeacherMarkDialog> {
  late SignatureController _signatureController;
  final GlobalKey _markKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penColor: Colors.red,
      penStrokeWidth: 3,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _sendMark() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先批注内容')));
      return;
    }
    try {
      final boundary = _markKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      widget.onSend(base64Encode(pngBytes));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发送失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text('批注学生：${widget.studentName}', style: const TextStyle(fontSize: 18)),
            if (widget.questionText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('题目：${widget.questionText}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: RepaintBoundary(
                key: _markKey,
                child: Container(
                  width: 800,
                  height: 600,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      if (widget.studentImageBase64.isNotEmpty)
                        Image.memory(base64Decode(widget.studentImageBase64), width: 800, height: 600, fit: BoxFit.contain),
                      Signature(
                        controller: _signatureController,
                        width: 800,
                        height: 600,
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => _signatureController.clear(), child: const Text('清空')),
                const SizedBox(width: 20),
                ElevatedButton(onPressed: _sendMark, child: const Text('发送批注')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}