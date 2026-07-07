import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedCountry;
  bool _marketingOptIn = false;
  String? _error;
  String? _success;
  bool _showSuccessOverlay = false;

  static const List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
    'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
    'Bahamas', 'Bangladesh', 'Belarus', 'Belgium', 'Brazil',
    'Canada', 'Chile', 'China', 'Colombia', 'Croatia',
    'Cuba', 'Czech Republic', 'Denmark', 'Egypt', 'Finland',
    'France', 'Georgia', 'Germany', 'Greece', 'Hungary',
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq',
    'Ireland', 'Israel', 'Italy', 'Japan', 'Kazakhstan',
    'Kenya', 'Kuwait', 'Latvia', 'Lithuania', 'Luxembourg',
    'Malaysia', 'Mexico', 'Monaco', 'Morocco', 'Nepal',
    'Netherlands', 'New Zealand', 'Nigeria', 'North Korea', 'Norway',
    'Pakistan', 'Palestine', 'Peru', 'Philippines', 'Poland',
    'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda',
    'Saudi Arabia', 'Serbia', 'Singapore', 'Slovakia', 'Slovenia',
    'Somalia', 'South Africa', 'South Korea', 'Spain', 'Sudan',
    'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan',
    'Thailand', 'Tunisia', 'Turkey', 'Turkmenistan', 'Ukraine',
    'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan',
    'Vatican City', 'Venezuela', 'Vietnam', 'Yemen', 'Zimbabwe',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _dobController.text = user?.dateOfBirth ?? '';
    _selectedCountry = user?.country;
    _marketingOptIn = user?.marketingOptIn ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) return;
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }

    setState(() { _error = null; _success = null; });

    final auth = context.read<AuthProvider>();
    final error = await auth.updateProfile(
      name: name,
      email: email,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      country: _selectedCountry,
      marketingOptIn: _marketingOptIn,
    );

    if (mounted) {
      if (error != null) {
        setState(() => _error = error);
      } else {
        setState(() {
          _success = null;
          _showSuccessOverlay = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (_showSuccessOverlay) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 16),
              Text('Profile updated!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  helperText: 'Changing email will require re-verification',
                  helperStyle: GoogleFonts.inter(fontSize: 11, color: Colors.orangeAccent),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                dropdownColor: Theme.of(context).cardColor,
                decoration: InputDecoration(
                  labelText: 'Country',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _selectedCountry = v),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Marketing emails', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                subtitle: Text('Receive recommendations and updates', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                value: _marketingOptIn,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _marketingOptIn = v),
              ),
              if (user?.emailVerified == false) ...[
                const SizedBox(height: 8),
                Text(
                  'Email not verified',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orangeAccent),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                Text(_success!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
