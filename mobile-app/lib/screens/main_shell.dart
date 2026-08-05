import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import 'home_calm_screen.dart';
import 'moderate_screen.dart';
import 'high_screen.dart';
import 'calm_now_calm_screen.dart';
import 'calm_moderate.dart';
import 'calm_high.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  String _stressLevel = 'Calm';
  Timer? _stressTimer;

  // ── Selected color changes based on stress ────────────────
  Color get _selectedColor => switch (_stressLevel) {
    'Mild' => const Color(0xFFF5A623),
    'High' => const Color(0xFFE8647A),
    _      => const Color(0xFF3ABFAC),
  };

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _fetchStressLevel();
    _stressTimer = Timer.periodic(
      const Duration(seconds: 16),
      (_) => _fetchStressLevel(),
    );
  }

  @override
  void dispose() {
    _stressTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStressLevel() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final res = await supabase
          .from('stress_readings')
          .select('stress_level')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _stressLevel = res['stress_level'] ?? 'Calm';
        });
      }
    } catch (e) {
      print('❌ Stress fetch error: $e');
    }
  }

  // ── Home screen based on stress ───────────────────────────
  Widget get _homeScreen => switch (_stressLevel) {
    'High' => const HighScreen(),
    'Mild' => const ModerateScreen(),
    _      => const HomeCalmScreen(),
  };

  // ── Calm Now screen based on stress ───────────────────────
  Widget get _calmNowScreen => switch (_stressLevel) {
    'High' => const CalmHighScreen(),
    'Mild' => const CalmModerateScreen(),
    _      => const CalmNowCalmScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeScreen,
      _calmNowScreen,
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
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
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: _currentIndex == 0,
                  selectedColor: _selectedColor,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.spa_rounded,
                  label: 'Calm Now',
                  selected: _currentIndex == 1,
                  selectedColor: _selectedColor,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.assessment_rounded,
                  label: 'Reports',
                  selected: _currentIndex == 2,
                  selectedColor: _selectedColor,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: _currentIndex == 3,
                  selectedColor: _selectedColor,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? selectedColor
        : const Color(0xFF1A2744);

    return InkWell(
      onTap: onTap,
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
                fontFamily: 'DM Sans',
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