import 'package:flutter/material.dart';
import 'guided_breathing_screen.dart';
import 'grounding_exercise_screen.dart';

/// Calm Moderate: Mild Now — guided breathing and grounding activities.
class CalmModerateScreen extends StatelessWidget {
  const CalmModerateScreen({super.key});

  static const _background = Color(0xFFFFFBF0);
  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _subtitleGrey = Color(0xFF8B7355);
  static const _mildPillBg = Color(0xFFFFF0E0);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  TextStyle get _baseTextStyle => const TextStyle(
        fontFamily: _fontFamily,
        color: _navy,
      );

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
              Text(
                'Mild Now',
                style: _baseTextStyle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Let\u2019s slow things down for a moment.',
                style: _baseTextStyle.copyWith(
                  color: _subtitleGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _mildPillBg,
                    borderRadius: BorderRadius.circular(_pillRadius),
                  ),
                  child: Text(
                    'Mild',
                    style: _baseTextStyle.copyWith(
                      color: _orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _NavCard(
                title: 'Guided breathing',
                subtitle: 'Start here \u00b7 1 min',
                icon: Icons.waves_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GuidedBreathingScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NavCard(
                title: 'Grounding exercise',
                subtitle: '5 senses \u00b7 4 min',
                icon: Icons.remove_red_eye_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GroundingExerciseScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _iconTileBg = Color(0xFFFFE8C8);
  static const _cardSurface = Color(0xFFF7F9FB);
  static const _subtitleGrey = Color(0xFF8B7355);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 4),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _iconTileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _orange, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        color: _subtitleGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DisabledAwareNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              const _DisabledAwareNavItem(
                icon: Icons.spa_rounded,
                label: 'Calm Now',
                selected: true,
                onTap: null,
              ),
              const _DisabledAwareNavItem(
                icon: Icons.assessment_rounded,
                label: 'Reports',
                selected: false,
                onTap: null,
              ),
              const _DisabledAwareNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: false,
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );
  }


class _DisabledAwareNavItem extends StatelessWidget {
  const _DisabledAwareNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const _navy = Color(0xFF1A2744);
  static const _orange = Color(0xFFF5A623);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    final Color baseColor = selected ? _orange : _navy;
    final Color color = isDisabled && !selected
        ? _navy.withValues(alpha: 0.45)
        : baseColor;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
