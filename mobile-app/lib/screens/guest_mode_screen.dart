import 'package:flutter/material.dart';
import '../widgets/smartcalm_logo.dart';

/// Guest Mode screen shown when user continues without logging in.
/// Introduces SmartCalm and explains how it works, with CTA buttons.
class GuestModeScreen extends StatelessWidget {
  const GuestModeScreen({super.key});

  static const _background = Color(0xFFF7F9FB);
  static const _navy = Color(0xFF1A2744);
  static const _accent = Color(0xFF3ABFAC);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goToSignUp(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/signup');
  }

  TextStyle get _baseTextStyle => const TextStyle(
        fontFamily: _fontFamily,
        color: _navy,
      );

  Widget _buildBrandTitle() {
    const titleStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      height: 1.1,
    );

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
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
                    Text(
                      'Calm',
                      style: titleStyle.copyWith(color: _accent),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 3,
                      color: _accent,
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
              const Align(
                alignment: Alignment.topRight,
                child: SmartCalmLogoSmall(),
              ),
              const SizedBox(height: 16),
              _buildBrandTitle(),
              const SizedBox(height: 8),
              Text(
                'Your personal stress-awareness companion',
                textAlign: TextAlign.center,
                style: _baseTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'What SmartCalm does',
                      textAlign: TextAlign.center,
                      style: _baseTextStyle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SmartCalm helps you stay connected with your body by understanding your stress levels.'
                      ' It offers guidance to support your well-being and bring more calm into your daily life',
                      textAlign: TextAlign.center,
                      style: _baseTextStyle.copyWith(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'How it works',
                textAlign: TextAlign.left,
                style: _baseTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              const _HowItWorksRow(
                icon: Icons.watch_rounded,
                text:
                    'Analyzes data collected from wearable sensors to continuously monitor your physiological signals and detect stress changes.',
              ),
              const SizedBox(height: 14),
              const _HowItWorksRow(
                icon: Icons.bar_chart_rounded,
                text:
                    'Classifies your stress level, allowing you to clearly understand your current state.',
              ),
              const SizedBox(height: 14),
              const _HowItWorksRow(
                icon: Icons.eco_rounded,
                text:
                    'Provides calming techniques and actionable guidance to help you relax and regain focus.',
              ),
              const SizedBox(height: 110),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _goToSignUp(context),
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
                  child: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _goToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
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
                  child: const Text('Log in'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  static const _navy = Color(0xFF1A2744);
  static const _iconContainerBg = Color(0xFFC0F0E9);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _iconContainerBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 28,
            color: _navy,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: _fontFamily,
              color: _navy,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
