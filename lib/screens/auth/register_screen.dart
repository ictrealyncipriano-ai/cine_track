import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'verification_sent_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _country;
  bool _acceptTerms = false;
  bool _marketingOptIn = false;
  int _passwordStrength = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showSuccess = false;
  String? _error;

  static const _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
    'Switzerland',
    'Austria',
    'Belgium',
    'Ireland',
    'Portugal',
    'Greece',
    'Poland',
    'Czech Republic',
    'Japan',
    'South Korea',
    'China',
    'India',
    'Philippines',
    'Indonesia',
    'Malaysia',
    'Thailand',
    'Vietnam',
    'Singapore',
    'Brazil',
    'Mexico',
    'Argentina',
    'Colombia',
    'Chile',
    'Peru',
    'South Africa',
    'Nigeria',
    'Egypt',
    'Kenya',
    'New Zealand',
    'Turkey',
    'Russia',
    'Ukraine',
    'Israel',
    'Saudi Arabia',
    'United Arab Emirates',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _error = 'You must agree to the Terms of Service and Privacy Policy');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth != null
          ? '${_dateOfBirth!.year.toString().padLeft(4, '0')}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
          : null,
      country: _country,
      marketingOptIn: _marketingOptIn,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (mounted) {
      if (error != null) {
        setState(() => _error = error);
      } else {
        setState(() => _showSuccess = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationSentScreen(email: _emailController.text.trim()),
            ),
          );
        }
      }
    }
  }

  Color _strengthColor() {
    return switch (_passwordStrength) {
      0 => Colors.red,
      1 => Colors.orange,
      2 => Colors.amber,
      3 => Colors.lightGreen,
      _ => Colors.green,
    };
  }

  String _strengthLabel() {
    return switch (_passwordStrength) {
      0 => 'Weak',
      1 => 'Fair',
      2 => 'Good',
      3 => 'Strong',
      _ => 'Very strong',
    };
  }

  void _onPasswordChanged(String v) {
    int strength = 0;
    if (v.length >= 8) strength++;
    if (v.contains(RegExp(r'[A-Z]'))) strength++;
    if (v.contains(RegExp(r'[a-z]'))) strength++;
    if (v.contains(RegExp(r'[0-9]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 120, now.month, now.day);
    final maxDate = DateTime(now.year - 13, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: null,
      validator: validator,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_showSuccess) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 16),
              Text('Account created!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ResponsiveContainer(
              maxWidth: 600,
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
                  Text(
                    'Create Account',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outlined,
                    validator: (v) =>
                        v != null && v.trim().isNotEmpty ? null : 'Name is required',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                    validator: (v) {
                      if (v == null || v.trim().length < 3) return 'Min 3 characters';
                      if (v.trim().length > 50) return 'Max 50 characters';
                      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v.trim())) {
                        return 'Letters, numbers, _ and - only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter a valid email';
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      return emailRegex.hasMatch(v.trim()) ? null : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone (optional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(v.trim())) {
                        return 'Invalid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (optional)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: _dateOfBirth != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _dateOfBirth = null),
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
                            : '',
                        style: TextStyle(
                          color: _dateOfBirth != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Country (optional)',
                      prefixIcon: const Icon(Icons.language),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _country,
                        isExpanded: true,
                        dropdownColor: Theme.of(context).cardColor,
                        hint: Text(
                          'Select your country',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        ),
                        items: _countries.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (v) => setState(() => _country = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outlined,
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    onChanged: _onPasswordChanged,
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Min 8 characters';
                      if (v.length > 72) return 'Max 72 characters';
                      if (!v.contains(RegExp(r'[A-Z]'))) return 'Needs an uppercase letter';
                      if (!v.contains(RegExp(r'[a-z]'))) return 'Needs a lowercase letter';
                      if (!v.contains(RegExp(r'[0-9]'))) return 'Needs a digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength / 4,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(_strengthColor()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _strengthLabel(),
                      style: TextStyle(fontSize: 12, color: _strengthColor()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_outlined,
                    obscureText: _obscureConfirm,
                    suffix: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                      ),
                      tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) =>
                        v == _passwordController.text ? null : 'Passwords do not match',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _marketingOptIn,
                        onChanged: (v) => setState(() => _marketingOptIn = v ?? false),
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _marketingOptIn = !_marketingOptIn),
                          child: Text(
                            'Send me movie recommendations and updates via email',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (!_acceptTerms || auth.isLoading) ? null : _submit,
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
                          : const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
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
      ),
    );
  }
}
