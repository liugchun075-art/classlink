import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIChatDialog extends StatefulWidget {
  final String? questionContext;
  final String? userAnswer;
  
  const AIChatDialog({
    Key? key,
    this.questionContext,
    this.userAnswer,
  }) : super(key: key);

  @override
  _AIChatDialogState createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> {
  final TextEditingController _questionController = TextEditingController();
  final AIService _aiService = AIService();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.questionContext != null) {
      _questionController.text = widget.questionContext!;
    }
  }
  
  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': question});
      _isLoading = true;
    });
    
    _questionController.clear();
    
    String response;
    if (widget.userAnswer != null) {
      response = await _aiService.explainAnswer(question, widget.userAnswer!);
    } else {
      response = await _aiService.askQuestion(question);
    }
    
    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.assistant, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'AI 学习助手',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 对话区域
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 350),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['content']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 加载指示器
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            // 输入区域
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: '输入你的问题...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendQuestion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}