import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  // 百度OCR API配置（需要注册百度AI开放平台获取）
  // 这里使用免费的公测API，你也可以用自己的key
  static const String apiKey = 'YOUR_BAIDU_API_KEY';
  static const String secretKey = 'YOUR_BAIDU_SECRET_KEY';
  
  // 临时使用免费的OCR API（识别手写数字）
  static Future<String> recognizeHandwriting(Uint8List imageBytes) async {
    try {
      // 将图片转为base64
      String base64Image = base64Encode(imageBytes);
      
      // 使用免费的OCR API（手写数字识别）
      // 这里使用一个免费的在线OCR服务，你也可以用自己的
      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {
          'apikey': 'helloworld', // 免费API key
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'base64Image': 'data:image/png;base64,$base64Image',
          'language': 'eng',
          'OCREngine': '2', // 使用手写识别引擎
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty) {
          String text = data['ParsedResults'][0]['ParsedText'];
          // 清理文本，只保留数字
          text = text.replaceAll(RegExp(r'[^0-9+\-*/=]'), '');
          return text.isEmpty ? '' : text;
        }
      }
      return '';
    } catch (e) {
      print('OCR Error: $e');
      return '';
    }
  }
  
  // 简单的数字识别（基于像素分析，不需要API）
  static String simpleNumberRecognition(Uint8List imageBytes) {
    // 这是一个简化的识别方法
    // 实际项目中应该使用真实的OCR服务
    // 这里返回空，让用户输入
    return '';
  }
}