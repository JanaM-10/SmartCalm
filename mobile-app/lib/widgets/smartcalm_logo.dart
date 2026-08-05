import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// SmartCalm logo: stylized brain outline with heartbeat line.
/// Matches the design for use on welcome (white) and form screens (primary color).
class SmartCalmLogo extends StatelessWidget {
  const SmartCalmLogo({
    super.key,
    this.size = 80,
    this.color,
    this.showLabel = false,
  });

  final double size;
  final Color? color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Logo.png',
          width: 130,
          height: 92,
          fit: BoxFit.contain,
        ),
        if (showLabel) ...[
          SizedBox(height: size * 0.2),
          Text(
            'SMARTCALM',
            style: TextStyle(
              color: const Color.fromRGBO(194, 231, 240, 1),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: size * 0.28,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small logo for header (top-right on Login, Sign Up, Forget Password).
class SmartCalmLogoSmall extends StatelessWidget {
  const SmartCalmLogoSmall({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 5),
      child: Image.asset(
        'assets/images/Small-logo.png',
        width: 30,
        height: 27,
        fit: BoxFit.contain,
      ),
    );
  }
}
