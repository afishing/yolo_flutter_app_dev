import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo_example/presentation/models/drill_task.dart';

/// 拍照采集屏幕 — 使用 YOLOView 实时检测，拍照时同步截取当前帧的检测结果。
///
/// 实时检测的 [YOLOResult] 通过 [YOLOView.onResult] 持续回调，
/// 拍照时通过 [YOLOViewController.capturePhoto] 获取原始 JPEG，
/// 同时将最新一帧的检测列表与照片绑定存储。
class BladeCaptureScreen extends StatefulWidget {
  final DrillTask task;
  final int bladeIndex;

  const BladeCaptureScreen({
    super.key,
    required this.task,
    required this.bladeIndex,
  });

  @override
  State<BladeCaptureScreen> createState() => _BladeCaptureScreenState();
}

class _BladeCaptureScreenState extends State<BladeCaptureScreen> {
  late final YOLOViewController _controller;
  final bool _ownsController = true;

  /// 最新一帧的实时检测结果（拍照时与照片绑定）。
  List<YOLOResult> _latestDetections = const [];

  /// 模型是否已加载完成。
  bool _modelLoaded = false;

  /// 拍照闪光动画控制。
  bool _flash = false;

  BladeData get _blade => widget.task.blades[widget.bladeIndex];

  @override
  void initState() {
    super.initState();
    _controller = YOLOViewController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ── 拍照 ────────────────────────────────────────────────

  Future<void> _capture() async {
    if (!_modelLoaded || !_controller.isInitialized) {
      _showSnack('模型正在加载中，请稍候');
      return;
    }

    // 截取原始照片（不含叠加框）
    final Uint8List? bytes = await _controller.capturePhoto(
      withOverlays: false,
    );
    if (bytes == null) {
      _showSnack('拍照失败，请重试');
      return;
    }

    // 闪光动画
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _flash = false);
    });

    // 将照片与当前帧的检测结果绑定存储
    setState(() {
      _blade.photos.add(
        CapturedPhoto(
          imageBytes: bytes,
          detections: List.of(_latestDetections),
        ),
      );
    });
  }

  // ── 完成拍照 → 下一个刀翼或返回首页 ──────────────────

  void _finishCapture() {
    final isLastBlade = widget.bladeIndex >= widget.task.bladeCount - 1;

    if (isLastBlade) {
      // 所有刀翼拍照完成 → 返回首页（首页已持有 task 引用）
      Navigator.of(context).pop();
    } else {
      // 还有更多刀翼 → 进入下一个刀翼拍照
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BladeCaptureScreen(
            task: widget.task,
            bladeIndex: widget.bladeIndex + 1,
          ),
        ),
      );
    }
  }

  // ── UI ──────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 实时检测画面
          YOLOView(
            modelPath: 'yolo26n',
            task: YOLOTask.detect,
            controller: _controller,
            onResult: (results) {
              _latestDetections = results;
            },
            onModelLoad: (path, task) {
              if (mounted) setState(() => _modelLoaded = true);
            },
          ),

          // 顶部信息栏
          _buildTopBar(),

          // 模型加载指示
          if (!_modelLoaded) _buildLoadingOverlay(),

          // 底部操作栏
          _buildBottomBar(),

          // 拍照闪光
          if (_flash)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }

  // ── 顶部信息栏 ──────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.precision_manufacturing, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '钻头 ${widget.task.drillBitNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '刀翼 ${_blade.bladeNumber}/${widget.task.bladeCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 加载指示 ────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载检测模型...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ── 底部操作栏 ──────────────────────────────────────────

  Widget _buildBottomBar() {
    final photoCount = _blade.photos.length;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 缩略图条
              if (photoCount > 0) ...[
                SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoCount,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            _blade.photos[i].imageBytes,
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 按钮行
              Row(
                children: [
                  // 已拍数量
                  if (photoCount > 0)
                    Text(
                      '已拍 $photoCount 张',
                      style: const TextStyle(color: Colors.white70),
                    )
                  else
                    const Text('点击拍照', style: TextStyle(color: Colors.white70)),
                  const Spacer(),

                  // 完成拍照按钮
                  if (photoCount > 0)
                    FilledButton.icon(
                      onPressed: _finishCapture,
                      icon: const Icon(Icons.check),
                      label: const Text('完成拍照'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // 拍照按钮
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.tonalIcon(
                  onPressed: _capture,
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text('拍照', style: TextStyle(fontSize: 18)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
