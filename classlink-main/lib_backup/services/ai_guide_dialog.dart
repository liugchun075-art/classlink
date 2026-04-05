import 'package:flutter/material.dart';
import '../services/ai_guide_service.dart';

class AIGuideDialog extends StatefulWidget {
  final String question;
  final String studentAnswer;
  final int attemptCount;
  
  const AIGuideDialog({
    Key? key,
    required this.question,
    required this.studentAnswer,
    required this.attemptCount,
  }) : super(key: key);

  @override
  _AIGuideDialogState createState() => _AIGuideDialogState();
}

class _AIGuideDialogState extends State<AIGuideDialog> {
  final AIGuideService _aiService = AIGuideService();
  String _guidance = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _getGuidance();
  }
  
  Future<void> _getGuidance() async {
    setState(() => _isLoading = true);
    final guidance = await _aiService.getGuidance(
      widget.question,
      widget.studentAnswer,
      widget.attemptCount,
    );
    setState(() {
      _guidance = guidance;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assistant, color: Colors.purple, size: 32),
                SizedBox(width: 12),
                Text(
                  'AI 学习助手',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '你的答案：',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      widget.studentAnswer.isEmpty 
                          ? '（还未作答）' 
                          : widget.studentAnswer,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('AI正在分析你的答案...'),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 引导提示',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _guidance,
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                    if (widget.attemptCount >= 3 && _guidance.contains('老师'))
                      SizedBox(height: 12),
                    if (widget.attemptCount >= 3 && _guidance.contains('老师'))
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 这里可以触发"问老师"功能
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text('现在问老师'),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('继续思考'),
                ),
                SizedBox(width: 8),
                if (!_isLoading)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _getGuidance(); // 重新获取提示
                    },
                    child: Text('再问一次'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}