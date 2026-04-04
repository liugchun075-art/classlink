import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

// ==================== 修复一：独立画板组件 ====================

// 笔画数据结构
class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  
  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}

// 画板状态管理
class WhiteboardState {
  final List<Stroke> strokes = [];
  final ValueNotifier<List<Stroke>> strokesNotifier = ValueNotifier([]);
  
  void addStroke(Stroke stroke) {
    strokes.add(stroke);
    strokesNotifier.value = List.from(strokes);
  }
  
  void updateLastStroke(Offset point) {
    if (strokes.isNotEmpty) {
      strokes.last.points.add(point);
      strokesNotifier.value = List.from(strokes);
    }
  }
  
  void clear() {
    strokes.clear();
    strokesNotifier.value = [];
  }
}

// 修复后的画板绘制器
class FixedWhiteboardPainter extends CustomPainter {
  final List<Stroke> strokes;
  
  FixedWhiteboardPainter(this.strokes);
  
  @override
  void paint(Canvas canvas, Size size) {
    // ✅ 修复四：使用saveLayer支持橡皮擦的BlendMode.clear
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
    
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      // ✅ 修复四：橡皮擦模式使用正确的blendMode
      if (stroke.isEraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
      }
      
      if (stroke.points.length > 1) {
        final path = Path();
        path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
        
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        
        canvas.drawPath(path, paint);
      }
    }
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 独立画板组件（局部刷新）
class WhiteboardWidget extends StatefulWidget {
  final WhiteboardState whiteboardState;
  final bool isEraserMode;
  final Color currentColor;
  final double strokeWidth;
  final String? currentImageUrl;
  
  const WhiteboardWidget({
    Key? key,
    required this.whiteboardState,
    required this.isEraserMode,
    required this.currentColor,
    required this.strokeWidth,
    this.currentImageUrl,
  }) : super(key: key);
  
