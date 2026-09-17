import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_error_banner.dart';
import '../../l10n/app_localizations.dart';

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
    final rawError = await auth.resendVerification(widget.email);

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() {
        _message = displayError;
        _sent = false;
        _cooldown = 0;
      });
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _message = AppLocalizations.of(context)!.newCodeSent;
        _sent = true;
        _cooldown = 60;
      });
      _startCooldown();
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    final auth = context.read<AuthProvider>();
    final rawError = await auth.verifyEmailCode(widget.email, code);

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() {
        _message = displayError;
        _verified = false;
      });
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _verified = true;
        _message = AppLocalizations.of(context)!.emailVerifiedSuccess;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

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
                  _verified ? l10n.emailVerified : l10n.checkYourEmail,
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_verified) ...[
                  Text(
                    l10n.verificationSentTo,
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
                    l10n.codeExpires10Min,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    l10n.youCanNowLogIn,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_message != null && !_verified) ...[
                  const SizedBox(height: 16),
                  if (_sent)
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    AuthErrorBanner(message: _message!),
                ],
                if (_verified) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.goToSignIn,
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
                      label: Text(l10n.verifyCode),
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
                      label: Text(_cooldown > 0 ? l10n.resendCodeCountdown(_cooldown) : l10n.resendCode),
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
                          text: l10n.backTo,
                           style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 14),
                          children: [
                            TextSpan(
                              text: l10n.signIn,
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
