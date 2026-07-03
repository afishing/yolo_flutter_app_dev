import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo_example/presentation/models/drill_task.dart';

/// 任务数据持久化管理器。
///
/// 存储策略：
/// - 任务元数据（钻头编号、刀翼数、刀齿选择）→ JSON 文件
/// - 照片原始字节 → 独立 JPEG 文件
///
/// 目录结构：
/// ```
/// <appDocs>/drill_tasks/
///   tasks.json
///   <taskId>/photo_<blade>_<index>.jpg
/// ```
class TaskStorage {
  TaskStorage._();
  static const _dirName = 'drill_tasks';
  static const _metaFile = 'tasks.json';

  static Future<String> _rootPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_dirName';
  }

  // ── 保存 ────────────────────────────────────────────────

  /// 保存所有任务（含照片文件写入磁盘）。
  static Future<void> saveAll(List<DrillTask> tasks) async {
    final root = await _rootPath();
    final jsonList = <Map<String, dynamic>>[];

    for (final task in tasks) {
      jsonList.add(await _taskToJson(task, root));
    }

    final metaPath = '$root/$_metaFile';
    await File(metaPath).create(recursive: true);
    await File(metaPath).writeAsString(jsonEncode(jsonList));
  }

  static Future<Map<String, dynamic>> _taskToJson(
    DrillTask task,
    String root,
  ) async {
    final taskDir = '$root/${task.id}';

    final bladesJson = <Map<String, dynamic>>[];
    for (final blade in task.blades) {
      final photosJson = <Map<String, dynamic>>[];

      for (var pi = 0; pi < blade.photos.length; pi++) {
        final photo = blade.photos[pi];
        final photoPath = '$taskDir/photo_${blade.bladeNumber}_$pi.jpg';

        // 写入照片文件
        final photoFile = File(photoPath);
        await photoFile.create(recursive: true);
        await photoFile.writeAsBytes(photo.imageBytes);

        photosJson.add({
          'path': photoPath,
          'detections': photo.detections.map((d) => d.toMap()).toList(),
        });
      }

      bladesJson.add({
        'bladeNumber': blade.bladeNumber,
        'photos': photosJson,
        'selectedTeeth': blade.selectedTeeth
            .map((t) => {
                  'toothNumber': t.toothNumber,
                  'photoIndex': t.photoIndex,
                  'detectionIndex': t.detectionIndex,
                })
            .toList(),
      });
    }

    return {
      'id': task.id,
      'drillBitNumber': task.drillBitNumber,
      'bladeCount': task.bladeCount,
      'createdAt': task.createdAt.toIso8601String(),
      'blades': bladesJson,
    };
  }

  // ── 加载 ────────────────────────────────────────────────

  /// 加载所有任务（含照片文件读取）。
  static Future<List<DrillTask>> loadAll() async {
    final root = await _rootPath();
    final metaPath = '$root/$_metaFile';
    final metaFile = File(metaPath);

    if (!await metaFile.exists()) return [];

    try {
      final content = await metaFile.readAsString();
      final jsonList = jsonDecode(content) as List;
      final tasks = <DrillTask>[];

      for (final item in jsonList) {
        if (item is! Map) continue;
        final task = await _taskFromJson(Map<String, dynamic>.from(item));
        if (task != null) tasks.add(task);
      }

      return tasks;
    } catch (_) {
      return [];
    }
  }

  static Future<DrillTask?> _taskFromJson(Map<String, dynamic> json) async {
    try {
      final id = json['id'] as String;
      final drillBitNumber = json['drillBitNumber'] as String;
      final bladeCount = json['bladeCount'] as int;
      final createdAt = DateTime.parse(json['createdAt'] as String);

      final bladesJson = json['blades'] as List? ?? [];
      final blades = <BladeData>[];

      for (final bj in bladesJson) {
        if (bj is! Map) continue;
        final b = Map<String, dynamic>.from(bj);
        final bladeNumber = b['bladeNumber'] as int;

        // 加载照片
        final photosJson = b['photos'] as List? ?? [];
        final photos = <CapturedPhoto>[];
        for (final pj in photosJson) {
          if (pj is! Map) continue;
          final p = Map<String, dynamic>.from(pj);
          final path = p['path'] as String;
          final photoFile = File(path);
          if (!await photoFile.exists()) continue;

          final bytes = await photoFile.readAsBytes();
          final detectionsJson = p['detections'] as List? ?? [];
          final detections = detectionsJson
              .whereType<Map>()
              .map((d) => YOLOResult.fromMap(d))
              .toList();

          photos.add(CapturedPhoto(imageBytes: bytes, detections: detections));
        }

        // 加载已选刀齿
        final teethJson = b['selectedTeeth'] as List? ?? [];
        final teeth = teethJson.whereType<Map>().map((t) {
          final m = Map<String, dynamic>.from(t);
          return SelectedTooth(
            toothNumber: m['toothNumber'] as int,
            photoIndex: m['photoIndex'] as int,
            detectionIndex: m['detectionIndex'] as int,
          );
        }).toList();

        blades.add(BladeData(
          bladeNumber: bladeNumber,
          photos: photos,
          selectedTeeth: teeth,
        ));
      }

      return DrillTask(
        id: id,
        drillBitNumber: drillBitNumber,
        bladeCount: bladeCount,
        blades: blades,
        createdAt: createdAt,
      );
    } catch (_) {
      return null;
    }
  }

  // ── 删除 ────────────────────────────────────────────────

  /// 删除指定任务的所有文件。
  static Future<void> deleteTask(String taskId) async {
    final root = await _rootPath();
    final taskDir = Directory('$root/$taskId');
    if (await taskDir.exists()) {
      await taskDir.delete(recursive: true);
    }
  }
}
