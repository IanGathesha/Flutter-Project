import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../db/database_helper.dart';

class _SubjectWithGoal {
  final String subjectId;
  final String subjectName;
  final String? goalId;
  final double? targetHours;
  final DateTime? deadline;

  _SubjectWithGoal({
    required this.subjectId,
    required this.subjectName,
    this.goalId,
    this.targetHours,
    this.deadline,
  });
}

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final _db = DatabaseHelper.instance;
  List<_SubjectWithGoal> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final subjectRows = await _db.getSubjects();
    final List<_SubjectWithGoal> items = [];

    for (final subjectRow in subjectRows) {
      final subjectId = subjectRow['id'] as String;
      final subjectName = subjectRow['name'] as String;
      final goalRows = await _db.getStudyGoalsForSubject(subjectId);

      if (goalRows.isEmpty) {
        items.add(_SubjectWithGoal(subjectId: subjectId, subjectName: subjectName));
      } else {
        final goal = goalRows.first;
        items.add(_SubjectWithGoal(
          subjectId: subjectId,
          subjectName: subjectName,
          goalId: goal['id'] as String,
          targetHours: (goal['target_hours'] as num).toDouble(),
          deadline: DateTime.parse(goal['deadline'] as String),
        ));
      }
    }

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final hoursController = TextEditingController();
    DateTime? selectedDeadline;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('New Subject Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Subject name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target hours'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDeadline == null
                              ? 'No deadline selected'
                              : 'Deadline: ${_formatDate(selectedDeadline!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDeadline = picked);
                          }
                        },
                        child: const Text('Pick date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final hours = double.tryParse(hoursController.text.trim());

                    if (name.isEmpty || hours == null || selectedDeadline == null) {
                      return;
                    }

                    final subjectId = const Uuid().v4();
                    final now = DateTime.now().toIso8601String();

                    await _db.insertSubject({
                      'id': subjectId,
                      'name': name,
                      'created_at': now,
                    });

                    await _db.insertStudyGoal({
                      'id': const Uuid().v4(),
                      'subject_id': subjectId,
                      'target_hours': hours,
                      'deadline': selectedDeadline!.toIso8601String(),
                      'created_at': now,
                    });

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await _loadData();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSubject(String subjectId) async {
    await _db.deleteSubject(subjectId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Planner')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No subjects yet. Tap + to add one.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final daysLeft = item.deadline == null
                        ? null
                        : item.deadline!.difference(DateTime.now()).inDays;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(item.subjectName),
                        subtitle: item.targetHours == null
                            ? const Text('No goal set')
                            : Text(
                                'Target: ${item.targetHours!.toStringAsFixed(1)}h · '
                                'Deadline: ${_formatDate(item.deadline!)} '
                                '(${daysLeft! >= 0 ? '$daysLeft days left' : 'overdue'})',
                              ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteSubject(item.subjectId),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
