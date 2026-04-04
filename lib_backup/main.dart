import 'package:flutter/material.dart';
import 'screens/teacher_screen.dart';
import 'screens/student_paper_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智慧课堂 ClassLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFFF5F7FA), // 现代淡灰蓝背景
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = 'student';
  final TextEditingController classCodeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;

  void login() async {
    final classCode = classCodeController.text.trim();
    final name = nameController.text.trim();

    if (classCode.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请输入班级码和姓名')));
      return;
    }

    setState(() => isLoading = true);

    try {
      if (role == 'student') {
        final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/get-paper?class_code=$classCode'));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // 💡 终极安全解析：使用 Dart 的空安全符 ?，哪怕没有这个字段也绝对不崩溃
          List<dynamic> rawQuestions = [];
          
          if (data != null) {
            if (data['questions'] != null) {
               rawQuestions = data['questions'];
            } else if (data['paper'] != null && data['paper']['questions'] != null) {
               rawQuestions = data['paper']['questions'];
            } else if (data['data'] != null && data['data']['questions'] != null) {
               rawQuestions = data['data']['questions'];
            }
          }

          if (rawQuestions.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => StudentPaperScreen(
                className: classCode,
                userName: name,
                questions: List<Map<String, dynamic>>.from(rawQuestions),
              ),
            ));
          } else {
            // 如果后端返回了 false，或者试卷为空，弹出安全提示
            String errorMsg = (data != null && data['message'] != null) ? data['message'] : '老师尚未下发试卷，请稍后再试';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取试卷失败，请检查网络或班级码')));
        }
      } else {
        // 老师端直接跳转
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TeacherScreen(className: classCode, userName: name),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('网络连接错误: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 角色选择卡片组件
  Widget _buildRoleCard(String title, String value, IconData icon, Color color) {
    bool isSelected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: isSelected ? color : Colors.grey.shade400),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.indigo.shade50, Colors.white]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 区域
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)]),
                    child: Icon(Icons.menu_book_rounded, size: 60, color: Colors.indigo),
                  ),
                  SizedBox(height: 24),
                  Text('智慧课堂 ClassLink', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.indigo.shade900)),
                  SizedBox(height: 8),
                  Text('随时随地，师生同频互动', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  SizedBox(height: 48),

                  // 身份选择
                  Row(
                    children: [
                      _buildRoleCard('我是学生', 'student', Icons.face, Colors.blue),
                      SizedBox(width: 16),
                      _buildRoleCard('我是老师', 'teacher', Icons.school, Colors.orange),
                    ],
                  ),
                  SizedBox(height: 32),

                  // 输入框
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                    child: TextField(
                      controller: classCodeController,
                      decoration: InputDecoration(hintText: '输入班级码 (如: 111)', prefixIcon: Icon(Icons.meeting_room, color: Colors.indigo.shade300), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(hintText: '输入您的姓名', prefixIcon: Icon(Icons.badge, color: Colors.indigo.shade300), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  SizedBox(height: 40),

                  // 登录按钮
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('进入课堂', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}