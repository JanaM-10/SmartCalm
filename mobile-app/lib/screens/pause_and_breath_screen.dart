import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../core/theme/app_colors.dart';

enum GuidedBreathingPhase {
  idle,
  inhale,
  holdAfterInhale,
  exhale,
  holdAfterExhale,
  finished,
}

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({
    super.key,
    this.readingId,
    this.stressLevel = 'High',
  });

  final String? readingId;
  final String  stressLevel;

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin {
  static const int      _maxFullCycles = 3;
  static const Duration _phaseDuration = Duration(seconds: 4);

  late final AnimationController _controller;
  late Animation<double>         _scaleAnimation;

  GuidedBreathingPhase _phase               = GuidedBreathingPhase.idle;
  int  _completedFullCycles                 = 0;
  bool _inFinalPartialCycle                 = false;

  // ── Calm session tracking ─────────────────────────────────
  String?   _sessionId;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _phaseDuration)
      ..addStatusListener(_handleStatusChange);
    _scaleAnimation = const AlwaysStoppedAnimation<double>(1.0);
  }

  void _handleStatusChange(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) return;
    switch (_phase) {
      case GuidedBreathingPhase.inhale:
        _startHoldAfterInhale();
        break;
      case GuidedBreathingPhase.holdAfterInhale:
        _inFinalPartialCycle ? _finishSession() : _startExhale();
        break;
      case GuidedBreathingPhase.exhale:
        _startHoldAfterExhale();
        break;
      case GuidedBreathingPhase.holdAfterExhale:
        _completedFullCycles += 1;
        if (_completedFullCycles >= _maxFullCycles) _inFinalPartialCycle = true;
        _startInhale();
        break;
      default:
        break;
    }
  }

  Future<void> _startSession() async {
    _controller.stop();
    _controller.reset();
    _completedFullCycles  = 0;
    _inFinalPartialCycle  = false;

    // Save session start
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await supabase.from('calm_sessions').insert({
          'user_id':       userId,
          'reading_id':    widget.readingId,
          'stress_level':  widget.stressLevel,
          'activity_type': 'Breathing',
          'activity_name': 'Deep Breathing 4-4-4',
          'started_at':    DateTime.now().toUtc().toIso8601String(),
        }).select().single();
        _sessionId        = res['id'];
        _sessionStartTime = DateTime.now();
      }
    } catch (e) {
      print('❌ Session start error: $e');
    }

    _startInhale();
  }

  void _startInhale() {
    setState(() {
      _phase = GuidedBreathingPhase.inhale;
      _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    });
    _controller.duration = _phaseDuration;
    _controller.forward(from: 0.0);
  }

  void _startHoldAfterInhale() {
    setState(() {
      _phase          = GuidedBreathingPhase.holdAfterInhale;
      _scaleAnimation = const AlwaysStoppedAnimation<double>(1.5);
    });
    _controller.duration = _phaseDuration;
    _controller.forward(from: 0.0);
  }

  void _startExhale() {
    setState(() {
      _phase = GuidedBreathingPhase.exhale;
      _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    });
    _controller.duration = _phaseDuration;
    _controller.forward(from: 0.0);
  }

  void _startHoldAfterExhale() {
    setState(() {
      _phase          = GuidedBreathingPhase.holdAfterExhale;
      _scaleAnimation = const AlwaysStoppedAnimation<double>(1.0);
    });
    _controller.duration = _phaseDuration;
    _controller.forward(from: 0.0);
  }

  Future<void> _finishSession() async {
    _controller.stop();
    setState(() => _phase = GuidedBreathingPhase.finished);
    await _saveSessionEnd(completed: true);
  }

  Future<void> _saveSessionEnd({required bool completed}) async {
    if (_sessionId == null) return;
    try {
      final duration = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0;
      await supabase.from('calm_sessions').update({
        'duration_seconds': duration,
        'completed':        completed,
        'ended_at':         DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _sessionId!);
      _sessionId        = null;
      _sessionStartTime = null;
    } catch (e) {
      print('❌ Session end error: $e');
    }
  }

  void _stopSession() {
    _controller.stop();
    setState(() {
      _phase               = GuidedBreathingPhase.idle;
      _completedFullCycles = 0;
      _inFinalPartialCycle = false;
      _scaleAnimation      = const AlwaysStoppedAnimation<double>(1.0);
    });
  }

  Future<void> _endSessionAndReturn() async {
    if (_sessionId != null) {
      await _saveSessionEnd(completed: _phase == GuidedBreathingPhase.finished);
    }
    _stopSession();
    if (mounted) Navigator.of(context).pop();
  }

  String get _phaseLabel {
    switch (_phase) {
      case GuidedBreathingPhase.inhale:          return 'Inhale';
      case GuidedBreathingPhase.holdAfterInhale:
      case GuidedBreathingPhase.holdAfterExhale: return 'Hold';
      case GuidedBreathingPhase.exhale:          return 'Exhale';
      case GuidedBreathingPhase.finished:        return 'Session Complete';
      default:                                   return 'Ready';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEEF1),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: _endSessionAndReturn,
        ),
        title: Text(
          'High Stress',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Deep Breathing Exercise',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: Color(0xFF1A2744),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Follow the rhythm to slow your breathing.',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: Color(0xFF1A2744),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _BreathingSphere(label: _phaseLabel),
                    ),
                    const SizedBox(height: 56),
                    const Text(
                      'Let your breath fill your chest.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        color: Color(0xFF1A2744),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _phase == GuidedBreathingPhase.idle
                      ? _startSession
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8647A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _endSessionAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8647A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'End Session',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingSphere extends StatelessWidget {
  const _BreathingSphere({required this.label});

  final String label;
  static const double _size = 180;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFFFDAE2),
            const Color(0xFFF5B8C4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          color: Color(0xFFE8647A),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}