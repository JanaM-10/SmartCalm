import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CalmSoundItem {
  const CalmSoundItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
  final String   id;
  final String   name;
  final String   description;
  final IconData icon;
}

const List<CalmSoundItem> kCalmSounds = [
  CalmSoundItem(id: 'rain',   name: 'Rain',             description: 'Soft rain to relax and slow breathing', icon: Icons.cloud_rounded),
  CalmSoundItem(id: 'quran',  name: 'Quran Recitation', description: 'Calm and peaceful recitation',          icon: Icons.menu_book_rounded),
  CalmSoundItem(id: 'ocean',  name: 'Ocean Waves',      description: 'Gentle waves for relaxation',           icon: Icons.waves_rounded),
  CalmSoundItem(id: 'forest', name: 'Forest',           description: 'Peaceful forest with birdsong',         icon: Icons.park_rounded),
];

class CalmSoundsScreen extends StatefulWidget {
  const CalmSoundsScreen({
    super.key,
    this.readingId,
    this.stressLevel = 'Calm',
  });

  final String? readingId;
  final String  stressLevel;

  @override
  State<CalmSoundsScreen> createState() => _CalmSoundsScreenState();
}

class _CalmSoundsScreenState extends State<CalmSoundsScreen> {
  static const _background  = Color(0xFFE6F7F5);
  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _fontFamily  = 'DM Sans';
  static const _pillRadius  = 28.0;

  CalmSoundItem? _selectedSound;
  bool _isPlaying       = false;
  int  _currentSeconds  = 0;
  int  _listeningSeconds = 0;
  static const int _totalSeconds = 120;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Calm session tracking ─────────────────────────────────
  String?   _sessionId;
  DateTime? _sessionStartTime;

  String _getAssetPath(String soundId) {
    switch (soundId) {
      case 'rain':   return 'sounds/rain.mp3';
      case 'quran':  return 'sounds/Quran.mp3';
      case 'ocean':  return 'sounds/ocean.mp3';
      case 'forest': return 'sounds/forest.mp3';
      default:       return 'sounds/rain.mp3';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSound = kCalmSounds.first;
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startSessionTracking(String soundName) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final res = await supabase.from('calm_sessions').insert({
          'user_id':       userId,
          'reading_id':    widget.readingId,
          'stress_level':  widget.stressLevel,
          'activity_type': 'Sound',
          'activity_name': soundName,
          'started_at':    DateTime.now().toUtc().toIso8601String(),
        }).select().single();
        _sessionId        = res['id'];
        _sessionStartTime = DateTime.now();
      }
    } catch (e) {
      print('❌ Session start error: $e');
    }
  }

  Future<void> _endSessionTracking() async {
    if (_sessionId == null) return;
    try {
      final duration = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : _listeningSeconds;
      await supabase.from('calm_sessions').update({
        'duration_seconds': duration,
        'completed':        true,
        'ended_at':         DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _sessionId!);
    } catch (e) {
      print('❌ Session end error: $e');
    }
  }

  Future<void> _playSound(CalmSoundItem sound) async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _selectedSound   = sound;
        _currentSeconds  = 0;
        _listeningSeconds = 0;
      });
      await _audioPlayer.play(AssetSource(_getAssetPath(sound.id)));
      setState(() => _isPlaying = true);
      _startTimer();
      // Start session tracking when sound starts
      await _startSessionTracking(sound.name);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _listeningSeconds++;
        if (_currentSeconds >= _totalSeconds) {
          _currentSeconds = _totalSeconds;
        } else {
          _currentSeconds++;
        }
      });
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_selectedSound == null) return;
      if (_isPlaying) {
        await _audioPlayer.pause();
        _timer?.cancel();
      } else {
        if (_audioPlayer.state == PlayerState.paused) {
          await _audioPlayer.resume();
        } else {
          await _playSound(_selectedSound!);
          return;
        }
        _startTimer();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _isPlaying       = false;
          _currentSeconds  = 0;
          _listeningSeconds = 0;
        });
      }
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> _endSession() async {
    await _stopAudio();
    await _endSessionTracking();
    if (mounted) Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1)}:${s.toString().padLeft(2, '0')}';
  }

  String _formatListeningTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _navy),
          onPressed: _endSession,
        ),
        title: const Text(
          'Calm Sounds',
          style: TextStyle(
            fontFamily: _fontFamily,
            color: _navy,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount: kCalmSounds.length,
                itemBuilder: (context, index) {
                  final sound    = kCalmSounds[index];
                  final selected = _selectedSound?.id == sound.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SoundCard(
                      sound:    sound,
                      selected: selected,
                      onTap:    () => _playSound(sound),
                    ),
                  );
                },
              ),
            ),
            _PlayerSection(
              sound:          _selectedSound,
              currentSeconds: _currentSeconds,
              totalSeconds:   _totalSeconds,
              isPlaying:      _isPlaying,
              onPlayPause:    _togglePlayPause,
              formatTime:     _formatTime,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Listening for ${_formatListeningTime(_listeningSeconds)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _endSession,
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
                  child: const Text('End session'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.sound,
    required this.selected,
    required this.onTap,
  });

  final CalmSoundItem sound;
  final bool          selected;
  final VoidCallback  onTap;

  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _cardSurface = Color(0xFFFDFDFE);
  static const _subtitleGrey = Color(0xFF757575);
  static const _fontFamily  = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: _accent, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(sound.icon, color: _accent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound.name,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sound.description,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          color: _subtitleGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent, width: 2),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: _accent, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.sound,
    required this.currentSeconds,
    required this.totalSeconds,
    required this.isPlaying,
    required this.onPlayPause,
    required this.formatTime,
  });

  final CalmSoundItem?      sound;
  final int                 currentSeconds;
  final int                 totalSeconds;
  final bool                isPlaying;
  final VoidCallback        onPlayPause;
  final String Function(int) formatTime;

  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _cardSurface = Color(0xFFFDFDFE);
  static const _fontFamily  = 'DM Sans';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top:  BorderSide(color: _accent, width: 3),
          left: BorderSide(color: _accent, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          if (sound != null) ...[
            Row(
              children: [
                Icon(sound!.icon, color: _accent, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound!.name,
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatTime(currentSeconds)} / ${formatTime(totalSeconds)}',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          color: _navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalSeconds > 0 ? currentSeconds / totalSeconds : 0,
              minHeight: 6,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: _accent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPlayPause,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}