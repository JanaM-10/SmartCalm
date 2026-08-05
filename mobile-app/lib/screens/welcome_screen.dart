import 'package:flutter/material.dart';

import '../widgets/smartcalm_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _background = Color(0xFF1A2744);
  static const _white = Color(0xFFFFFFFF);
  static const _accent = Color(0xFF3ABFAC);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  void _goToSignUp(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/signup');
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _buildBrandTitle() {
    const titleStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      height: 1.1,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: titleStyle,
        children: [
          const TextSpan(
            text: 'Smart',
            style: TextStyle(color: _white),
          ),
          TextSpan(
            text: 'Calm',
            style: titleStyle.copyWith(color: _accent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmartCalmLogo(
                      size: _logoSize(context),
                      color: _white,
                    ),
                    const SizedBox(height: 20),
                    _buildBrandTitle(),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 52,
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
                  child: const Text('Get started'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _goToLogin(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _white,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: _white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_pillRadius),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('I already have an account'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static double _logoSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 72;
    if (width > 600) return 120;
    return 88;
  }
}
