import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'reset_password_screen.dart';

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
    final error = await auth.forgotPassword(_emailController.text.trim());

    if (mounted) {
      if (error != null) {
        setState(() => _error = error);
      } else {
        setState(() {
          _success = 'If that email is registered, you will receive a password reset link shortly.';
          _emailSent = true;
        });
      }
    }
  }

  void _parseAndNavigate() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;

    Uri? uri;
    try {
      uri = Uri.parse(link);
    } catch (_) {
      setState(() => _error = 'Invalid link format');
      return;
    }

    final queryParams = uri.queryParameters;
    final email = queryParams['email'];
    final token = queryParams['token'];

    if (email == null || token == null) {
      setState(() => _error = 'Could not find reset token in the link');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(email: email, token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                    'Reset Password',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
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
                      labelText: 'Email',
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
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Enter a valid email',
                  ),
                  if (_emailSent) ...[
                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    const SizedBox(height: 16),
                    Text(
                      'Paste the reset link from your email below:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      hintText: 'Paste full reset link here',
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
                        child: const Text('Continue',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                            : const Text('Send Reset Link',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                        text: 'Back to ',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
