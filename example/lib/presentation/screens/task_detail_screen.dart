import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/presentation/models/drill_task.dart';
import 'package:ultralytics_yolo_example/presentation/screens/tooth_selection_screen.dart';

/// 任务详情页 — 展示各刀翼状态，可进入某个刀翼进行刀齿选择。
///
/// 任务完成后（所有刀翼拍照完毕），用户可从首页进入此页面，
/// 选择某个刀翼查看照片并人工选取检测框作为刀齿。
class TaskDetailScreen extends StatefulWidget {
  final DrillTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Scaffold(
      appBar: AppBar(
        title: Text('钻头 ${task.drillBitNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 任务概览卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      task.drillBitNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '钻头编号: ${task.drillBitNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            _InfoChip(
                                icon: Icons.layers, label: '${task.bladeCount} 刀翼'),
                            _InfoChip(
                                icon: Icons.photo_camera, label: '$_totalPhotos 张照片'),
                            _InfoChip(
                                icon: Icons.settings, label: '${task.totalTeethCount} 刀齿'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 刀翼列表标题
          Text('刀翼列表', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // 各刀翼卡片
          ...task.blades.map((blade) => _BladeCard(
                blade: blade,
                onTap: blade.photos.isEmpty
                    ? null
                    : () => _enterToothSelection(blade.bladeNumber - 1),
              )),
        ],
      ),
    );
  }

  int get _totalPhotos =>
      widget.task.blades.fold(0, (sum, b) => sum + b.photos.length);

  void _enterToothSelection(int bladeIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ToothSelectionScreen(
          task: widget.task,
          bladeIndex: bladeIndex,
        ),
      ),
    );
    // 返回后刷新 UI（刀齿选择可能已变更）
    if (mounted) setState(() {});
  }
}

// ── 刀翼卡片 ──────────────────────────────────────────────

class _BladeCard extends StatelessWidget {
  final BladeData blade;
  final VoidCallback? onTap;

  const _BladeCard({required this.blade, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPhotos = blade.photos.isNotEmpty;
    final teethCount = blade.selectedTeeth.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 刀翼序号
              CircleAvatar(
                radius: 20,
                backgroundColor: hasPhotos
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  '${blade.bladeNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasPhotos
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 刀翼信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '刀翼 ${blade.bladeNumber}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    if (hasPhotos)
                      Wrap(
                        spacing: 6,
                        children: [
                          _MiniChip(
                              icon: Icons.photo, label: '${blade.photos.length} 张'),
                          _MiniChip(
                              icon: Icons.settings, label: '$teethCount 齿'),
                        ],
                      )
                    else
                      Text(
                        '未拍照',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),

              // 状态图标
              if (hasPhotos)
                Icon(
                  teethCount > 0 ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: teethCount > 0 ? 24 : 16,
                  color: teethCount > 0
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 辅助组件 ──────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
