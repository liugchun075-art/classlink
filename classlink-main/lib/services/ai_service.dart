import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiKey = 'sk-5e6df883a76b45cfb08ef47a01f78f64';
  static const String apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  Future<String> askQuestion(String question, {String? context}) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '你是一个专业的数学老师助手，帮助学生解答问题。请用友好、耐心的语气回答，适合初高中学生理解。'
        },
        {
          'role': 'user',
          'content': context != null 
              ? '学生的问题：$question\n\n试卷上下文：$context' 
              : '学生的问题：$question'
        }
      ];
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'AI服务暂时不可用，请稍后再试。错误码：${response.statusCode}';
      }
    } catch (e) {
      return '连接AI服务失败：$e';
    }
  }
  
  Future<String> explainAnswer(String question, String userAnswer) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '你是一个专业的数学老师，帮助学生分析他们的答案是否正确，并给出详细的解答过程。'
        },
        {
          'role': 'user',
          'content': '题目：$question\n\n学生的答案：$userAnswer\n\n请分析这个答案是否正确，如果不正确，请给出正确的解题步骤。'
        }
      ];
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'AI服务暂时不可用，请稍后再试。';
      }
    } catch (e) {
      return '连接AI服务失败：$e';
    }
  }
}