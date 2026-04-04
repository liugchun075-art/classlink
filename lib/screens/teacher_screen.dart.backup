import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import '../services/websocket_service.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class TeacherScreen extends StatefulWidget {
  final String className;
  final String userName;
  const TeacherScreen({Key? key, required this.className, required this.userName}) : super(key: key);
  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class StudentAsk {
  final String studentName;
  final String questionText;
  final int questionIndex;
  final String imageBase64;
  final DateTime timestamp;
  StudentAsk({required this.studentName, required this.questionText, required this.questionIndex, required this.imageBase64, required this.timestamp});
}

class _TeacherScreenState extends State<TeacherScreen> {
  late WebSocketService _wsService;
  final List<StudentAsk> _studentAsks = [];
  final Map<String, bool> _repliedStatus = {};
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _wsService = WebSocketService(className: widget.className, role: 'teacher', userName: widget.userName);
    _wsService.onStudentAsk = (name, txt, idx, img) => setState(() => _studentAsks.insert(0, StudentAsk(studentName: name, questionText: txt, questionIndex: idx, imageBase64: img, timestamp: DateTime.now())));
    _wsService.connect();
  }

  void _showAnnotationDialog(StudentAsk ask) {
    showDialog(
      context: context,
      useSafeArea: false, 
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('批注 ${ask.studentName} 的第 ${ask.questionIndex + 1} 题'),
            backgroundColor: Colors.red.shade700,
            leading: IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
          body: _TeacherAnnotationWidget(
            studentImageBase64: ask.imageBase64,
            onSend: (combinedBase64) {
              _wsService.sendReply(targetStudent: ask.studentName, questionIndex: ask.questionIndex, content: '老师已批注', imageBase64: combinedBase64);
              setState(() => _repliedStatus['${ask.studentName}-${ask.questionIndex}'] = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 批注已成功发送给学生')));
            },
          ),
        ),
      ),
    );
  }

  Future<void> _upload(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      final req = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/analyze-paper?class_code=${widget.className}'));
      req.files.add(http.MultipartFile.fromBytes('file', await file.readAsBytes(), filename: 'paper.jpg'));
      final res = await req.send();
      final data = json.decode(await res.stream.bytesToString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['success'] ? '✅ 试卷下发成功！' : '❌ 上传失败')));
    } catch (e) {} finally { setState(() => _isUploading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className}班 - 教师控制台'),
        backgroundColor: Colors.indigo,
        actions: [
          if (_isUploading) Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
      body: _studentAsks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 100, color: Colors.indigo.shade200),
                  SizedBox(height: 20),
                  Text('暂无学生提问', style: TextStyle(fontSize: 22, color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('请先上传试卷，学生才能开始作答', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  SizedBox(height: 40),
                  
                  // 【修复】：高对比度、极其清晰的上传按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _upload(ImageSource.gallery),
                        icon: Icon(Icons.photo_library), 
                        label: Text('相册选图'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, 
                          foregroundColor: Colors.indigo,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => _upload(ImageSource.camera),
                        icon: Icon(Icons.camera_alt), 
                        label: Text('拍照试卷'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo, // 深蓝底
                          foregroundColor: Colors.white,  // 纯白字
                          elevation: 4,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _studentAsks.length,
              itemBuilder: (ctx, i) {
                final ask = _studentAsks[i];
                final isReplied = _repliedStatus['${ask.studentName}-${ask.questionIndex}'] == true;
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(backgroundColor: isReplied ? Colors.green.shade100 : Colors.indigo.shade100, child: Icon(Icons.person, color: isReplied ? Colors.green : Colors.indigo)),
                    title: Text('${ask.studentName} 提问了第 ${ask.questionIndex + 1} 题', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('时间: ${ask.timestamp.hour}:${ask.timestamp.minute.toString().padLeft(2, '0')}'),
                    trailing: ElevatedButton.icon(
                      icon: Icon(isReplied ? Icons.check : Icons.edit, size: 18),
                      label: Text(isReplied ? '已解答' : '去批注'),
                      style: ElevatedButton.styleFrom(backgroundColor: isReplied ? Colors.green : Colors.redAccent, foregroundColor: Colors.white, shape: StadiumBorder()),
                      onPressed: () => _showAnnotationDialog(ask),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TeacherAnnotationWidget extends StatefulWidget {
  final String studentImageBase64;
  final Function(String) onSend;
  const _TeacherAnnotationWidget({required this.studentImageBase64, required this.onSend});
  @override
  __TeacherAnnotationWidgetState createState() => __TeacherAnnotationWidgetState();
}

class __TeacherAnnotationWidgetState extends State<_TeacherAnnotationWidget> {
  final SignatureController _sigCtrl = SignatureController(penStrokeWidth: 4, penColor: Colors.red, exportBackgroundColor: Colors.transparent);
  final GlobalKey _captureKey = GlobalKey(); 

  Future<void> _captureAndSend() async {
    if (_sigCtrl.isEmpty) return;
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final img = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        widget.onSend(base64.encode(bytes.buffer.asUint8List()));
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('💡 可双指缩放，用手指红笔批改', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  OutlinedButton.icon(onPressed: _sigCtrl.clear, icon: Icon(Icons.delete_outline), label: Text('清空')),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _captureAndSend, 
                    icon: Icon(Icons.send), label: Text('发给学生'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade200,
            child: InteractiveViewer(
              minScale: 1.0, maxScale: 4.0,
              child: Center(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 底图：学生发来的原图
                        Image.memory(base64.decode(widget.studentImageBase64), fit: BoxFit.contain),
                        // 顶层：红笔画板
                        Positioned.fill(child: Signature(controller: _sigCtrl, backgroundColor: Colors.transparent)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}