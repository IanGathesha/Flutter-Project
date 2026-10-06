import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../db/database_helper.dart';
import 'subject_journal_screen.dart';

class _SubjectAnalytics {
  final String subjectId;
  final String subjectName;
  final double hoursStudied;
  final double? targetHours;
  final double totalXp;
  final int distractionCount;

  _SubjectAnalytics({
    required this.subjectId,
    required this.subjectName,
    required this.hoursStudied,
    this.targetHours,
    required this.totalXp,
    required this.distractionCount,
  });
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _db = DatabaseHelper.instance;
  List<_SubjectAnalytics> _items = [];
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final subjectRows = await _db.getSubjects();
    final List<_SubjectAnalytics> items = [];

    for (final subjectRow in subjectRows) {
      final subjectId = subjectRow['id'] as String;
      final subjectName = subjectRow['name'] as String;

      final sessions = await _db.getFocusSessionsForSubject(subjectId);
      final totalSeconds = sessions.fold<int>(
          0, (sum, s) => sum + (s['planned_duration_seconds'] as int));
      final totalXp = sessions.fold<double>(
          0, (sum, s) => sum + (s['xp_earned'] as num).toDouble());

      final goals = await _db.getStudyGoalsForSubject(subjectId);
      final targetHours =
          goals.isEmpty ? null : (goals.first['target_hours'] as num).toDouble();

      final logs = await _db.getFocusLogsForSubject(subjectId);
      final distractionCount =
          logs.where((l) => l['event_type'] == 'app_background').length;

      items.add(_SubjectAnalytics(
        subjectId: subjectId,
        subjectName: subjectName,
        hoursStudied: totalSeconds / 3600,
        targetHours: targetHours,
        totalXp: totalXp,
        distractionCount: distractionCount,
      ));
    }

    final streak = await _calculateStreak();

    setState(() {
      _items = items;
      _streak = streak;
      _loading = false;
    });
  }

  Future<int> _calculateStreak() async {
    final sessions = await _db.getAllFocusSessions();
    final dates = sessions
        .map((s) => DateTime.parse(s['start_time'] as String))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);

    DateTime expected;
    if (dates.first == today) {
      expected = today;
    } else if (dates.first == today.subtract(const Duration(days: 1))) {
      expected = today.subtract(const Duration(days: 1));
    } else {
      return 0; // most recent session isn't today or yesterday - streak broken
    }

    int streak = 0;
    for (final d in dates) {
      if (d == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final rawMax = _items.fold<double>(0, (max, item) {
      final candidate = item.targetHours != null
          ? (item.hoursStudied > item.targetHours! ? item.hoursStudied : item.targetHours!)
          : item.hoursStudied;
      return candidate > max ? candidate : max;
    });
    final chartMaxY = rawMax <= 0 ? 1.0 : rawMax * 1.25;
    final chartInterval = chartMaxY / 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No study data yet.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            '$_streak day streak',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Hours studied by subject',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            maxY: chartMaxY,
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: chartInterval,
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= _items.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _items[index].subjectName,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (int i = 0; i < _items.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _items[i].hoursStudied,
                                      width: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final item in _items)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubjectJournalScreen(
                                    subjectId: item.subjectId,
                                    subjectName: item.subjectName,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.subjectName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (item.targetHours != null) ...[
                                  LinearProgressIndicator(
                                    value: (item.hoursStudied / item.targetHours!)
                                        .clamp(0, 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.hoursStudied.toStringAsFixed(1)}h / '
                                    '${item.targetHours!.toStringAsFixed(1)}h '
                                    '(${((item.hoursStudied / item.targetHours!) * 100).clamp(0, 100).toStringAsFixed(0)}%)',
                                  ),
                                ] else
                                  Text(
                                      '${item.hoursStudied.toStringAsFixed(1)}h studied (no goal set)'),
                                const SizedBox(height: 4),
                                Text('Total XP: ${item.totalXp.toStringAsFixed(1)}'),
                                Text('Times left the app: ${item.distractionCount}'),
                              ],
                            ),
                          ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
