import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../widgets/smartcalm_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _background = Color(0xFFF7F9FB);
  static const _navy = Color(0xFF1A2744);
  static const _accent = Color(0xFF3ABFAC);
  static const _avatarBg = Color(0xFFC0F0E9);
  static const _labelGrey = Color(0xFF757575);
  static const _fontFamily = 'DM Sans';
  static const _pillRadius = 28.0;

  // ── User data ─────────────────────────────────────────────
  String _name = '';
  String _email = '';
  bool _isLoading = true;

  // ── Preferences ───────────────────────────────────────────
  bool _alertsEnabled = true;
  bool _wearableFeedbackEnabled = true;
  Set<String> _calmActions = {'Guided Breathing'};
  Set<String> _calmSounds = {'Quran Recitation'};

  static const _calmActionOptions = [
    'Guided Breathing',
    'Light Exercises',
    'Grounding Exercises',
  ];

  static const _calmSoundOptions = [
    'Quran Recitation',
    'Rain',
    'Ocean Waves',
    'Forest',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _name  = res['name'] ?? '';
          _email = user.email ?? '';
          _alertsEnabled         = res['alerts_enabled'] ?? true;
          _wearableFeedbackEnabled = res['wearable_feedback'] ?? true;
          _calmActions = Set<String>.from(
            res['preferred_calm_actions'] ?? ['Guided Breathing'],
          );
          _calmSounds = {res['preferred_calm_sound'] ?? 'Quran Recitation'};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Profile load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('users').update({
        'alerts_enabled':         _alertsEnabled,
        'wearable_feedback':      _wearableFeedbackEnabled,
        'preferred_calm_actions': _calmActions.toList(),
        'preferred_calm_sound':   _calmSounds.first,
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved!'),
            backgroundColor: Color(0xFF3ABFAC),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Save preferences error: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  void _toggleAlerts(bool value) {
    setState(() => _alertsEnabled = value);
    _savePreferences();
  }

  void _toggleWearableFeedback(bool value) {
    setState(() => _wearableFeedbackEnabled = value);
    _savePreferences();
  }

  void _toggleCalmAction(String option, bool selected) {
    setState(() {
      if (selected) {
        _calmActions.add(option);
      } else {
        _calmActions.remove(option);
      }
    });
    _savePreferences();
  }

  void _toggleCalmSound(String option, bool selected) {
    setState(() {
      if (selected) {
        _calmSounds = {option};
      }
    });
    _savePreferences();
  }

  TextStyle get _baseTextStyle => const TextStyle(
        fontFamily: _fontFamily,
        color: _navy,
      );

  TextStyle get _sectionTitleStyle => _baseTextStyle.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3ABFAC)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: _avatarBg,
                      child: Text(
                        _name.isNotEmpty
                            ? _name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name,
                      style: _baseTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: _baseTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Preferences', style: _sectionTitleStyle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                  children: [
                    _PreferenceRow(
                      icon: Icons.notifications_none_rounded,
                      label: 'Alerts',
                      value: _alertsEnabled,
                      onChanged: _toggleAlerts,
                    ),
                    const Divider(height: 1),
                    _PreferenceRow(
                      icon: Icons.watch_rounded,
                      label: 'Wearable Feedback',
                      value: _wearableFeedbackEnabled,
                      onChanged: _toggleWearableFeedback,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AccentPreferenceCard(
                        title: 'Preferred Calm Actions',
                        child: _CheckboxTwoColumnGrid(
                          options: _calmActionOptions,
                          selected: _calmActions,
                          onToggle: _toggleCalmAction,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AccentPreferenceCard(
                        title: 'Preferred Calm Sound',
                        child: _CheckboxTwoColumnGrid(
                          options: _calmSoundOptions,
                          selected: _calmSounds,
                          onToggle: _toggleCalmSound,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _logout,
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
                  child: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentPreferenceCard extends StatelessWidget {
  const _AccentPreferenceCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  static const _navy = Color(0xFF1A2744);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: _fontFamily,
              color: _navy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CheckboxTwoColumnGrid extends StatelessWidget {
  const _CheckboxTwoColumnGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String option, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    final leftColumn = <String>[];
    final rightColumn = <String>[];

    for (var i = 0; i < options.length; i++) {
      if (i.isEven) {
        leftColumn.add(options[i]);
      } else {
        rightColumn.add(options[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumn
                .map((option) => _ProfileCheckboxTile(
                      label: option,
                      value: selected.contains(option),
                      onChanged: (v) => onToggle(option, v),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightColumn
                .map((option) => _ProfileCheckboxTile(
                      label: option,
                      value: selected.contains(option),
                      onChanged: (v) => onToggle(option, v),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileCheckboxTile extends StatelessWidget {
  const _ProfileCheckboxTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const _navy = Color(0xFF1A2744);
  static const _accent = Color(0xFF3ABFAC);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: _accent,
                checkColor: Colors.white,
                side: const BorderSide(color: _accent, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  color: _navy,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const _navy = Color(0xFF1A2744);
  static const _accent = Color(0xFF3ABFAC);
  static const _fontFamily = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _accent),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: _fontFamily,
          color: _navy,
          fontSize: 15,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: _accent,
        activeThumbColor: Colors.white,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}