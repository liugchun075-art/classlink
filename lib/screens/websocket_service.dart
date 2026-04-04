import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

/// WebSocket服务类
class WebSocketService {
  WebSocketChannel? _channel;
  Function(String)? onMessage;
  Function(dynamic)? onError;
  Function()? onDisconnect;
  Function()? onConnected;
  
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  String? _url;
  
  bool get isConnected => _channel != null;
  
  /// 连接WebSocket
  void connect(String url) {
    _url = url;
    _connectInternal();
  }
  
  void _connectInternal() {
    if (_isDisposed || _url == null) return;
    
    try {
      print('[WebSocket] 正在连接: $_url');
      _channel = WebSocketChannel.connect(Uri.parse(_url!));
      print('[WebSocket] 连接建立成功');
      
      _channel!.stream.listen(
        (message) {
          print('[WebSocket] 收到消息，长度: ${message.length} 字符');
          _safeCallback(() {
            if (onMessage != null) onMessage!(message);
          });
        },
        onError: (error) {
          print('[WebSocket] 连接错误: $error');
          _safeCallback(() {
            if (onError != null) onError!(error);
          });
          _scheduleReconnect();
        },
        onDone: () {
          print('[WebSocket] 连接断开');
          _safeCallback(() {
            if (onDisconnect != null) onDisconnect!();
          });
          _scheduleReconnect();
        },
      );
      
      _safeCallback(() {
        print('[WebSocket] 连接成功回调');
        if (onConnected != null) onConnected!();
      });
      
    } catch (e) {
      print('[WebSocket] 连接失败: $e');
      _safeCallback(() {
        if (onError != null) onError!(e);
      });
      _scheduleReconnect();
    }
  }
  
  void _safeCallback(Function callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        callback();
      }
    });
  }
  
  void _scheduleReconnect() {
    if (_isDisposed) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      if (!_isDisposed) _connectInternal();
    });
  }
  
  /// 发送消息
  void send(String message) {
    print('[WebSocket] 准备发送消息: ${message.length} 字符');
    if (_channel != null) {
      try {
        print('[WebSocket] 实际发送消息: $message');
        _channel!.sink.add(message);
        print('[WebSocket] 消息发送成功');
      } catch (e) {
        print('[WebSocket] 消息发送失败: $e');
        _safeCallback(() {
          if (onError != null) onError!(e);
        });
      }
    } else {
      print('[WebSocket] 错误: WebSocket通道为空，无法发送消息');
    }
  }
  
  /// 发送JSON消息
  void sendJson(Map<String, dynamic> data) {
    final message = json.encode(data);
    send(message);
  }
  
  /// 断开连接
  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    try {
      _channel?.sink.close();
    } catch (e) {
      print('[WebSocket] 关闭错误: $e');
    }
  }
}

/// 问老师消息构建器
class AskTeacherMessageBuilder {
  /// 构建问老师消息
  static Map<String, dynamic> build({
    required String className,
    required String userName,
    required int questionIndex,
    required String questionText,
    String imageBase64 = '',
  }) {
    return {
      'type': 'ask',
      'class_code': className,
      'user_name': userName,
      'question_index': questionIndex,
      'question_text': questionText.length > 200 ? questionText.substring(0, 200) + '...' : questionText,
      'image': imageBase64,
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
    };
  }
}

/// AI分析消息构建器
class AskAIMessageBuilder {
  /// 构建AI分析消息
  static Map<String, dynamic> build({
    required String className,
    required String userName,
    required int questionIndex,
    required String questionText,
    String imageBase64 = '',
  }) {
    return {
      'type': 'ai_analysis',
      'class_code': className,
      'user_name': userName,
      'question_index': questionIndex,
      'question_text': questionText,
      'image': imageBase64,
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
    };
  }
}