import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

/// WebSocket服务 - 处理学生端和老师端的通信
class WebSocketService {
  final String className;
  final String role; // 'student' 或 'teacher'
  final String userName;
  
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // 回调函数
  Function(String, String, int, String)? onStudentAsk; // (studentName, questionText, questionIndex, imageBase64)
  Function(String, int, String)? onTeacherReply; // (content, questionIndex, imageBase64)
  Function()? onConnected;
  Function(dynamic)? onError;
  Function()? onDisconnect;
  
  WebSocketService({
    required this.className,
    required this.role,
    required this.userName,
  });
  
  /// 连接WebSocket
  void connect({String host = '192.168.1.104:8000'}) {
    final url = 'ws://$host/ws/$className/$role/$userName';
    _connectInternal(url);
}
  
  void _connectInternal(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _isConnected = false;
          _safeCallback(() {
            if (onError != null) onError!(error);
          });
          _scheduleReconnect(url);
        },
        onDone: () {
          _isConnected = false;
          _safeCallback(() {
            if (onDisconnect != null) onDisconnect!();
          });
          _scheduleReconnect(url);
        },
      );
      
      _isConnected = true;
      _safeCallback(() {
        if (onConnected != null) onConnected!();
      });
      
    } catch (e) {
      _safeCallback(() {
        if (onError != null) onError!(e);
      });
      _scheduleReconnect(url);
    }
  }
  
  void _handleMessage(String message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String?;
      
      if (type == 'student_ask' && role == 'teacher') {
        // 老师端接收学生求助
        final studentName = data['student_name'] as String? ?? '';
        final questionText = data['question_text'] as String? ?? '';
        final questionIndex = data['question_index'] as int? ?? 0;
        final imageBase64 = data['image'] as String? ?? '';
        
        _safeCallback(() {
          if (onStudentAsk != null) onStudentAsk!(studentName, questionText, questionIndex, imageBase64);
        });
      } else if (type == 'teacher_reply' && role == 'student') {
        // 学生端接收老师批注
        final content = data['content'] as String? ?? '';
        final questionIndex = data['question_index'] as int? ?? 0;
        final imageBase64 = data['image'] as String? ?? '';
        
        _safeCallback(() {
          if (onTeacherReply != null) onTeacherReply!(content, questionIndex, imageBase64);
        });
      }
    } catch (e) {
      // 忽略解析错误
    }
  }
  
  void _safeCallback(Function callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
  
  void _scheduleReconnect(String url) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 3), () {
      _connectInternal(url);
    });
  }
  
  /// 发送学生求助（学生端使用）
  void sendAsk({
    required int questionIndex,
    required String questionText,
    required String imageBase64,
  }) {
    if (!_isConnected || _channel == null) return;
    
    final message = {
      'type': 'ask',
      'question_index': questionIndex,
      'question_text': questionText,
      'image': imageBase64,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  /// 发送老师回复（老师端使用）
  void sendReply({
    required String targetStudent,
    required int questionIndex,
    required String content,
    required String imageBase64,
  }) {
    if (!_isConnected || _channel == null) return;
    
    final message = {
      'type': 'reply',
      'target_student': targetStudent,
      'question_index': questionIndex,
      'content': content,
      'image': imageBase64,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  /// 断开连接
  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _isConnected = false;
  }
}