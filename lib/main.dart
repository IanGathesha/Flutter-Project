import 'package:flutter/material.dart';
import 'screens/launcher_screen.dart';

void main() {
  runApp(const EcoStudySyncApp());
}

class EcoStudySyncApp extends StatelessWidget {
  const EcoStudySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoStudy Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const LauncherScreen(),
    );
  }
}
