import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({
    super.key,
    this.readingId,
    this.stressLevel = 'Calm',
  });

  final String? readingId;
  final String  stressLevel;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  static const _background   = Color(0xFFE6F7F5);
  static const _navy         = Color(0xFF1A2744);
  static const _subtitleGrey = Color(0xFF757575);
  static const _fontFamily   = 'DM Sans';

  static const List<Map<String, dynamic>> _activities = [
    {'label': 'Light Exercise',  'icon': Icons.self_improvement_rounded},
    {'label': 'Reading',         'icon': Icons.menu_book_rounded},
    {'label': 'Music',           'icon': Icons.music_note_rounded},
    {'label': 'Creative Hobby',  'icon': Icons.palette_rounded},
  ];

  String?   _sessionId;
  DateTime? _sessionStartTime;
  String?   _selectedActivity;

  Future<void> _startSession(String activityName) async {
    // End previous session if exists
    if (_sessionId != null) await _endSession(completed: false);

    setState(() => _selectedActivity = activityName);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await supabase.from('calm_sessions').insert({
          'user_id':       userId,
          'reading_id':    widget.readingId,
          'stress_level':  widget.stressLevel,
          'activity_type': 'Activity',
          'activity_name': activityName,
          'started_at':    DateTime.now().toUtc().toIso8601String(),
        }).select().single();
        _sessionId        = res['id'];
        _sessionStartTime = DateTime.now();
      }
    } catch (e) {
      print('❌ Session start error: $e');
    }
  }

  Future<void> _endSession({bool completed = true}) async {
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

  Future<void> _handleBack() async {
    await _endSession(completed: _sessionId != null);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _navy),
          onPressed: _handleBack,
        ),
        title: const Text(
          'Activity suggestions',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: _navy,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Take a Break with Fun Activities',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _subtitleGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              ..._activities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityCard(
                    label:    activity['label'] as String,
                    icon:     activity['icon']  as IconData,
                    selected: _selectedActivity == activity['label'],
                    onTap:    () => _startSession(activity['label'] as String),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String   label;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;

  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _cardSurface = Color(0xFFFDFDFE);
  static const _fontFamily  = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: _accent, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: _accent, size: 32),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                  fontSize: 17,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _accent, size: 24),
          ],
        ),
      ),
    );
  }
}