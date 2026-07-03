import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/presentation/models/drill_task.dart';
import 'package:ultralytics_yolo_example/presentation/screens/blade_capture_screen.dart';
import 'package:ultralytics_yolo_example/presentation/screens/task_detail_screen.dart';
import 'package:ultralytics_yolo_example/presentation/screens/task_form_screen.dart';
import 'package:ultralytics_yolo_example/presentation/services/task_storage.dart';

/// 钻头刀齿检测 — 首页。
///
/// 展示任务列表，FAB 创建新任务。
class DrillHomeScreen extends StatefulWidget {
  const DrillHomeScreen({super.key});

  @override
  State<DrillHomeScreen> createState() => _DrillHomeScreenState();
}

class _DrillHomeScreenState extends State<DrillHomeScreen> {
  final List<DrillTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskStorage.loadAll();
    if (mounted) {
      setState(() {
        _tasks.addAll(tasks);
        _isLoading = false;
      });
    }
  }

  /// 持久化所有任务到磁盘。
  void _persist() {
    TaskStorage.saveAll(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('钻头刀齿检测'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState(context)
              : _buildTaskList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add),
        label: const Text('新建任务'),
      ),
    );
  }

  // ── 空状态 ──────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.precision_manufacturing_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
              alpha: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无检测任务',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮新建检测任务',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── 任务列表 ────────────────────────────────────────────

  Widget _buildTaskList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: _tasks.length,
      itemBuilder: (context, index) => _TaskCard(
        task: _tasks[index],
        onTap: () => _showTaskDetail(context, _tasks[index]),
      ),
    );
  }

  void _createTask() async {
    // 步骤 1: 从表单获取任务
    final task = await Navigator.of(context).push<DrillTask>(
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (task == null || !mounted) return;

    // 步骤 2: 立即保存到列表（确保任务不会丢失）
    setState(() => _tasks.insert(0, task));

    // 步骤 3: 启动拍照流程（从首页直接 push，保证 pop 能正确返回）
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BladeCaptureScreen(task: task, bladeIndex: 0),
      ),
    );

    // 拍照流程结束后，保存并刷新 UI
    if (mounted) {
      _persist();
      setState(() {});
    }
  }

  void _showTaskDetail(BuildContext context, DrillTask task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    // 返回后保存并刷新 UI（刀齿选择可能已变更）
    if (mounted) {
      _persist();
      setState(() {});
    }
  }
}

// ── 任务卡片 ──────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final DrillTask task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
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
                        Chip(
                          label: Text('${task.bladeCount} 刀翼'),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text('${task.totalTeethCount} 刀齿'),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text(
                            '${task.completedBladeCount}/${task.bladeCount} 完成',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

