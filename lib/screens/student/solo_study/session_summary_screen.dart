import 'package:flutter/material.dart';

class SessionSummaryScreen extends StatelessWidget {
  final String sessionId;
  final String subjectId;
  final int foregroundSeconds;
  final int plannedSeconds;
  final double focusXpEarned;
  final double recallXpEarned;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    required this.subjectId,
    required this.foregroundSeconds,
    required this.plannedSeconds,
    required this.focusXpEarned,
    required this.recallXpEarned,
  });

  @override
  Widget build(BuildContext context) {
    final percent = plannedSeconds == 0
        ? 0.0
        : (foregroundSeconds / plannedSeconds * 100).clamp(0, 100);
    final totalXp = focusXpEarned + recallXpEarned;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Complete')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}% focused',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Total XP: ${totalXp.toStringAsFixed(1)} / 100',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Focus: ${focusXpEarned.toStringAsFixed(1)} / 75   ·   '
                'Recall: ${recallXpEarned.toStringAsFixed(1)} / 25',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
