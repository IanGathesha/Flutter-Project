class RevisionEntry {
  final String id;
  final String sessionId;
  final String subjectId;
  final String content;
  final int wordCount;
  final bool meetsThreshold;
  final String createdAt;

  RevisionEntry({
    required this.id,
    required this.sessionId,
    required this.subjectId,
    required this.content,
    required this.wordCount,
    required this.meetsThreshold,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'subject_id': subjectId,
        'content': content,
        'word_count': wordCount,
        'meets_threshold': meetsThreshold ? 1 : 0,
        'created_at': createdAt,
      };

  factory RevisionEntry.fromMap(Map<String, dynamic> map) => RevisionEntry(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        subjectId: map['subject_id'] as String,
        content: map['content'] as String,
        wordCount: map['word_count'] as int,
        meetsThreshold: (map['meets_threshold'] as int) == 1,
        createdAt: map['created_at'] as String,
      );
}
