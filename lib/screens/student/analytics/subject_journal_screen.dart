import 'package:flutter/material.dart';

import '../../../db/database_helper.dart';

class SubjectJournalScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectJournalScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectJournalScreen> createState() => _SubjectJournalScreenState();
}

class _SubjectJournalScreenState extends State<SubjectJournalScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await _db.getRevisionEntriesForSubject(widget.subjectId);
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _formatDate(String isoString) {
    final d = DateTime.parse(isoString);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subjectName} — Journal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No written summaries yet for this subject.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    // Entries come back newest-first; number them so the
                    // oldest entry is "Session 1" chronologically.
                    final sessionNumber = _entries.length - index;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Session $sessionNumber',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _formatDate(entry['created_at'] as String),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(entry['content'] as String),
                            const SizedBox(height: 4),
                            Text(
                              '${entry['word_count']} words',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
