import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../widgets/smartcalm_logo.dart';

class ModerateScreen extends StatefulWidget {
  const ModerateScreen({super.key});

  @override
  State<ModerateScreen> createState() => _ModerateScreenState();
}

class _ModerateScreenState extends State<ModerateScreen> {
  static const _background = Color(0xFFFFFBF0);
  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _subtitleTan = Color(0xFF8B7355);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  double? _heartRate;
  double? _skinTemp;
  double? _skinResponse;
  double? _movement;
  String _lastSync = 'Not started';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchLatestReading();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 16),
      (_) => _fetchLatestReading(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestReading() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await supabase
          .from('stress_readings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _heartRate    = res['heart_rate']?.toDouble();
          _skinTemp     = res['skin_temp']?.toDouble();
          _skinResponse = res['skin_response']?.toDouble();
          _movement     = res['movement']?.toDouble();
          _lastSync     = _formatTime(res['created_at']);
        });
      }
    } catch (e) {
      print('❌ Fetch error: $e');
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return 'Unknown';
    }
  }

  TextStyle get _baseTextStyle => const TextStyle(
        fontFamily: _fontFamily,
        color: _navy,
      );

  Widget _buildBrandHeader() {
    const titleStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      height: 1.1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              style: titleStyle,
              children: [
                const TextSpan(
                  text: 'Smart',
                  style: TextStyle(color: _navy),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Calm', style: titleStyle.copyWith(color: _orange)),
                        const SizedBox(height: 4),
                        Container(height: 3, color: _orange),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SmartCalmLogoSmall(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrandHeader(),
              const SizedBox(height: 20),
              _ConnectionCard(lastSync: _lastSync),
              const SizedBox(height: 48),
              Text(
                'Mild',
                textAlign: TextAlign.center,
                style: _baseTextStyle.copyWith(
                  color: _orange,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your body is showing signs of stress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _subtitleTan,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 70),
              _SensorGrid(
                heartRate:    _heartRate,
                skinTemp:     _skinTemp,
                skinResponse: _skinResponse,
                movement:     _movement,
              ),
              const SizedBox(height: 60),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
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
                  child: const Text('Start monitoring'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.lastSync});

  final String lastSync;

  static const _orange = Color(0xFFF5A623);
  static const _connectionBg = Color(0xFFFFF5E6);
  static const _subtitleTan = Color(0xFF8B7355);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _connectionBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_rounded, color: _orange, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Connected',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.bold,
                      color: _orange,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, color: _subtitleTan.withValues(alpha: 0.25)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection: Wi-Fi',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.bold,
                        color: _subtitleTan,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last sync: $lastSync',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        color: _subtitleTan,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({
    required this.heartRate,
    required this.skinTemp,
    required this.skinResponse,
    required this.movement,
  });

  final double? heartRate;
  final double? skinTemp;
  final double? skinResponse;
  final double? movement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                icon: Icons.favorite_rounded,
                label: 'Heart Rate',
                value: heartRate != null
                    ? '${heartRate!.toStringAsFixed(0)} bpm'
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon: Icons.back_hand_rounded,
                label: 'Skin Response',
                value: skinResponse != null
                    ? '${skinResponse!.toStringAsFixed(2)} V'
                    : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                icon: Icons.thermostat_rounded,
                label: 'Skin Temp',
                value: skinTemp != null
                    ? '${skinTemp!.toStringAsFixed(1)}°C'
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon: Icons.show_chart_rounded,
                label: 'Movement',
                value: movement != null
                    ? '${movement!.toStringAsFixed(2)} g'
                    : '—',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _cardCream = Color(0xFFFEF6E4);
  static const _iconCircleBg = Color(0xFFFFE8C8);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _iconCircleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _orange, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _fontFamily,
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.w600,
              color: _orange,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}