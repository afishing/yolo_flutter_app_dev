// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/presentation/screens/drill_home_screen.dart';

void main() {
  runApp(const DrillInspectionApp());
}

class DrillInspectionApp extends StatelessWidget {
  const DrillInspectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '钻头刀齿检测',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DrillHomeScreen(),
    );
  }
}
