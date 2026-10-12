class StudyGoal {
  final String id;
  final String subjectId;
  final double targetHours;
  final String deadline; // ISO 8601 date string
  final String createdAt;

  StudyGoal({
    required this.id,
    required this.subjectId,
    required this.targetHours,
    required this.deadline,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'target_hours': targetHours,
        'deadline': deadline,
        'created_at': createdAt,
      };

  factory StudyGoal.fromMap(Map<String, dynamic> map) => StudyGoal(
        id: map['id'] as String,
        subjectId: map['subject_id'] as String,
        targetHours: (map['target_hours'] as num).toDouble(),
        deadline: map['deadline'] as String,
        createdAt: map['created_at'] as String,
      );
}
