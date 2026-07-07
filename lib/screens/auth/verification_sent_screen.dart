import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class VerificationSentScreen extends StatefulWidget {
  final String email;

  const VerificationSentScreen({super.key, required this.email});

  @override
  State<VerificationSentScreen> createState() => _VerificationSentScreenState();
}

class _VerificationSentScreenState extends State<VerificationSentScreen> {
  final _codeController = TextEditingController();
  String? _message;
  bool _sent = false;
  bool _verified = false;
  int _cooldown = 0;

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _cooldown--);
      return _cooldown > 0;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final error = await auth.resendVerification(widget.email);

      if (mounted) {
        if (error != null) {
          setState(() {
            _message = error;
            _sent = false;
            _cooldown = 0;
          });
        } else {
          setState(() {
            _message = 'A new verification code has been sent.';
            _sent = true;
            _cooldown = 60;
          });
          _startCooldown();
        }
      }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    final auth = context.read<AuthProvider>();
    final error = await auth.verifyEmailCode(widget.email, code);

    if (mounted) {
      if (error != null) {
        setState(() {
          _message = error;
          _verified = false;
        });
      } else {
        setState(() {
          _verified = true;
          _message = 'Email verified successfully!';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _verified
                      ? Icons.check_circle_rounded
                      : Icons.mark_email_unread_rounded,
                  size: 80,
                  color: _verified
                      ? Colors.greenAccent
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _verified ? 'Email Verified!' : 'Check Your Email',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_verified) ...[
                  Text(
                    'We sent a verification code to',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) {
                      if (v.length == 6) {
                        _verifyCode();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code from the email. The code expires in 10 minutes.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'You can now log in to your account.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_message != null && !_verified) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _sent ? Colors.greenAccent : Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_verified) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go to Sign In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: auth.isLoading ? null : _verifyCode,
                      icon: const Icon(Icons.check),
                      label: const Text('Verify Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _cooldown > 0 ? null : _resend,
                      icon: const Icon(Icons.refresh),
                      label: Text(_cooldown > 0 ? 'Resend Code ($_cooldown)' : 'Resend Code'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: Text.rich(
                        TextSpan(
                          text: 'Back to ',
                           style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
