import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../widgets/smartcalm_logo.dart';

class HomeCalmScreen extends StatefulWidget {
  const HomeCalmScreen({super.key});

  @override
  State<HomeCalmScreen> createState() => _HomeCalmScreenState();
}

class _HomeCalmScreenState extends State<HomeCalmScreen> {
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  // ── Stress state ──────────────────────────────────────────
  String _stressLevel = 'Unknown';
  double _confidence  = 0.0;
  bool   _isReady     = false;

  // ── Sensor values ─────────────────────────────────────────
  double? _heartRate;
  double? _skinTemp;
  double? _skinResponse;
  double? _movement;

  // ── Connection ────────────────────────────────────────────
  bool   _isMonitoring = false;
  String _lastSync     = 'Not started';
  Timer? _pollTimer;

  // ── Colors per stress level ───────────────────────────────
  Color get _background => switch (_stressLevel) {
    'Mild' => const Color(0xFFFFFBE6),
    'High' => const Color(0xFFFFEBEB),
    _      => const Color(0xFFE6F7F5),
  };

  Color get _accent => switch (_stressLevel) {
    'Mild' => const Color(0xFFD4A017),
    'High' => const Color(0xFFE53935),
    _      => const Color(0xFF3ABFAC),
  };

  String get _stressMessage => switch (_stressLevel) {
    'Mild' => 'You seem slightly tense',
    'High' => "Let's pause together",
    _      => "You're doing okay right now",
  };

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchLatestReading();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 16),
      (_) => _fetchLatestReading(),
    );
    setState(() => _isMonitoring = true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 16),
      (_) => _fetchLatestReading(),
    );
    _fetchLatestReading();
    setState(() => _isMonitoring = true);
  }

  void _stopMonitoring() {
    _pollTimer?.cancel();
    setState(() {
      _isMonitoring = false;
      _stressLevel  = 'Unknown';
      _isReady      = false;
      _heartRate    = null;
      _skinTemp     = null;
      _skinResponse = null;
      _movement     = null;
      _lastSync     = 'Not started';
    });
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
          _stressLevel  = res['stress_level'] ?? 'Unknown';
          _confidence   = (res['confidence'] ?? 0.0).toDouble();
          _heartRate    = res['heart_rate']?.toDouble();
          _skinTemp     = res['skin_temp']?.toDouble();
          _skinResponse = res['skin_response']?.toDouble();
          _movement     = res['movement']?.toDouble();
          _isReady      = true;
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
                  style: TextStyle(color: Color(0xFF1A2744)),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _CalmBrandAccent(
                    titleStyle: titleStyle,
                    accentColor: _accent,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: _background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrandHeader(),
                const SizedBox(height: 20),
                _ConnectionCard(
                  isMonitoring: _isMonitoring,
                  lastSync: _lastSync,
                ),
                const SizedBox(height: 48),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _isReady ? _stressLevel : 'Loading...',
                    key: ValueKey(_stressLevel),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: _accent,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isReady
                      ? _stressMessage
                      : 'Waiting for first reading...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: _accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isReady && _confidence > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${(_confidence * 100).toStringAsFixed(0)}% confidence',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: _accent.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
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
                    onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
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
                    child: Text(
                      _isMonitoring ? 'Stop monitoring' : 'Start monitoring',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalmBrandAccent extends StatelessWidget {
  const _CalmBrandAccent({
    required this.titleStyle,
    required this.accentColor,
  });

  final TextStyle titleStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Calm', style: titleStyle.copyWith(color: accentColor)),
          const SizedBox(height: 4),
          Container(height: 3, color: accentColor),
        ],
      ),
    );
  }
}

// ── Connection card ────────────────────────────────────────────
class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.isMonitoring,
    required this.lastSync,
  });

  final bool   isMonitoring;
  final String lastSync;

  static const _navy = Color(0xFF1A2744);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    final color = isMonitoring
        ? const Color(0xFF3ABFAC)
        : const Color(0xFF9E9E9E);
    final bg = isMonitoring
        ? const Color(0xFFCDF4EE)
        : const Color(0xFFF5F5F5);

    return Container(
      decoration: BoxDecoration(
        color: bg,
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
                children: [
                  Icon(
                    isMonitoring
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMonitoring ? 'Connected' : 'Not connected',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, color: color.withValues(alpha: 0.25)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection: Wi-Fi',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last sync: $lastSync',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        color: _navy,
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

// ── Sensor grid ────────────────────────────────────────────────
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
                icon:  Icons.favorite_rounded,
                label: 'Heart Rate',
                value: heartRate != null
                    ? '${heartRate!.toStringAsFixed(0)} bpm'
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon:  Icons.back_hand_rounded,
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
                icon:  Icons.thermostat_rounded,
                label: 'Skin Temp',
                value: skinTemp != null
                    ? '${skinTemp!.toStringAsFixed(1)}°C'
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon:  Icons.show_chart_rounded,
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

// ── Sensor card ────────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String   label;
  final String   value;

  static const _navy         = Color(0xFF1A2744);
  static const _accent       = Color(0xFF3ABFAC);
  static const _cardSurface  = Color(0xFFFDFDFE);
  static const _iconCircleBg = Color(0xFFC0F0E9);
  static const _valueGrey    = Color(0xFF5C6B7A);
  static const _fontFamily   = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            child: Icon(icon, color: _accent, size: 24),
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
              fontWeight: FontWeight.w500,
              color: _valueGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}