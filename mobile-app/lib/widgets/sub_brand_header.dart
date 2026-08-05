import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Reusable header: "SmartCalm" text (with underline under "art") on the left,
/// brain/logo icon on the right. Matches the top header design.
class SubBrandTitleAndLogo extends StatelessWidget {
  const SubBrandTitleAndLogo({super.key});

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
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
          ColorFiltered(
            colorFilter:
                const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            child: Image.asset(
              'assets/images/Small-logo.png',
              width: 32,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
