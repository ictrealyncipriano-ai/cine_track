import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/error_message.dart';
import '../../helpers/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_error_banner.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  String? _error;
  String? _success;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _success = null;
    });

    final auth = context.read<AuthProvider>();
    final rawError = await auth.forgotPassword(_emailController.text.trim());

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() => _error = displayError);
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() {
        _success = AppLocalizations.of(context)!.ifEmailRegistered;
        _emailSent = true;
      });
    }
  }

  void _parseAndNavigate() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;

    Uri? uri;
    try {
      uri = Uri.parse(link);
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context)!.invalidLinkFormat);
      return;
    }

    final queryParams = uri.queryParameters;
    final email = queryParams['email'];
    final token = queryParams['token'];

    if (email == null || token == null) {
      setState(() => _error = AppLocalizations.of(context)!.noResetToken);
      return;
    }

    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() => _error = AppLocalizations.of(context)!.invalidEmailInLink);
      return;
    }
    if (token.length < 10) {
      setState(() => _error = AppLocalizations.of(context)!.invalidResetToken);
      return;
    }

    context.go('/login/reset-password?email=${Uri.encodeComponent(email)}&token=${Uri.encodeComponent(token)}');
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
                    Icons.lock_reset_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.resetPasswordTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.resetPasswordDescription,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
                      enabled: !_emailSent,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.invalidEmail;
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      return emailRegex.hasMatch(v.trim()) ? null : l10n.invalidEmail;
                    },
                  ),
                  if (_emailSent) ...[
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.pasteResetLink,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      hintText: l10n.resetLinkHint,
                      prefixIcon: const Icon(Icons.link),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _parseAndNavigate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.continueAction,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    AuthErrorBanner(message: _error!),
                  ],
                  if (_success != null && !_emailSent) ...[
                    const SizedBox(height: 12),
                    Text(_success!, style: const TextStyle(color: Colors.greenAccent)),
                  ],
                  const SizedBox(height: 24),
                  if (!_emailSent)
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
                            : Text(l10n.sendResetLink,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                        text: l10n.backTo,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14),
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
