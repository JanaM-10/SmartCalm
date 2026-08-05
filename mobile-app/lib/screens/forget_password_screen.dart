import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../widgets/smartcalm_logo.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  static const _background  = Color(0xFFF7F9FB);
  static const _navy        = Color(0xFF1A2744);
  static const _accent      = Color(0xFF3ABFAC);
  static const _iconCircleBg = Color(0xFFC0F0E9);
  static const _labelGrey   = Color(0xFF757575);
  static const _hintGrey    = Color(0xFF9E9E9E);
  static const _fontFamily  = 'DM Sans';
  static const _pillRadius  = 28.0;

  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading  = false;
  bool _emailSent  = false;

  TextStyle get _baseTextStyle => const TextStyle(
        fontFamily: _fontFamily,
        color: _navy,
      );

  InputDecoration _fieldDecoration({required String hintText}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_pillRadius),
      borderSide: const BorderSide(color: _accent),
    );
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: _baseTextStyle.copyWith(color: _hintGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 400;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 24 : 40,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forget Password',
                              style: _baseTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SmartCalmLogoSmall(),
                          ],
                        ),
                        SizedBox(height: isNarrow ? 32 : 40),
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              color: _iconCircleBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _emailSent
                                  ? Icons.mark_email_read_outlined
                                  : Icons.mail_outline,
                              color: _accent,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _emailSent ? 'Email sent!' : 'Reset your password',
                          textAlign: TextAlign.center,
                          style: _baseTextStyle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _emailSent
                              ? 'Check your inbox for a password reset link. Follow the link to set a new password.'
                              : 'Enter the email linked to your account and we\'ll send a reset link.',
                          textAlign: TextAlign.center,
                          style: _baseTextStyle.copyWith(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: isNarrow ? 28 : 32),
                        if (!_emailSent) ...[
                          Text(
                            'Email',
                            style: _baseTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: _baseTextStyle.copyWith(fontSize: 15),
                            decoration: _fieldDecoration(
                              hintText: 'hello@reallygreatsite.com',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _emailSent
                                ? () => Navigator.of(context).pop()
                                : (_isLoading ? null : _resetPassword),
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
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_emailSent ? 'Back to Login' : 'Send reset link'),
                          ),
                        ),
                        SizedBox(height: isNarrow ? 24 : 32),
                        if (!_emailSent)
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Remember it? ',
                                  style: _baseTextStyle.copyWith(
                                    color: _labelGrey,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Log in',
                                    style: _baseTextStyle.copyWith(
                                      color: _accent,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}