import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config.dart';
import '../../helpers/error_message.dart';
import '../../helpers/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_error_banner.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  String? _error;
  bool _emailNotVerified = false;
  bool _resendSent = false;
  bool _verifying = false;
  bool _codeVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _emailNotVerified = false;
      _resendSent = false;
      _codeVerified = false;
      _codeController.clear();
    });

    final auth = context.read<AuthProvider>();
    final rawError = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() {
        _error = displayError;
        _emailNotVerified = isEmailNotVerifiedError(rawError);
      });
      showAuthErrorSnackBar(context, displayError);
    } else {
      if (mounted) {
        context.go('/browse');
      }
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final rawError = await auth.resendVerification(_emailController.text.trim());

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() => _error = displayError);
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _resendSent = true;
        _error = AppLocalizations.of(context)!.newVerificationLinkSent;
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() {
      _verifying = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final rawError = await auth.verifyEmailCode(
      _emailController.text.trim(),
      code,
    );

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() {
        _error = displayError;
        _verifying = false;
      });
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _codeVerified = true;
        _verifying = false;
        _error = null;
      });
      _submit();
    }
  }

  void _showApiUrlDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.apiUrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: AppConfig.apiBaseUrl,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.apiUrlDescription,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await AppConfig.setApiBaseUrl(url);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.apiUrlUpdated)),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
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
            child: ResponsiveContainer(
              maxWidth: 480,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_creation_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onLongPress: _showApiUrlDialog,
                    child: Text(
                      l10n.welcomeBack,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPress: _showApiUrlDialog,
                    child: Text(
                      AppConfig.apiBaseUrl,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.invalidEmail;
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      return emailRegex.hasMatch(v.trim()) ? null : l10n.invalidEmail;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                        tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        v != null && v.length >= 8 ? null : l10n.minPasswordChars,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.go('/login/forgot-password');
                      },
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        fillColor: WidgetStateProperty.resolveWith((states) =>
                            _rememberMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      Text(l10n.rememberMe,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    AuthErrorBanner(message: _error!),
                    if (_emailNotVerified) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _resendSent ? null : _resend,
                        child: Text(
                          _resendSent ? l10n.verificationEmailSent : l10n.resendVerification,
                          style: TextStyle(
                            color: _resendSent
                                ? Colors.greenAccent
                                : Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_codeVerified)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                l10n.emailVerifiedSigningIn,
                                style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _verifying ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _verifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.verifyCode,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.signIn,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      context.go('/login/register');
                    },
                    child: Text.rich(
                      TextSpan(
                        text: l10n.noAccount,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14),
                        children: [
                          TextSpan(
                            text: l10n.signUp,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
