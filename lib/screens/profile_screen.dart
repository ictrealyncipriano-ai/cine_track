import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'landing_page.dart';
import 'sessions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final _cpController = TextEditingController();
  final _npController = TextEditingController();
  final _cnpController = TextEditingController();
  bool _changingPassword = false;

  final _deletePwController = TextEditingController();

  String? _profileError;
  String? _profileSuccess;
  String? _pwError;
  String? _pwSuccess;
  String? _deleteError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpController.dispose();
    _npController.dispose();
    _cnpController.dispose();
    _deletePwController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?['name'] as String? ?? '';
    _emailController.text = user?['email'] as String? ?? '';
    setState(() {
      _editing = true;
      _profileError = null;
      _profileSuccess = null;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) return;
    if (!email.contains('@')) {
      setState(() => _profileError = 'Enter a valid email');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.updateProfile(name, email);

    if (mounted) {
      if (error != null) {
        setState(() {
          _profileError = error;
          _profileSuccess = null;
        });
      } else {
        setState(() {
          _editing = false;
          _profileError = null;
          _profileSuccess = 'Profile updated';
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final cp = _cpController.text;
    final np = _npController.text;
    final cnp = _cnpController.text;

    if (cp.isEmpty || np.isEmpty) {
      setState(() => _pwError = 'Fill in all password fields');
      return;
    }
    if (np.length < 8) {
      setState(() => _pwError = 'New password must be at least 8 characters');
      return;
    }
    if (np != cnp) {
      setState(() => _pwError = 'Passwords do not match');
      return;
    }

    final auth = context.read<AuthProvider>();
    final error = await auth.changePassword(cp, np, cnp);

    if (mounted) {
      if (error != null) {
        setState(() {
          _pwError = error;
          _pwSuccess = null;
        });
      } else {
        _cpController.clear();
        _npController.clear();
        _cnpController.clear();
        setState(() {
          _changingPassword = false;
          _pwError = null;
          _pwSuccess = 'Password changed successfully';
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final pw = _deletePwController.text;
    if (pw.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final error = await auth.deleteAccount(pw);

    if (mounted) {
      if (error != null) {
        setState(() => _deleteError = error);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    }
  }

  void _showDeleteDialog() {
    _deletePwController.clear();
    setState(() => _deleteError = null);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data (favorites, watchlist, and account info) will be permanently deleted.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deletePwController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter your password to confirm',
                filled: true,
                fillColor: const Color(0xFF0D1117),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_deleteError != null) ...[
              const SizedBox(height: 8),
              Text(_deleteError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(
                Icons.person,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            if (!_editing) ...[
              Text(
                user?['name'] as String? ?? 'User',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?['email'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              if (user?['email_verified'] == false) ...[
                const SizedBox(height: 4),
                Text(
                  'Email not verified',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (_editing) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        onPressed: () => setState(() {
                          _editing = false;
                          _profileError = null;
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_profileError != null) ...[
              const SizedBox(height: 12),
              Text(_profileError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            if (_profileSuccess != null) ...[
              const SizedBox(height: 12),
              Text(_profileSuccess!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            if (!_changingPassword) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _changingPassword = true;
                    _pwError = null;
                    _pwSuccess = null;
                  }),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Change Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (_changingPassword) ...[
              TextFormField(
                controller: _cpController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _npController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cnpController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Update Password'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _changingPassword = false;
                          _pwError = null;
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_pwError != null) ...[
              const SizedBox(height: 12),
              Text(_pwError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            if (_pwSuccess != null) ...[
              const SizedBox(height: 12),
              Text(_pwSuccess!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen())),
                icon: const Icon(Icons.devices, size: 18),
                label: const Text('Manage Sessions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showDeleteDialog,
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingPage()),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
