import 'dart:convert';
import 'package:http/http.dart' as http;

class AIGuideService {
  static const String apiKey = 'sk-5e6df883a76b45cfb08ef47a01f78f64';
  static const String apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  Future<String> getGuidance(String question, String studentAnswer, int attemptCount) async {
    try {
      final systemPrompt = '''
你是一位经验丰富、非常有耐心的中学数学老师。你的职责是帮助学生独立思考，而不是直接给出答案。

核心原则：
1. 绝对不要直接给出答案
2. 先肯定学生已经做对的部分
3. 用提问的方式引导学生思考下一步
4. 每次提示不超过3句话
5. 语气鼓励、温和

根据题目类型调整引导方式：
- 填空题：提示计算步骤，引导学生自己算出答案
- 解答题：提示分析已知条件、找等量关系
- 应用题：提示画图、设未知数、找等量关系

如果学生已经尝试了多次（超过3次），可以建议："你已经思考了很久，要不要问问老师？老师会给你更详细的讲解。"

记住：你是引导者，不是答案提供者。''';
      
      String userPrompt;
      if (studentAnswer.isEmpty) {
        userPrompt = '''
学生刚开始做这道题，还没有写任何答案。

题目：$question

请给出简短的引导提示，帮助学生开始思考这道题。不要直接给答案，最多3句话。
''';
      } else if (attemptCount <= 2) {
        userPrompt = '''
学生做题卡住了，这是第 $attemptCount 次求助。

题目：$question
学生目前写的内容：$studentAnswer

请分析学生当前写的内容：
1. 哪里写对了？
2. 可能卡在哪个环节？
3. 给出下一步的引导提示

注意：不要直接给出答案，最多3句话。
''';
      } else {
        userPrompt = '''
学生已经尝试了 $attemptCount 次还是不太明白。

题目：$question
学生目前写的内容：$studentAnswer

请先肯定学生的努力，然后温和地建议学生可以问问老师，同时也可以给一点最后的提示。
最多3句话。
''';
      }
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'AI暂时无法响应，请稍后再试或直接问老师。';
      }
    } catch (e) {
      return '连接AI服务失败，请检查网络后重试。';
    }
  }
}