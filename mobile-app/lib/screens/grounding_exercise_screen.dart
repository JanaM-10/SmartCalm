import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class GroundingExerciseScreen extends StatefulWidget {
  const GroundingExerciseScreen({
    super.key,
    this.readingId,
    this.stressLevel = 'Mild',
  });

  final String? readingId;
  final String stressLevel;

  @override
  State<GroundingExerciseScreen> createState() =>
      _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<GroundingExerciseScreen> {
  static const _background = Color(0xFFFFFBF0);
  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _subtitleGrey = Color(0xFF8B7355);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  String? _sessionId;
  DateTime? _sessionStartTime;

  static const _steps = [
    _GroundingStep(
      number: 5,
      title: 'Things you can see',
      description: 'Look around slowly and notice 5 things',
    ),
    _GroundingStep(
      number: 4,
      title: 'Things you can touch',
      description: 'Feel textures near you now',
    ),
    _GroundingStep(
      number: 3,
      title: 'Things you can hear',
      description: 'Listen carefully to your surroundings',
    ),
    _GroundingStep(
      number: 2,
      title: 'Things you can smell',
      description: 'Notice any scents around you',
    ),
    _GroundingStep(
      number: 1,
      title: 'Things you can taste',
      description: 'Be present with this moment',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await supabase
            .from('calm_sessions')
            .insert({
              'user_id': userId,
              'reading_id': widget.readingId,
              'stress_level': widget.stressLevel,
              'activity_type': 'Grounding',
              'activity_name': 'Grounding Exercise',
              'started_at': DateTime.now().toUtc().toIso8601String(),
            })
            .select()
            .single();
        _sessionId = res['id'];
        _sessionStartTime = DateTime.now();
      }
    } catch (e) {
      print('❌ Session start error: $e');
    }
  }

  Future<void> _endSession() async {
    if (_sessionId != null) {
      try {
        final duration = _sessionStartTime != null
            ? DateTime.now().difference(_sessionStartTime!).inSeconds
            : 0;
        await supabase
            .from('calm_sessions')
            .update({
              'duration_seconds': duration,
              'completed': true,
              'ended_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', _sessionId!);
      } catch (e) {
        print('❌ Session end error: $e');
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Grounding exercise',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: _navy,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Notice your surroundings to refocus',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: _subtitleGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _steps.length; i++) ...[
                      if (i > 0) const SizedBox(height: 20),
                      _GroundingStepRow(step: _steps[i]),
                    ],
                    const SizedBox(height: 290),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _endSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_pillRadius),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: _fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('End session'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroundingStep {
  const _GroundingStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;
}

class _GroundingStepRow extends StatelessWidget {
  const _GroundingStepRow({required this.step});

  final _GroundingStep step;

  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _numberCircleBg = Color(0xFFFFF8F0);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _numberCircleBg,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${step.number}',
            style: const TextStyle(
              fontFamily: _fontFamily,
              color: _orange,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
