import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../core/theme/app_colors.dart';

enum GuidedBreathingPhase {
  idle,
  inhale,
  exhale,
  finished,
}

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({
    super.key,
    this.readingId,
    this.stressLevel = 'Mild',
  });

  final String? readingId;
  final String stressLevel;

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _inhaleDuration = Duration(seconds: 4);
  static const Duration _exhaleDuration = Duration(seconds: 6);
  static const Duration _totalDuration  = Duration(minutes: 1);

  late final AnimationController _controller;
  late final Animation<double>   _scaleAnimation;

  GuidedBreathingPhase _phase = GuidedBreathingPhase.idle;
  Timer?  _sessionTimer;

  // ── Calm session tracking ─────────────────────────────────
  String?  _sessionId;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _inhaleDuration)
      ..addStatusListener(_handleStatusChange);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _handleStatusChange(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed && _phase == GuidedBreathingPhase.inhale) {
      _startExhale();
    } else if (status == AnimationStatus.dismissed && _phase == GuidedBreathingPhase.exhale) {
      if (_sessionTimer != null) _startInhale();
    }
  }

  Future<void> _startSession() async {
    _stopSession();

    // Save session start to Supabase
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await supabase.from('calm_sessions').insert({
          'user_id':       userId,
          'reading_id':    widget.readingId,
          'stress_level':  widget.stressLevel,
          'activity_type': 'Breathing',
          'activity_name': 'Guided Breathing',
          'started_at': DateTime.now().toUtc().toIso8601String(),
        }).select().single();
        _sessionId        = res['id'];
        _sessionStartTime = DateTime.now();
      }
    } catch (e) {
      print('❌ Session start error: $e');
    }

    _sessionTimer = Timer(_totalDuration, () {
      if (!mounted) return;
      _finishSession();
    });
    _startInhale();
  }

  void _startInhale() {
    setState(() => _phase = GuidedBreathingPhase.inhale);
    _controller.duration = _inhaleDuration;
    _controller.forward(from: 0.0);
  }

  void _startExhale() {
    setState(() => _phase = GuidedBreathingPhase.exhale);
    _controller.duration = _exhaleDuration;
    _controller.reverse(from: 1.0);
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
          : 60;
      await supabase.from('calm_sessions').update({
        'duration_seconds': duration,
        'completed':        completed,
        'ended_at':         DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _sessionId!);
    } catch (e) {
      print('❌ Session end error: $e');
    }
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _controller.stop();
    setState(() => _phase = GuidedBreathingPhase.idle);
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
      case GuidedBreathingPhase.inhale:   return 'Inhale';
      case GuidedBreathingPhase.exhale:   return 'Exhale';
      case GuidedBreathingPhase.finished: return 'Session Complete';
      case GuidedBreathingPhase.idle:     return 'Ready';
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: _endSessionAndReturn,
        ),
        title: Text(
          'Mild Now',
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
              const SizedBox(height: 16),
              const Text(
                'Guided breathing',
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
                    Text(
                      'Inhale for 4 seconds, then exhale for 6 seconds.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _phase == GuidedBreathingPhase.idle
                      ? _startSession
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
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
                    backgroundColor: const Color(0xFFF5A623),
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
            const Color(0xFFFEF6E4),
            const Color(0xFFE8D4B0),
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
          color: Color(0xFFF5A623),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}