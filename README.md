# YOLO Flutter App - 多任务实时视觉推理

基于 [ultralytics_yolo](https://github.com/ultralytics/yolo-flutter-app) 插件的完整示例应用，支持 6 种 YOLO 任务实时推理，全部模型离线内置。

## 功能特性

- **6 种视觉任务**实时推理：
  - Detect - 目标检测
  - Segment - 实例分割
  - Semantic - 语义分割
  - Classify - 图像分类
  - Pose - 姿态估计
  - OBB - 旋转目标检测
- **多模型尺寸切换**：n / s / m / l / x（不同精度与速度权衡）
- 全部 n 和 s 尺寸 int8 模型预打包，离线可用
- Detect 任务全部 5 个尺寸均内置
- 实时性能指标：FPS、推理耗时（pre/inference/post）
- 可调节置信度阈值与 IoU 阈值
- 支持手势：双指缩放、点击对焦
- 摄像头切换、闪光灯控制、拍照分享
- 镜头切换（广角/长焦等）

## 内置模型

### Detect（目标检测）- 全部 5 尺寸

| 模型                | 大小    | 说明     |
| ------------------- | ------- | -------- |
| yolo26n_int8.tflite | 2.7 MB  | 最快     |
| yolo26s_int8.tflite | 9.6 MB  | 平衡     |
| yolo26m_int8.tflite | 20.1 MB | 中等     |
| yolo26l_int8.tflite | 24.5 MB | 高精度   |
| yolo26x_int8.tflite | 54.2 MB | 最高精度 |

### 其他任务 - n 和 s 尺寸

| 任务     | n 尺寸                            | s 尺寸                             |
| -------- | --------------------------------- | ---------------------------------- |
| Segment  | yolo26n-seg_int8.tflite (3.0 MB)  | yolo26s-seg_int8.tflite (10.5 MB)  |
| Semantic | yolo26n-sem_int8.tflite (1.6 MB)  | yolo26s-sem_int8.tflite (6.1 MB)   |
| Classify | yolo26n-cls_int8.tflite (2.8 MB)  | yolo26s-cls_int8.tflite (6.6 MB)   |
| Pose     | yolo26n-pose_int8.tflite (3.4 MB) | yolo26s-pose_int8.tflite (10.6 MB) |
| OBB      | yolo26n-obb_int8.tflite (2.8 MB)  | yolo26s-obb_int8.tflite (9.9 MB)   |

## 技术栈

- **Flutter** >= 3.32.1
- **ultralytics_yolo** - YOLO 推理插件（本地路径依赖）
- **TFLite** int8 量化模型，GPU 加速 (LiteRT)
- **CameraX** (Android) / **AVFoundation** (iOS)
- **share_plus** - 拍照分享
- **wakelock_plus** - 屏幕常亮
- **shared_preferences** - 任务偏好持久化

## 快速开始

```bash
# 安装依赖
flutter pub get

# 运行到 Android 设备
flutter run -d <device-id>

# 构建 Release APK
flutter build apk --release
```

> **注意**：修改 `assets/models/` 目录内容后，需要执行 `flutter clean` 再构建，否则增量构建不会将新文件打包进 APK。

## 项目结构

```
yolo-flutter-app-main/
├── lib/                        # 插件源码
│   ├── core/
│   │   ├── yolo_model_resolver.dart   # 模型解析（assets → 下载）
│   │   └── yolo_model_manager.dart    # 下载进度管理
│   ├── widgets/
│   │   ├── yolo_showcase.dart         # 完整摄像头 UI 组件
│   │   ├── yolo_view.dart             # 平台视图桥接
│   │   ├── yolo_controller.dart       # 摄像头控制器
│   │   └── ...                        # 其他 UI 组件
│   └── ultralytics_yolo.dart          # 公共 API 导出
├── example/                    # 示例应用
│   ├── lib/
│   │   └── main.dart           # 入口（含多页面导航）
│   ├── assets/
│   │   └── models/             # 全部 TFLite 模型文件
│   └── pubspec.yaml
└── README.md
```

## 界面说明

- **顶部**：模型名称 + FPS/耗时指标 + 任务切换标签 + 尺寸切换标签
- **中部**：实时摄像头画面 + 检测结果叠加
- **底部**：置信度/IoU 滑块 + 缩放指示器 + 镜头选择 + 工具栏（暂停/拍照/分享/信息）

## 许可证

遵循 Ultralytics AGPL-3.0 许可证 - https://ultralytics.com/license
