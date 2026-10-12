import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:screen_state_v2/screen_state.dart';
import 'package:uuid/uuid.dart';

import '../../../db/database_helper.dart';
import 'revision_journal_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final String subjectId;
  final String technique;
  final int plannedMinutes;

  const ActiveSessionScreen({
    super.key,
    required this.subjectId,
    required this.technique,
    required this.plannedMinutes,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with WidgetsBindingObserver {
  late final String _sessionId;
  late final int _plannedSeconds;
  late final DateTime _startTime;

  final _db = DatabaseHelper.instance;
  final _screen = Screen();
  StreamSubscription<ScreenStateEvent>? _screenSubscription;
  Timer? _ticker;
  Timer? _graceTimer;

  // Timestamp-based presence tracking - robust against missed/throttled ticks.
  DateTime? _presentSince;
  int _foregroundSecondsAccumulated = 0;

  // Debounces the "away" decision so a screen_off event arriving slightly
  // after the app-backgrounded event still gets a chance to reclassify
  // the transition as "present" before any time is lost.
  Timer? _awayConfirmTimer;
  static const _awayConfirmDelay = Duration(seconds: 3);

  int _elapsedSeconds = 0;

  bool _appInForeground = true;
  bool _screenOff = false;
  bool _graceActive = false;
  bool _graceUsed = false;
  int _graceSecondsRemaining = 0;

  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
    _plannedSeconds = widget.plannedMinutes * 60;
    _startTime = DateTime.now();
    _presentSince = _startTime; // present from the start

    WidgetsBinding.instance.addObserver(this);
    _startScreenListener();
    _logEvent('session_start');
    debugPrint('[EcoStudy] session started, planned=$_plannedSeconds s');

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenSubscription?.cancel();
    _ticker?.cancel();
    _graceTimer?.cancel();
    _awayConfirmTimer?.cancel();
    super.dispose();
  }

  void _startScreenListener() {
    try {
      _screenSubscription = _screen.screenStateStream.listen((event) {
        if (event == ScreenStateEvent.SCREEN_OFF) {
          setState(() => _screenOff = true);
          _logEvent('screen_off');
          debugPrint('[EcoStudy] SCREEN_OFF detected');
          _updatePresence();
        } else if (event == ScreenStateEvent.SCREEN_ON) {
          setState(() => _screenOff = false);
          _logEvent('screen_on');
          debugPrint('[EcoStudy] SCREEN_ON detected');
          _updatePresence();
        }
      });
      debugPrint('[EcoStudy] screen state listener started successfully');
    } catch (e) {
      debugPrint('[EcoStudy] screen state listener FAILED to start: $e');
      // Screen-state detection unavailable on this device; foreground
      // tracking still works without it.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    debugPrint('[EcoStudy] lifecycle state changed: $state (foreground=$isForeground)');
    if (isForeground != _appInForeground) {
      setState(() => _appInForeground = isForeground);
      _logEvent(isForeground ? 'app_foreground' : 'app_background');
      _updatePresence();
    }
  }

  void _logEvent(String eventType) {
    _db.insertFocusLog({
      'id': const Uuid().v4(),
      'session_id': _sessionId,
      'event_type': eventType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  bool get _countsAsPresent => _appInForeground || _screenOff || _graceActive;

  /// Call whenever a flag that affects _countsAsPresent changes.
  /// Flushes accumulated time using real timestamps rather than tick counts.
  /// "Away" transitions are debounced so a screen_off event arriving a
  /// moment later can still reclassify the gap as present time.
  void _updatePresence() {
    final nowPresent = _countsAsPresent;

    if (nowPresent) {
      _awayConfirmTimer?.cancel();
      _awayConfirmTimer = null;
      _presentSince ??= DateTime.now();
    } else {
      _awayConfirmTimer?.cancel();
      _awayConfirmTimer = Timer(_awayConfirmDelay, () {
        if (!_countsAsPresent && _presentSince != null) {
          _foregroundSecondsAccumulated +=
              DateTime.now().difference(_presentSince!).inSeconds;
          _presentSince = null;
        }
      });
    }
  }

  void _onTick() {
    if (_ended) return;

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    setState(() => _elapsedSeconds = elapsed);

    if (_elapsedSeconds >= _plannedSeconds) {
      _endSession();
    }
  }

  void _activateGrace() {
    if (_graceUsed || _graceActive) return;

    setState(() {
      _graceUsed = true;
      _graceActive = true;
      _graceSecondsRemaining = 90;
    });
    _logEvent('grace_start');
    debugPrint('[EcoStudy] grace window activated');
    _updatePresence();

    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _graceSecondsRemaining--);
      if (_graceSecondsRemaining <= 0) {
        timer.cancel();
        setState(() => _graceActive = false);
        _logEvent('grace_end');
        debugPrint('[EcoStudy] grace window expired');
        _updatePresence();
      }
    });
  }

  Future<void> _endSession() async {
    if (_ended) return;
    _ended = true;
    _awayConfirmTimer?.cancel(); // don't let a pending debounce fire after we've already flushed
    // Flush any still-open present interval as of right now. If we were mid
    // away-confirm wait, this counts that stretch as present rather than
    // penalizing a departure we hadn't yet confirmed as genuine.
    if (_presentSince != null) {
      _foregroundSecondsAccumulated +=
          DateTime.now().difference(_presentSince!).inSeconds;
      _presentSince = null;
    }

    _ticker?.cancel();
    _graceTimer?.cancel();
    _logEvent('session_end');

    final foregroundSeconds = _foregroundSecondsAccumulated;
    final xpEarned = (foregroundSeconds / _plannedSeconds) * 100 * 0.75;
    debugPrint(
        '[EcoStudy] session end: foreground=$foregroundSeconds / planned=$_plannedSeconds -> xp=$xpEarned');

    await _db.insertFocusSession({
      'id': _sessionId,
      'subject_id': widget.subjectId,
      'technique': widget.technique,
      'start_time': _startTime.toIso8601String(),
      'end_time': DateTime.now().toIso8601String(),
      'planned_duration_seconds': _plannedSeconds,
      'foreground_seconds': foregroundSeconds,
      'xp_earned': xpEarned,
      'grace_used': _graceUsed ? 1 : 0,
      'recall_entry_id': null,
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RevisionJournalScreen(
          sessionId: _sessionId,
          subjectId: widget.subjectId,
          foregroundSeconds: foregroundSeconds,
          plannedSeconds: _plannedSeconds,
          focusXpEarned: xpEarned,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_plannedSeconds - _elapsedSeconds).clamp(0, _plannedSeconds);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.technique)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(remaining),
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (_graceActive)
                Text('Pause active — $_graceSecondsRemaining s remaining')
              else
                ElevatedButton(
                  onPressed: _graceUsed ? null : _activateGrace,
                  child: Text(
                    _graceUsed ? "Pause used" : "Pause, Don't Penalize",
                  ),
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _endSession,
                child: const Text('End session now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
