import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo_example/presentation/models/drill_task.dart';


/// 刀齿选择屏幕 — 在已拍照片上点选检测框，分配刀齿编号。
///
/// 检测框来自拍照时实时监测截取的 [YOLOResult.normalizedBox]（0-1 归一化坐标），
/// 渲染时通过 [AspectRatio] 保证图片无 letterboxing，归一化坐标直接映射到渲染区域。
class ToothSelectionScreen extends StatefulWidget {
  final DrillTask task;
  final int bladeIndex;

  const ToothSelectionScreen({
    super.key,
    required this.task,
    required this.bladeIndex,
  });

  @override
  State<ToothSelectionScreen> createState() => _ToothSelectionScreenState();
}

class _ToothSelectionScreenState extends State<ToothSelectionScreen> {
  /// 当前查看的照片索引。
  int _currentPhotoIndex = 0;

  /// 已解码的图片尺寸缓存（photoIndex → Size）。
  final Map<int, Size> _imageSizes = {};

  BladeData get _blade => widget.task.blades[widget.bladeIndex];

  List<CapturedPhoto> get _photos => _blade.photos;

  /// 当前刀翼已选刀齿（直接操作 BladeData.selectedTeeth）。
  List<SelectedTooth> get _selectedTeeth => _blade.selectedTeeth;

  /// 下一个待分配的刀齿编号。
  int get _nextToothNumber => _selectedTeeth.length + 1;

  @override
  void initState() {
    super.initState();
    _decodeImages();
  }

  // ── 图片解码 ────────────────────────────────────────────

  Future<void> _decodeImages() async {
    for (var i = 0; i < _photos.length; i++) {
      try {
        final codec = await ui.instantiateImageCodec(
          _photos[i].imageBytes,
        );
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _imageSizes[i] = Size(
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            );
          });
        }
        frame.image.dispose();
      } catch (_) {
        // 忽略解码失败，该照片不显示框
      }
    }
  }

  // ── 选择/取消选择 ──────────────────────────────────────

  /// 切换某个检测框的选中状态。
  void _toggleSelection(int photoIndex, int detectionIndex) {
    final existing = _selectedTeeth.indexWhere(
      (t) => t.photoIndex == photoIndex && t.detectionIndex == detectionIndex,
    );

    setState(() {
      if (existing >= 0) {
        // 取消选择，并重新编号
        _selectedTeeth.removeAt(existing);
        _renumberTeeth();
      } else {
        // 新增选择
        _selectedTeeth.add(
          SelectedTooth(
            toothNumber: _nextToothNumber,
            photoIndex: photoIndex,
            detectionIndex: detectionIndex,
          ),
        );
      }
    });
  }

  /// 重新编号所有已选刀齿（确保从 1 开始连续）。
  void _renumberTeeth() {
    for (var i = 0; i < _selectedTeeth.length; i++) {
      _selectedTeeth[i].toothNumber = i + 1;
    }
  }

  /// 撤销最后一个选择。
  void _undoLast() {
    if (_selectedTeeth.isEmpty) return;
    setState(() {
      _selectedTeeth.removeLast();
      _renumberTeeth();
    });
  }

  /// 查找某个检测框是否已被选中，返回刀齿编号或 null。
  int? _getToothNumber(int photoIndex, int detectionIndex) {
    for (final t in _selectedTeeth) {
      if (t.photoIndex == photoIndex && t.detectionIndex == detectionIndex) {
        return t.toothNumber;
      }
    }
    return null;
  }

  // ── 完成 → 返回任务详情页 ──────────────────────────────

  void _finishBlade() {
    Navigator.of(context).pop();
  }

  // ── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('刀齿选择 — 刀翼 ${_blade.bladeNumber}/${widget.task.bladeCount}'),
        actions: [
          if (_selectedTeeth.isNotEmpty)
            TextButton.icon(
              onPressed: _undoLast,
              icon: const Icon(Icons.undo),
              label: const Text('撤销'),
            ),
        ],
      ),
      body: _photos.isEmpty
          ? const Center(child: Text('无照片'))
          : Column(
              children: [
                _buildInfoBar(),
                Expanded(child: _buildImageWithBoxes()),
                _buildPhotoStrip(),
                _buildActionBar(),
              ],
            ),
    );
  }

  // ── 信息栏 ──────────────────────────────────────────────

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.precision_manufacturing, size: 20),
          const SizedBox(width: 8),
          Text('钻头 ${widget.task.drillBitNumber}',
              style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (_selectedTeeth.isNotEmpty)
            Chip(
              label: Text('已选 ${_selectedTeeth.length} 齿'),
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              '下一编号: #$_nextToothNumber',
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
        ],
      ),
    );
  }

  // ── 图片 + 检测框 ──────────────────────────────────────

  Widget _buildImageWithBoxes() {
    if (_photos.isEmpty) return const SizedBox.shrink();

    final photo = _photos[_currentPhotoIndex];
    final detections = photo.detections;
    final imgSize = _imageSizes[_currentPhotoIndex];

    // 如果还没有解码出图片尺寸，先显示图片
    if (imgSize == null) {
      return Center(
        child: Image.memory(
          photo.imageBytes,
          fit: BoxFit.contain,
        ),
      );
    }

    final aspectRatio = imgSize.width / imgSize.height;

    return InteractiveViewer(
      maxScale: 5,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 底图
                  Image.memory(
                    photo.imageBytes,
                    fit: BoxFit.fill,
                  ),
                  // 检测框
                  for (int i = 0; i < detections.length; i++)
                    _buildDetectionBox(
                      detection: detections[i],
                      detectionIndex: i,
                      photoIndex: _currentPhotoIndex,
                      containerWidth: w,
                      containerHeight: h,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionBox({
    required YOLOResult detection,
    required int detectionIndex,
    required int photoIndex,
    required double containerWidth,
    required double containerHeight,
  }) {
    final box = detection.normalizedBox;
    final left = box.left * containerWidth;
    final top = box.top * containerHeight;
    final width = (box.right - box.left) * containerWidth;
    final height = (box.bottom - box.top) * containerHeight;

    final toothNumber = _getToothNumber(photoIndex, detectionIndex);
    final isSelected = toothNumber != null;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _toggleSelection(photoIndex, detectionIndex),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.green : Colors.blue,
              width: 3,
            ),
            color: isSelected
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$toothNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ── 照片缩略图条 ────────────────────────────────────────

  Widget _buildPhotoStrip() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        itemBuilder: (context, i) {
          final isSelected = i == _currentPhotoIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentPhotoIndex = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Image.memory(
                      _photos[i].imageBytes,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                    ),
                    // 显示该照片已选刀齿数量
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          '${_selectedTeeth.where((t) => t.photoIndex == i).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 底部操作栏 ──────────────────────────────────────────

  Widget _buildActionBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // 提示
            Expanded(
              child: Text(
                _selectedTeeth.isEmpty
                    ? '点击蓝色方框选择刀齿'
                    : '已选 ${_selectedTeeth.length} 个刀齿，继续点击选择更多',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // 完成按钮
            FilledButton.icon(
              onPressed: _finishBlade,
              icon: const Icon(Icons.check),
              label: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
}
