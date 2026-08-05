import 'package:flutter/material.dart';
import 'calm_sounds_screen.dart';
import 'activities_screen.dart';
import 'journal_screen.dart';

class CalmNowCalmScreen extends StatelessWidget {
  const CalmNowCalmScreen({super.key});

  static const _background  = Color(0xFFE6F7F5);
  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _subtitleGrey = Color(0xFF757575);
  static const _calmPillBg  = Color(0xFFC0F0E9);
  static const _fontFamily  = 'DM Sans';
  static const _pillRadius  = 28.0;

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
                'Calm Now',
                style: _baseTextStyle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take a moment for yourself',
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
                    color: _calmPillBg,
                    borderRadius: BorderRadius.circular(_pillRadius),
                  ),
                  child: Text(
                    'Calm',
                    style: _baseTextStyle.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _NavCard(
                title: 'Calm Sounds',
                subtitle: 'Quran · Rain · Ocean · Forest',
                icon: Icons.music_note_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CalmSoundsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NavCard(
                title: 'Activity Suggestions',
                subtitle: 'Reading · Music · Exercise',
                icon: Icons.back_hand_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ActivitiesScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NavCard(
                title: 'Journaling',
                subtitle: 'Write how you feel',
                icon: Icons.edit_note_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JournalScreen(
                      stressLevel: 'Calm',
                    ),
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

  final String   title;
  final String   subtitle;
  final IconData icon;
  final VoidCallback onTap;

  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _iconTileBg  = Color(0xFFC0F0E9);
  static const _cardSurface = Color(0xFFF7F9FB);
  static const _subtitleGrey = Color(0xFF757575);
  static const _fontFamily  = 'DM Sans';

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
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
                child: Icon(icon, color: _accent, size: 28),
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