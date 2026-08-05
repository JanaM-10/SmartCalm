import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../widgets/smartcalm_logo.dart';

const Color _rpScaffoldBg   = Color(0xFFF7F9FB);
const Color _rpNavy         = Color(0xFF1A2744);
const Color _rpTeal         = Color(0xFF3ABFAC);
const Color _rpOrange       = Color(0xFFF5A623);
const Color _rpCoral        = Color(0xFFE8647A);
const Color _rpGrey         = Color(0xFF757575);
const Color _rpChartSurface = Color(0xFFFDFDFE);
const String _rpFont        = 'DM Sans';
const String _apiUrl        = 'https://smartcalm-api.onrender.com';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summary      = {};
  Map<String, dynamic> _distribution = {};
  List<dynamic>        _timeline     = [];
  List<dynamic>        _episodes     = [];
  List<String>         _insights     = [];
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await http.get(
        Uri.parse('$_apiUrl/reports/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _summary      = data['summary']      ?? {};
          _distribution = data['distribution'] ?? {};
          _timeline     = data['timeline']     ?? [];
          _episodes     = data['episodes']     ?? [];
          _insights     = List<String>.from(data['insights'] ?? []);
          _isLoading    = false;
        });
      }
    } catch (e) {
      print('❌ Reports fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _todayDateLabel() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return 'Today, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rpScaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchReports,
          color: _rpTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reports', style: _ts(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_todayDateLabel(), style: _ts(fontSize: 13, color: _rpGrey)),
                        ],
                      ),
                    ),
                    const SmartCalmLogoSmall(),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: _rpTeal),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: _TodaySummaryCard(summary: _summary)),
                      const SizedBox(width: 12),
                      Expanded(child: _StressDistributionCard(distribution: _distribution)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WeeklyTimelineCard(timeline: _timeline),
                  const SizedBox(height: 16),
                  if (_episodes.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _EpisodeCard(
                            episodes: _episodes,
                            currentIndex: _currentEpisodeIndex,
                            onNext: () {
                              setState(() {
                                _currentEpisodeIndex =
                                    (_currentEpisodeIndex + 1) % _episodes.length;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _StressEpisodesCard(episodes: _episodes)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _InsightsCard(insights: _insights),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _ts({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = _rpNavy,
}) {
  return TextStyle(fontFamily: _rpFont, fontSize: fontSize, fontWeight: fontWeight, color: color);
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final avg      = summary['avg_stress']?.toStringAsFixed(2) ?? '—';
    final peak     = summary['peak_stress'] ?? '—';
    final total    = summary['total_readings']?.toString() ?? '—';
    final episodes = summary['total_episodes']?.toString() ?? '—';

    return _ReportsCard(
      title: "Today's Summary",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLine('Avg stress: $avg'),
          _SummaryLine('Episodes: $episodes'),
          _SummaryLine('Total readings: $total'),
          _SummaryLine('Peak stress: $peak'),
        ],
      ),
    );
  }
}

class _StressDistributionCard extends StatelessWidget {
  const _StressDistributionCard({required this.distribution});
  final Map<String, dynamic> distribution;

  @override
  Widget build(BuildContext context) {
    final calm  = (distribution['Calm'] ?? 0).toDouble();
    final mild  = (distribution['Mild'] ?? 0).toDouble();
    final high  = (distribution['High'] ?? 0).toDouble();
    final total = calm + mild + high;

    final calmPct = total > 0 ? (calm / total * 100).toStringAsFixed(0) : '0';
    final mildPct = total > 0 ? (mild / total * 100).toStringAsFixed(0) : '0';
    final highPct = total > 0 ? (high / total * 100).toStringAsFixed(0) : '0';

    final calmR = total > 0 ? calm / total : 0.5;
    final mildR = total > 0 ? mild / total : 0.3;
    final highR = total > 0 ? high / total : 0.2;

    return _ReportsCard(
      title: "Stress Distribution",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _PieChartPainter(
                calmRatio: calmR.toDouble(),
                mildRatio: mildR.toDouble(),
                highRatio: highR.toDouble(),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendDot(color: _rpTeal,   label: '$calmPct%'),
              _LegendDot(color: _rpOrange, label: '$mildPct%'),
              _LegendDot(color: _rpCoral,  label: '$highPct%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTimelineCard extends StatelessWidget {
  const _WeeklyTimelineCard({required this.timeline});
  final List<dynamic> timeline;

  @override
  Widget build(BuildContext context) {
    final labels = timeline.map((t) {
      try {
        final dt = DateTime.parse(t['date']);
        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        return days[dt.weekday - 1];
      } catch (_) {
        return t['date'].toString().substring(5);
      }
    }).toList();

    final List<double> values = timeline
        .map((t) => ((t['avg_stress'] ?? 0.0) as num).toDouble())
        .toList();

    return _ReportsCard(
      title: 'Weekly Stress Timeline',
      centerTitle: true,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: values.isEmpty
                  ? const Center(child: Text('No data yet', style: TextStyle(color: _rpGrey)))
                  : CustomPaint(
                      painter: _LineChartPainter(values: values),
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) => _AxisLabel(l)).toList(),
          ),
        ],
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episodes,
    required this.currentIndex,
    required this.onNext,
  });

  final List<dynamic> episodes;
  final int currentIndex;
  final VoidCallback onNext;

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '—';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m  = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ap';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep       = episodes[currentIndex];
    final duration = ep['duration_minutes']?.toStringAsFixed(1) ?? '—';
    final time     = _formatTime(ep['start']);
    final level    = ep['level'] ?? '—';

    return _ReportsCard(
      title: 'Episode ${currentIndex + 1}',
      footer: Text(
        '${currentIndex + 1} of ${episodes.length} episodes',
        style: const TextStyle(fontFamily: _rpFont, color: _rpGrey, fontSize: 11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLine('Duration: $duration min'),
          _SummaryLine('Time: $time'),
          _SummaryLine('Level: $level'),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: episodes.length > 1 ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rpNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontFamily: _rpFont, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              child: const Text('Next Episode'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StressEpisodesCard extends StatelessWidget {
  const _StressEpisodesCard({required this.episodes});
  final List<dynamic> episodes;

  @override
  Widget build(BuildContext context) {
    return _ReportsCard(
      title: 'Stress Episodes',
      child: SizedBox(
        height: 140,
        child: episodes.isEmpty
            ? const Center(child: Text('No episodes yet', style: TextStyle(color: _rpGrey)))
            : Padding(
                padding: const EdgeInsets.only(top: 4, right: 8, left: 4),
                child: CustomPaint(
                  painter: _BarChartPainter(episodes: episodes),
                  child: const SizedBox.expand(),
                ),
              ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    final text = insights.isNotEmpty
        ? insights.join('\n\n')
        : 'Keep monitoring to generate insights.';

    return _ReportsCard(
      title: 'Insights',
      child: Text(
        text,
        style: const TextStyle(fontFamily: _rpFont, color: _rpNavy, fontSize: 14, height: 1.4),
      ),
    );
  }
}

class _ReportsCard extends StatelessWidget {
  const _ReportsCard({
    required this.title,
    required this.child,
    this.footer,
    this.centerTitle = false,
  });

  final String title;
  final Widget child;
  final Widget? footer;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: centerTitle ? TextAlign.center : TextAlign.start,
              style: const TextStyle(fontFamily: _rpFont, color: _rpNavy, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
          child,
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: const TextStyle(fontFamily: _rpFont, color: _rpNavy, fontSize: 12, height: 1.35)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontFamily: _rpFont, color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontFamily: _rpFont, color: _rpNavy, fontSize: 11));
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.calmRatio, required this.mildRatio, required this.highRatio});

  final double calmRatio;
  final double mildRatio;
  final double highRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect       = Rect.fromLTWH(0, 0, size.width, size.height);
    const startAngle = -3.1415926535 / 2;
    const pi2        = 3.1415926535 * 2;
    final paint      = Paint()..style = PaintingStyle.fill;

    paint.color = _rpTeal;
    canvas.drawArc(rect, startAngle, pi2 * calmRatio, true, paint);
    paint.color = _rpOrange;
    canvas.drawArc(rect, startAngle + pi2 * calmRatio, pi2 * mildRatio, true, paint);
    paint.color = _rpCoral;
    canvas.drawArc(rect, startAngle + pi2 * calmRatio + pi2 * mildRatio, pi2 * highRatio, true, paint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) =>
      old.calmRatio != calmRatio || old.mildRatio != mildRatio || old.highRatio != highRatio;
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad    = 34.0;
    const topPad     = 8.0;
    final plotBottom = size.height - 16;
    final plotTop    = topPad + 4;
    final plotLeft   = leftPad;
    final plotRight  = size.width - 8;
    final plotH      = plotBottom - plotTop;
    final plotW      = plotRight - plotLeft - 16;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(plotLeft, plotTop, plotRight, plotBottom), const Radius.circular(8)),
      Paint()..color = _rpChartSurface,
    );

    final axisPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 1;
    canvas.drawLine(Offset(plotLeft, plotTop), Offset(plotLeft, plotBottom), axisPaint);
    canvas.drawLine(Offset(plotLeft, plotBottom), Offset(plotRight, plotBottom), axisPaint);

    const yLabels = ['2', '1.5', '1', '0.5', '0'];
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.right);
    for (var i = 0; i < yLabels.length; i++) {
      final t = (i / (yLabels.length - 1)).clamp(0.0, 1.0);
      final y = plotTop + t * (plotBottom - plotTop);
      tp.text = TextSpan(text: yLabels[i], style: const TextStyle(fontFamily: _rpFont, color: _rpNavy, fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(plotLeft - 6 - tp.width, y - tp.height / 2));
    }

    if (values.isEmpty) return;

    final linePaint = Paint()..color = _rpNavy..strokeWidth = 2..style = PaintingStyle.stroke;
    final path      = Path();
    final points    = <Offset>[];
    const maxVal    = 2.0;

    for (var i = 0; i < values.length; i++) {
      final x    = plotLeft + 8 + (i / (values.length - 1).clamp(1, values.length)) * plotW;
      final norm = (values[i] / maxVal).clamp(0.0, 1.0);
      final y    = plotBottom - norm * plotH;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = _rpNavy..style = PaintingStyle.fill;
    for (final p in points) canvas.drawCircle(p, 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.values != values;
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.episodes});
  final List<dynamic> episodes;

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft  = 28.0;
    final plotRight = size.width - 8;
    final bottom    = size.height - 18;
    const top       = 12.0;

    final axisPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 1;
    canvas.drawLine(Offset(plotLeft, top), Offset(plotLeft, bottom), axisPaint);
    canvas.drawLine(Offset(plotLeft, bottom), Offset(plotRight, bottom), axisPaint);

    final gridPaint = Paint()..color = Colors.grey.shade300..strokeWidth = 0.8;
    for (var g = 1; g <= 4; g++) {
      final gy = top + (bottom - top) * g / 5;
      canvas.drawLine(Offset(plotLeft, gy), Offset(plotRight, gy), gridPaint);
    }

    final n     = episodes.length.clamp(1, 6);
    final plotW = plotRight - plotLeft - 8;
    final barW  = (plotW - (n + 1) * 8) / n;
    var x       = plotLeft + 8.0;
    final maxH  = bottom - top - 4;

    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    for (var i = 0; i < n; i++) {
      final ep    = episodes[i];
      final level = ep['level'] ?? 'Calm';
      final color = level == 'High' ? _rpCoral : _rpOrange;
      final h     = maxH * (level == 'High' ? 0.85 : 0.55);

      canvas.drawRect(Rect.fromLTWH(x, bottom - h, barW, h), Paint()..color = color);

      textPainter.text = TextSpan(
        text: 'ep${i + 1}',
        style: const TextStyle(fontFamily: _rpFont, color: _rpNavy, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + barW / 2 - textPainter.width / 2, bottom + 2));
      x += barW + 8;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.episodes != episodes;
}