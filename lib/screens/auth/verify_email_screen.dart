import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_error_banner.dart';
import '../../l10n/app_localizations.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  String? _message;
  bool _sent = false;
  bool _verifying = false;
  bool _verified = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email;
    if (email == null) return;

    final rawError = await auth.resendVerification(email);

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() {
        _message = displayError;
        _sent = false;
      });
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _message = AppLocalizations.of(context)!.newCodeSent;
        _sent = true;
      });
    }
  }

  Future<void> _verifyCode() async {
    final auth = context.read<AuthProvider>();
    final email = auth.user?.email;
    if (email == null) return;

    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() {
      _verifying = true;
      _message = null;
    });

    final rawError = await auth.verifyEmailCode(email, code);

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() {
        _message = displayError;
        _verifying = false;
      });
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _verified = true;
        _verifying = false;
        _message = AppLocalizations.of(context)!.emailVerifiedSuccess;
      });
      await auth.checkAuth();
      if (!mounted) return;
      context.go('/browse');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? '';
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
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.emailNotVerified,
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.verifyEmailDescription,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  if (_sent || _verified)
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
                if (!_verified) ...[
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
                      if (v.length == 6) _verifyCode();
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.enter6DigitCode,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _resend,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.resendVerificationEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (!_verified) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _verifying ? null : _verifyCode,
                      icon: _verifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
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
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(l10n.iVerifiedSignIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        context.go('/landing');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOut),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
