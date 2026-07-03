import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/presentation/models/drill_task.dart';

/// 新建任务表单 — 填写钻头编号和刀翼数量。
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _drillBitController = TextEditingController();
  final _bladeCountController = TextEditingController(text: '1');

  @override
  void dispose() {
    _drillBitController.dispose();
    _bladeCountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final task = DrillTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      drillBitNumber: _drillBitController.text.trim(),
      bladeCount: int.parse(_bladeCountController.text.trim()),
    );

    // 将 task 返回给首页，由首页启动拍照流程
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建检测任务')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 图标
            Icon(
              Icons.precision_manufacturing,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // 钻头编号
            TextFormField(
              controller: _drillBitController,
              decoration: const InputDecoration(
                labelText: '钻头编号',
                hintText: '请输入钻头编号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入钻头编号' : null,
            ),
            const SizedBox(height: 20),

            // 刀翼数量
            TextFormField(
              controller: _bladeCountController,
              decoration: const InputDecoration(
                labelText: '刀翼数量',
                hintText: '1 ~ 20',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 20) return '请输入 1-20 的整数';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // 提交按钮
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始检测'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
