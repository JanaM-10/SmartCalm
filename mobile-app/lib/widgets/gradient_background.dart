import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Subtle vertical gradient from lighter blue at top to [AppColors.secondary] at bottom.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC2E7F0),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: child,
    );
  }
}
