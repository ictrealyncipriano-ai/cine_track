import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_error_banner.dart';
import '../../l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final rawError = await auth.resetPassword(
      widget.email,
      widget.token,
      _passwordController.text,
      _confirmPasswordController.text,
    );

    if (!mounted) return;
    if (rawError != null) {
      final displayError = cleanAuthError(rawError);
      setState(() => _error = displayError);
      showAuthErrorSnackBar(context, displayError);
    } else {
      setState(() => _success = true);
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
            child: _success ? _buildSuccess(context, l10n) : Form(
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
                    l10n.setNewPassword,
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.setNewPasswordDescription,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.newPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
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
                    onChanged: (v) {
                      int s = 0;
                      if (v.length >= 8) s++;
                      if (v.contains(RegExp(r'[A-Z]'))) s++;
                      if (v.contains(RegExp(r'[a-z]'))) s++;
                      if (v.contains(RegExp(r'[0-9]'))) s++;
                      setState(() => _passwordStrength = s);
                    },
                    validator: (v) {
                      if (v == null || v.length < 8) return l10n.minPasswordChars;
                      if (!v.contains(RegExp(r'[A-Z]'))) return l10n.needsUppercase;
                      if (!v.contains(RegExp(r'[a-z]'))) return l10n.needsLowercase;
                      if (!v.contains(RegExp(r'[0-9]'))) return l10n.needsDigit;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength / 4,
                      minHeight: 4,
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(_strengthColor()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_strengthLabel(l10n), style: TextStyle(fontSize: 12, color: _strengthColor())),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: _obscureConfirm,
                    validator: (v) =>
                        v == _passwordController.text ? null : l10n.passwordsDoNotMatch,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    AuthErrorBanner(message: _error!),
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
                          : Text(l10n.resetPassword,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _strengthColor() {
    return switch (_passwordStrength) {
      0 => Colors.red, 1 => Colors.orange, 2 => Colors.amber, 3 => Colors.lightGreen,
      _ => Colors.green,
    };
  }

  String _strengthLabel(AppLocalizations l10n) {
    return switch (_passwordStrength) {
      0 => l10n.passwordStrengthWeak, 1 => l10n.passwordStrengthFair, 2 => l10n.passwordStrengthGood, 3 => l10n.passwordStrengthStrong,
      _ => l10n.passwordStrengthVeryStrong,
    };
  }

  Widget _buildSuccess(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 80,
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.passwordResetSuccess,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.passwordResetDescription,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              context.go('/browse');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.goToHome,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
