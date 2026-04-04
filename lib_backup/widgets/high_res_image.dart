import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 高分辨率图片组件
/// 支持缩放查看高清细节，保持原始分辨率
class HighResImage extends StatelessWidget {
  final Uint8List imageBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final bool enableZoom;

  const HighResImage({
    Key? key,
    required this.imageBytes,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
    this.enableZoom = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.memory(
      imageBytes,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      // 关键：不压缩，保持原始分辨率
      cacheWidth: null,
      cacheHeight: null,
    );

    // 如果启用缩放，使用InteractiveViewer包装
    if (enableZoom) {
      return InteractiveViewer(
        // 支持缩放，保证高清细节可见
        minScale: 0.5,
        maxScale: 4.0,
        panEnabled: true,
        scaleEnabled: true,
        boundaryMargin: EdgeInsets.all(20),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// 带标签的高清配图组件
/// 专门用于显示试卷中的配图
class DiagramImage extends StatelessWidget {
  final Uint8List imageBytes;
  final String diagramType;
  final String? description;
  final double height;

  const DiagramImage({
    Key? key,
    required this.imageBytes,
    required this.diagramType,
    this.description,
    this.height = 220,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          // 配图标签
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(diagramType),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getTypeIcon(diagramType),
                SizedBox(width: 4),
                Text(
                  _getTypeLabel(diagramType),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // 图片区域
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: HighResImage(
                imageBytes: imageBytes,
                enableZoom: true,
              ),
            ),
          ),
          
          // 描述文本（如果有）
          if (description != null && description!.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                description!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'circuit':
        return Colors.blue;
      case 'geometry':
        return Colors.green;
      case 'experiment':
        return Colors.orange;
      case 'chart':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _getTypeIcon(String type) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'circuit':
        icon = Icons.electrical_services;
        break;
      case 'geometry':
        icon = Icons.square_foot;
        break;
      case 'experiment':
        icon = Icons.science;
        break;
      case 'chart':
        icon = Icons.bar_chart;
        break;
      default:
        icon = Icons.image;
    }
    return Icon(icon, size: 14, color: Colors.white);
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'circuit':
        return '电路图';
      case 'geometry':
        return '几何图';
      case 'experiment':
        return '实验图';
      case 'chart':
        return '图表';
      default:
        return '配图';
    }
  }
}

/// 图片加载状态组件
class ImageLoadingWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback? onRetry;

  const ImageLoadingWidget({
    Key? key,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '图片加载失败',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 8),
                  Text('加载高清图片中...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              )
            else if (hasError)
              Column(
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text(errorMessage, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (onRetry != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: onRetry,
                        child: Text('重试', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      ),
                    ),
                ],
              )
            else
              Column(
                children: [
                  Icon(Icons.image, size: 40, color: Colors.grey[400]),
                  SizedBox(height: 8),
                  Text('示例图片', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
          ],
        ),
      ),
    );
  }
}