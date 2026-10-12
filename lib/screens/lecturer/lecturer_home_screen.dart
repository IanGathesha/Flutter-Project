import 'package:flutter/material.dart';

class LecturerHomeScreen extends StatelessWidget {
  const LecturerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecturer')),
      body: const Center(
        child: Text('Lecture Sync & Course Stream — built in a later chunk'),
      ),
    );
  }
}