  @override
  _WhiteboardWidgetState createState() => _WhiteboardWidgetState();
}

class _WhiteboardWidgetState extends State<WhiteboardWidget> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          color: Colors.grey[200],
          child: Stack(
            children: [
              // 背景网格（静态，不会重绘）
              CustomPaint(
                painter: _StaticGridPainter(),
              ),
              
              // 题目图片（如果有）
              if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)
                Positioned(
                  top: 20,
                  left: 20,
                  child: ErrorBoundary(
                    child: Image.network(
                      widget.currentImageUrl!,
                      width: 200,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey[500]),
                                SizedBox(height: 8),
                                Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              // ✅ 修复三：使用ValueListenableBuilder实现局部刷新
              ValueListenableBuilder<List<Stroke>>(
                valueListenable: widget.whiteboardState.strokesNotifier,
                builder: (context, strokes, child) {
                  return CustomPaint(
                    painter: FixedWhiteboardPainter(strokes),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _onPanStart(DragStartDetails details) {
    widget.whiteboardState.addStroke(Stroke(
      points: [details.localPosition],
      color: widget.isEraserMode ? Colors.transparent : widget.currentColor,
      strokeWidth: widget.strokeWidth,
      isEraser: widget.isEraserMode,
    ));
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    // ✅ 修复三：只更新画板状态，不触发外层setState
    widget.whiteboardState.updateLastStroke(details.localPosition);
  }
  
  void _onPanEnd(DragEndDetails details) {
    // 可以在这里保存笔画或发送到服务器
  }
}

// 静态网格绘制器（不会重绘）
class _StaticGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;
    
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== 错误边界组件 ====================

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const ErrorBoundary({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget.builder(
      (FlutterErrorDetails details) {
        return Container(
          padding: EdgeInsets.all(16),
          color: Colors.red[50],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 12),
              Text(
                '组件渲染错误',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                style: TextStyle(color: Colors.red[600]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

// ==================== 修复后的WebSocket服务（带重连） ====================

class StableWebSocketService {
  WebSocketChannel? _channel;
  Function(String)? onMessage;
  Function(dynamic)? onError;
  Function()? onDisconnect;
  Function()? onReconnect;
  
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _isDisposed = false;
  String _url = '';
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  final Duration _initialReconnectDelay = Duration(seconds: 1);
  final Duration _maxReconnectDelay = Duration(seconds: 30);
  
  void connect(String url) {
    if (_isConnecting) return;
    
    _url = url;
    _isConnecting = true;
    _reconnectAttempts = 0;
    
    _connectInternal();
  }
  
  void _connectInternal() {
    if (_isDisposed) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      
      _channel!.stream.listen(
        (message) {
          _reconnectAttempts = 0; // 重置重连计数
          
          // ✅ 安全调用回调
          _safeCallback(() {
            if (onMessage != null) {
              onMessage!(message);
            }
          });
        },
        onError: (error) {
          _isConnecting = false;
          
          // ✅ 安全调用回调
          _safeCallback(() {
            if (onError != null) {
              onError!(error);
            }
          });
          
          _scheduleReconnect();
        },
        onDone: () {
          _isConnecting = false;
          
          // ✅ 安全调用回调
          _safeCallback(() {
            if (onDisconnect != null) {
              onDisconnect!();
            }
          });
          
          _scheduleReconnect();
        },
      );
      
      _isConnecting = false;
      _reconnectAttempts = 0;
      
    } catch (e) {
      _isConnecting = false;
      _safeCallback(() {
        if (onError != null) {
          onError!(e);
        }
      });
      
      _scheduleReconnect();
    }
  }
  
  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _reconnectTimer?.cancel();
    
    _reconnectAttempts++;
    
    // 指数退避重连策略
    final delay = Duration(
      milliseconds: (_initialReconnectDelay.inMilliseconds * 
        (1 << (_reconnectAttempts - 1))).clamp(
          _initialReconnectDelay.inMilliseconds,
          _maxReconnectDelay.inMilliseconds
        )
    );
    
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        _safeCallback(() {
          if (onReconnect != null) {
            onReconnect!();
          }
        });
        _connectInternal();
      }
    });
  }
  
  // ✅ 安全回调包装器
  void _safeCallback(Function callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }
  
  void send(String message) {
    if (_channel != null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        _safeCallback(() {
          if (onError != null) {
            onError!(e);
          }
        });
      }
    }
  }
  
  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    try {
      _channel?.sink.close();
    } catch (e) {
      // 忽略关闭时的错误
    }
  }
  
  bool get isConnected => _channel != null;
}

// ==================== 修复后的主屏幕 ====================

class StudentPaperScreen extends StatefulWidget {
  final String className;
  final String userName;
  final List<Map<String, dynamic>> questions;
  
  const StudentPaperScreen({
    Key? key,
    required this.className,
    required this.userName,
    required this.questions,
  }) : super(key: key);

  @override
  _StudentPaperScreenState createState() => _StudentPaperScreenState();
}

class _StudentPaperScreenState extends State<StudentPaperScreen> {
  final StableWebSocketService _webSocketService = StableWebSocketService();
  final WhiteboardState _whiteboardState = WhiteboardState();
  bool _isLoading = true;
  bool _isAskingAI = false;
  bool _isAskingTeacher = false;
  bool _isEraserMode = false;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  String? _currentQuestion;
  String? _currentImageUrl;
  String? _aiResponse;
  String? _teacherResponse;
  bool _isWebSocketConnected = false;
  
  @override
  void initState() {
    super.initState();
    
    // ✅ 设置WebSocket回调
    _webSocketService.onMessage = (message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        try {
          final data = json.decode(message);
          if (data['type'] == 'ai_response') {
            setState(() {
              _aiResponse = data['content'];
            });
            
            _safeShowSnackBar('AI已回答');
          } else if (data['type'] == 'teacher_response') {
            setState(() {
              _teacherResponse = data['content'];
            });
            
            _safeShowSnackBar('老师已回答');
          } else if (data['type'] == 'connection_status') {
            setState(() {
              _isWebSocketConnected = data['connected'] ?? false;
            });
          }
        } catch (e) {
          print('WebSocket消息解析错误: $e');
        }
      });
    };
    
    _webSocketService.onError = (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _safeShowSnackBar('连接错误: $error', isError: true);
      });
    };
    
    _webSocketService.onDisconnect = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isWebSocketConnected = false;
        });
        _safeShowSnackBar('连接断开', isWarning: true);
      });
    };
    
    _webSocketService.onReconnect = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _safeShowSnackBar('正在重新连接...', isWarning: true);
      });
    };
    
    // 连接WebSocket
    _webSocketService.connect('ws://localhost:8080/ws');
    
    // 加载初始数据
    _loadInitialData();
  }
  
  // ✅ 安全的SnackBar显示
  void _safeShowSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : (isWarning ? Colors.orange : null),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }
  
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  
  Future<void> _loadInitialData() async {
    try {
      // 使用传入的questions数据
      setState(() {
        _questions = widget.questions;
        _isLoading = false;
        if (_questions.isNotEmpty) {
          _updateCurrentQuestion();
        } else {
          _currentQuestion = '暂无题目';
          _currentImageUrl = null;
        }
      });
    } catch (e) {
      // ✅ 使用try-catch-finally
      _safeShowSnackBar('加载失败: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _updateCurrentQuestion() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;
    
    final question = _questions[_currentQuestionIndex];
    
    setState(() {
      _currentQuestion = question['content'] ?? '暂无题目';
      _currentImageUrl = question['image_url'] ?? question['imageUrl'] ?? '';
      _aiResponse = null;
      _teacherResponse = null;
    });
  }
  
  Future<void> _askAI() async {
    // ✅ 严格的try-catch-finally结构
    setState(() {
      _isAskingAI = true;
    });
    
    try {
      // 获取当前题目ID
      String? questionId;
      if (_questions.isNotEmpty && _currentQuestionIndex < _questions.length) {
        questionId = _questions[_currentQuestionIndex]['id']?.toString();
      }
      
      // 模拟AI请求
      await Future.delayed(Duration(seconds: 3));
      
      if (DateTime.now().millisecond % 3 == 0) {
        throw Exception('AI服务暂时不可用');
      }
      
      // 模拟AI回答
      setState(() {
        _aiResponse = 'AI分析完成。题目ID: ${questionId ?? "未知"}\n\n建议解答思路: 这是一个基础的积分问题，可以使用幂函数积分公式求解。';
      });
      
      _safeShowSnackBar('AI分析完成');
    } catch (e) {
      // ✅ 必须处理错误并提示
      _safeShowSnackBar('AI分析失败: $e', isError: true);
    } finally {
      // ✅ 绝对必须重置状态
      if (mounted) {
        setState(() {
          _isAskingAI = false;
        });
      }
    }
  }
  
  Future<void> _askTeacher() async {
    // ✅