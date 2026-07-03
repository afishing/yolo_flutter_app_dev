import 'dart:typed_data';

import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// 单个被选中的刀齿。
class SelectedTooth {
  /// 刀齿编号（1-based，由用户选择顺序自动递增）。
  int toothNumber;

  /// 该刀齿来自哪张照片（在 BladeData.photos 中的索引）。
  int photoIndex;

  /// 该刀齿对应照片中的第几个检测框（在 CapturedPhoto.detections 中的索引）。
  int detectionIndex;

  SelectedTooth({
    required this.toothNumber,
    required this.photoIndex,
    required this.detectionIndex,
  });

  @override
  String toString() =>
      'SelectedTooth(#$toothNumber, photo:$photoIndex, det:$detectionIndex)';
}

/// 拍照采集的一张照片及其对应的实时检测结果。
///
/// detections 来自拍照瞬间 YOLOView 的 onResult 回调，
/// 与照片帧同步截取，无需事后重新推理。
class CapturedPhoto {
  /// 原始 JPEG 字节。
  Uint8List imageBytes;

  /// 拍照瞬间的实时检测结果列表（归一化坐标在 normalizedBox 中）。
  List<YOLOResult> detections;

  CapturedPhoto({
    required this.imageBytes,
    this.detections = const [],
  });
}

/// 单个刀翼的采集与选择数据。
class BladeData {
  /// 刀翼序号（1-based）。
  int bladeNumber;

  /// 该刀翼拍摄的照片列表。
  List<CapturedPhoto> photos;

  /// 该刀翼已选中的刀齿列表。
  List<SelectedTooth> selectedTeeth;

  BladeData({
    required this.bladeNumber,
    List<CapturedPhoto>? photos,
    List<SelectedTooth>? selectedTeeth,
  })  : photos = photos ?? [],
        selectedTeeth = selectedTeeth ?? [];
}

/// 一个完整的钻头检测任务。
class DrillTask {
  /// 唯一标识。
  final String id;

  /// 钻头编号。
  String drillBitNumber;

  /// 刀翼数量。
  int bladeCount;

  /// 各刀翼的数据。
  List<BladeData> blades;

  /// 创建时间。
  final DateTime createdAt;

  DrillTask({
    required this.id,
    required this.drillBitNumber,
    required this.bladeCount,
    List<BladeData>? blades,
    DateTime? createdAt,
  })  : blades = blades ??
            List.generate(
              bladeCount,
              (i) => BladeData(bladeNumber: i + 1),
            ),
        createdAt = createdAt ?? DateTime.now();

  /// 已完成采集的刀翼数量。
  int get completedBladeCount =>
      blades.where((b) => b.selectedTeeth.isNotEmpty).length;

  /// 所有刀翼的刀齿总数。
  int get totalTeethCount =>
      blades.fold(0, (sum, b) => sum + b.selectedTeeth.length);
}
