import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'student_paper_screen.dart';
import 'teacher_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'student';
  String _className = '';
  String _userName = '';

  void _showNoPaperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('暂无试卷'),
        content: Text('老师还没有上传试卷，请等待老师上传后再进入。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(labelText: '角色'),
                items: ['student', 'teacher']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e == 'student' ? '学生' : '老师')))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: '课堂码'),
                onChanged: (v) => _className = v,
                validator: (v) => v!.isEmpty ? '请输入课堂码' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: '姓名'),
                onChanged: (v) => _userName = v,
                validator: (v) => v!.isEmpty ? '请输入姓名' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_role == 'student') {
                      try {
                        final response = await http.get(
                          Uri.parse('http://127.0.0.1:8000/api/get-paper?class_code=$_className'),
                        );
                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          if (data['success'] && data['questions'].isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentPaperScreen(
                                  className: _className,
                                  userName: _userName,
                                  questions: List<Map<String, dynamic>>.from(data['questions']),
                                ),
                              ),
                            );
                          } else {
                            _showNoPaperDialog();
                          }
                        } else {
                          _showNoPaperDialog();
                        }
                      } catch (e) {
                        _showNoPaperDialog();
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherScreen(
                            className: _className,
                            userName: _userName,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text('进入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}