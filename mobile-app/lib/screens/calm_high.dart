import 'package:flutter/material.dart';
import 'pause_and_breath_screen.dart';

class CalmHighScreen extends StatelessWidget {
  const CalmHighScreen({super.key});

  static const _background = Color(0xFFFDEEF1);
  static const _navy = Color(0xFF1A2744);
  static const _coral = Color(0xFFE8647A);
  static const _subtitleGrey = Color(0xFF5C6B7A);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _CoralWarningTriangle(),
                    const SizedBox(height: 32),
                    Text(
                      'Your body seems tense',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        color: _navy,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's slow things down together.",
                      textAlign: TextAlign.center,
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
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GuidedBreathingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _coral,
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
                  child: const Text('Pause and breathe'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoralWarningTriangle extends StatelessWidget {
  const _CoralWarningTriangle();

  static const _coral = Color(0xFFE8647A);

  @override
  Widget build(BuildContext context) {
    const double size = 200;

    return SizedBox(
      width: size,
      height: size * 0.88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PhysicalModel(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: CustomPaint(
              size: Size(size, size * 0.88),
              painter: _TrianglePainter(color: _coral),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text(
              '!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 72,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.04)
      ..lineTo(size.width * 0.96, size.height * 0.94)
      ..lineTo(size.width * 0.04, size.height * 0.94)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}