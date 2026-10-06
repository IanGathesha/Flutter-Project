class FocusLog {
  final String id;
  final String sessionId;
  final String eventType; // foreground, background, screen_off, screen_on, grace_start, grace_end
  final String timestamp;

  FocusLog({
    required this.id,
    required this.sessionId,
    required this.eventType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'event_type': eventType,
        'timestamp': timestamp,
      };

  factory FocusLog.fromMap(Map<String, dynamic> map) => FocusLog(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        eventType: map['event_type'] as String,
        timestamp: map['timestamp'] as String,
      );
}
