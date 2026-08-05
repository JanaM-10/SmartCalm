import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    super.key,
    this.readingId,
    this.stressLevel,
  });

  final String? readingId;
  final String? stressLevel;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _background   = Color(0xFFE6F7F5);
  static const _navy         = Color(0xFF1A2744);
  static const _accent       = Color(0xFF3ABFAC);
  static const _cardSurface  = Color(0xFFFDFDFE);
  static const _hintGrey     = Color(0xFF9E9E9E);
  static const _fontFamily   = 'DM Sans';
  static const _pillRadius   = 28.0;
  static const _maxCharacters = 500;

  final _controller = TextEditingController();
  int    _writingSeconds = 0;
  Timer? _writingTimer;
  bool   _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() { if (mounted) setState(() {}); });
    _writingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _writingSeconds++);
    });
  }

  @override
  void dispose() {
    _writingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatWritingTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveJournal() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('journal_entries').insert({
          'user_id':      userId,
          'reading_id':   widget.readingId,
          'stress_level': widget.stressLevel,
          'content':      text,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal saved ✅'),
            backgroundColor: Color(0xFF3ABFAC),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Journal save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save journal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Journal',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _navy,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'How are you feeling right now?',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: _cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  maxLines: 8,
                  minLines: 6,
                  maxLength: _maxCharacters,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    color: _navy,
                    fontSize: 15,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write freely, this is just for you. No one else can see this ....',
                    hintStyle: TextStyle(
                      fontFamily: _fontFamily,
                      color: _hintGrey,
                      fontSize: 15,
                      height: 1.45,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_controller.text.length} / $_maxCharacters',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Writing for ${_formatWritingTime(_writingSeconds)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveJournal,
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
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('End session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}