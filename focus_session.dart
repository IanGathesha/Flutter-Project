class FocusSession {
  final String id;
  final String subjectId;
  final String technique;
  final String startTime;
  final String? endTime;
  final int plannedDurationSeconds;
  final int foregroundSeconds;
  final double xpEarned;
  final bool graceUsed;
  final String? recallEntryId;

  FocusSession({
    required this.id,
    required this.subjectId,
    required this.technique,
    required this.startTime,
    this.endTime,
    required this.plannedDurationSeconds,
    this.foregroundSeconds = 0,
    this.xpEarned = 0,
    this.graceUsed = false,
    this.recallEntryId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'technique': technique,
        'start_time': startTime,
        'end_time': endTime,
        'planned_duration_seconds': plannedDurationSeconds,
        'foreground_seconds': foregroundSeconds,
        'xp_earned': xpEarned,
        'grace_used': graceUsed ? 1 : 0,
        'recall_entry_id': recallEntryId,
      };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
        id: map['id'] as String,
        subjectId: map['subject_id'] as String,
        technique: map['technique'] as String,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String?,
        plannedDurationSeconds: map['planned_duration_seconds'] as int,
        foregroundSeconds: map['foreground_seconds'] as int,
        xpEarned: (map['xp_earned'] as num).toDouble(),
        graceUsed: (map['grace_used'] as int) == 1,
        recallEntryId: map['recall_entry_id'] as String?,
      );
}
