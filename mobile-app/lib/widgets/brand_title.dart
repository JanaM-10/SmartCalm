import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Centered "SmartCalm" title with underline under "art", used on Login, Sign Up, Forget Password.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  static const double _fontSize = 28;
  static const double _underlineHeight = 3;
  static const double _underlineSpacing = 4;

  TextStyle _titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.primary,
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ) ??
        const TextStyle(
          color: AppColors.primary,
          fontSize: _fontSize,
          fontWeight: FontWeight.bold,
          height: 1.1,
        );
  }

  @override
  Widget build(BuildContext context) {
    final style = _titleStyle(context);

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'Sm'),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('art', style: style),
                    const SizedBox(height: _underlineSpacing),
                    Container(
                      height: _underlineHeight,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const TextSpan(text: 'Calm'),
          ],
        ),
      ),
    );
  }
}
