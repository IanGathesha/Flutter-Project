import 'package:flutter/material.dart';

import '../../../db/database_helper.dart';
import 'active_session_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  int _minutes = 25;

  // Every session already combines both named techniques from the proposal:
  // the timed block is the Pomodoro-style structure, the revision journal
  // at the end is the active recall practice. No selection needed.
  static const _technique = 'Pomodoro + Active Recall';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _db.getSubjects();
    setState(() {
      _subjects = subjects;
      if (subjects.isNotEmpty) _selectedSubjectId = subjects.first['id'] as String;
    });
  }

  void _startSession() {
    if (_selectedSubjectId == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(
          subjectId: _selectedSubjectId!,
          technique: _technique,
          plannedMinutes: _minutes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Solo Study')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _subjects.isEmpty
            ? const Text('Add a subject in Study Planner first.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subject'),
                  DropdownButton<String>(
                    value: _selectedSubjectId,
                    isExpanded: true,
                    items: _subjects
                        .map((s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text(s['name'] as String),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSubjectId = value),
                  ),
                  const SizedBox(height: 20),
                  Text('Duration: $_minutes minutes'),
                  Slider(
                    value: _minutes.toDouble(),
                    min: 5,
                    max: 90,
                    divisions: 17,
                    label: '$_minutes min',
                    onChanged: (value) => setState(() => _minutes = value.round()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _startSession,
                      child: const Text('Start Session'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
