import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ecostudy_sync.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_goals (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        target_hours REAL NOT NULL,
        deadline TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        technique TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        planned_duration_seconds INTEGER NOT NULL,
        foreground_seconds INTEGER NOT NULL DEFAULT 0,
        xp_earned REAL NOT NULL DEFAULT 0,
        grace_used INTEGER NOT NULL DEFAULT 0,
        recall_entry_id TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE focus_logs (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES focus_sessions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE revision_entries (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        content TEXT NOT NULL,
        word_count INTEGER NOT NULL,
        meets_threshold INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES focus_sessions (id),
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');
  }

  // ---- Subjects ----

  Future<void> insertSubject(Map<String, dynamic> subject) async {
    final db = await database;
    await db.insert('subjects', subject);
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final db = await database;
    return db.query('subjects', orderBy: 'created_at DESC');
  }

  Future<void> deleteSubject(String id) async {
    final db = await database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Study goals ----

  Future<void> insertStudyGoal(Map<String, dynamic> goal) async {
    final db = await database;
    await db.insert('study_goals', goal);
  }

  Future<List<Map<String, dynamic>>> getStudyGoalsForSubject(String subjectId) async {
    final db = await database;
    return db.query(
      'study_goals',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'deadline ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllStudyGoals() async {
    final db = await database;
    return db.query('study_goals', orderBy: 'deadline ASC');
  }

  // ---- Focus sessions ----

  Future<void> insertFocusSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert('focus_sessions', session);
  }

  Future<void> updateFocusSession(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update('focus_sessions', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFocusSessionsForSubject(String subjectId) async {
    final db = await database;
    return db.query(
      'focus_sessions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'start_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllFocusSessions() async {
    final db = await database;
    return db.query('focus_sessions', orderBy: 'start_time DESC');
  }

  // ---- Focus logs ----

  Future<void> insertFocusLog(Map<String, dynamic> log) async {
    final db = await database;
    await db.insert('focus_logs', log);
  }

  Future<List<Map<String, dynamic>>> getFocusLogsForSession(String sessionId) async {
    final db = await database;
    return db.query(
      'focus_logs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getFocusLogsForSubject(String subjectId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT focus_logs.* FROM focus_logs
      INNER JOIN focus_sessions ON focus_logs.session_id = focus_sessions.id
      WHERE focus_sessions.subject_id = ?
    ''', [subjectId]);
  }

  // ---- Revision entries ----

  Future<void> insertRevisionEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('revision_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getRevisionEntriesForSubject(String subjectId) async {
    final db = await database;
    return db.query(
      'revision_entries',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
  }
}
