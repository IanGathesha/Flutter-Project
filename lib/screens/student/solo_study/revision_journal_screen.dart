import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../db/database_helper.dart';
import 'session_summary_screen.dart';

class RevisionJournalScreen extends StatefulWidget {
  final String sessionId;
  final String subjectId;
  final int foregroundSeconds;
  final int plannedSeconds;
  final double focusXpEarned; // the 75% portion, already calculated

  const RevisionJournalScreen({
    super.key,
    required this.sessionId,
    required this.subjectId,
    required this.foregroundSeconds,
    required this.plannedSeconds,
    required this.focusXpEarned,
  });

  @override
  State<RevisionJournalScreen> createState() => _RevisionJournalScreenState();
}

class _RevisionJournalScreenState extends State<RevisionJournalScreen> {
  static const _minWordCount = 15;

  final _db = DatabaseHelper.instance;
  final _controller = TextEditingController();
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateWordCount);
    _controller.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final trimmed = _controller.text.trim();
    final words =
        trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    setState(() => _wordCount = words);
  }

  bool get _meetsThreshold => _wordCount >= _minWordCount;

  Future<void> _finish({required bool skipped}) async {
    final content = _controller.text.trim();
    double recallXp = 0;
    String? recallEntryId;

    if (!skipped && content.isNotEmpty) {
      recallEntryId = const Uuid().v4();
      await _db.insertRevisionEntry({
        'id': recallEntryId,
        'session_id': widget.sessionId,
        'subject_id': widget.subjectId,
        'content': content,
        'word_count': _wordCount,
        'meets_threshold': _meetsThreshold ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (_meetsThreshold) {
        recallXp = 25;
      }
    }

    await _db.updateFocusSession(widget.sessionId, {
      'xp_earned': widget.focusXpEarned + recallXp,
      'recall_entry_id': recallEntryId,
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          sessionId: widget.sessionId,
          subjectId: widget.subjectId,
          foregroundSeconds: widget.foregroundSeconds,
          plannedSeconds: widget.plannedSeconds,
          focusXpEarned: widget.focusXpEarned,
          recallXpEarned: recallXp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What did you learn?')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a short summary of what you covered this session. '
              'A genuine attempt (15+ words) earns the remaining 25% XP.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'What did you learn this session?',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_wordCount / $_minWordCount words${_meetsThreshold ? ' ✓' : ''}',
              style: TextStyle(
                color: _meetsThreshold ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _finish(skipped: true),
                    child: const Text('Skip (forfeit 25%)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _finish(skipped: false),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
