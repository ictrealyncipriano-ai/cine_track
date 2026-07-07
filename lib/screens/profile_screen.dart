import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/history_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/avatar_picker.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';
import 'my_reviews_screen.dart';
import 'sessions_screen.dart';
import 'landing_page.dart';
import 'movie_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  final VoidCallback? onSignIn;

  const ProfileScreen({super.key, this.isGuest = false, this.onSignIn});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _appVersion;

  bool _cpExpanded = false;
  final _cpController = TextEditingController();
  final _npController = TextEditingController();
  final _cnpController = TextEditingController();
  int _newPasswordStrength = 0;
  String? _pwError;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {}
  }

  @override
  void dispose() {
    _cpController.dispose();
    _npController.dispose();
    _cnpController.dispose();
    super.dispose();
  }

  void _pickAvatar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPicker(
        onPicked: (base64, mime) async {
          if (base64.isEmpty) return;
          final error = await context.read<AuthProvider>().uploadAvatar(base64, mime);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Avatar updated'),
                backgroundColor: error != null ? Theme.of(context).colorScheme.error : Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            child: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final pwController = TextEditingController();
    String? deleteError;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Account', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pwController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter your password to confirm',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (deleteError != null) ...[
                const SizedBox(height: 8),
                Text(deleteError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final pw = pwController.text;
                if (pw.isEmpty) return;
                final error = await context.read<AuthProvider>().deleteAccount(pw);
                if (error != null) {
                  setDialogState(() => deleteError = error);
                } else if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingPage()),
                    (route) => false,
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCacheCleared() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Cache', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Clear cached images and data?', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CachedNetworkImage.evictFromCache('*');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Language', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(ctx, 'English', true),
            _langOption(ctx, 'Spanish', false),
            _langOption(ctx, 'French', false),
            _langOption(ctx, 'German', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _langOption(BuildContext ctx, String name, bool selected) {
    return ListTile(
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
      title: Text(name, style: GoogleFonts.inter(color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Language switching coming soon'), backgroundColor: Colors.orangeAccent),
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('About', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/logo.png', height: 64),
            ),
            const SizedBox(height: 16),
            Text('CineTrack', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('v$_appVersion', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
            const SizedBox(height: 16),
            Text(
              'Track your movies, build watchlists, and discover new favorites.',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

    final error = await context.read<AuthProvider>().changePassword(cp, np, cnp);
    if (mounted) {
      if (error != null) {
        setState(() => _pwError = error);
      } else {
        _cpController.clear();
        _npController.clear();
        _cnpController.clear();
        setState(() {
          _cpExpanded = false;
          _pwError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Color _strengthColor() {
    return switch (_newPasswordStrength) {
      0 => Colors.red, 1 => Colors.orange, 2 => Colors.amber, 3 => Colors.lightGreen,
      _ => Colors.green,
    };
  }

  String _strengthLabel() {
    return switch (_newPasswordStrength) {
      0 => 'Weak', 1 => 'Fair', 2 => 'Good', 3 => 'Strong',
      _ => 'Very strong',
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (widget.isGuest && !auth.isAuthenticated) {
      return _buildGuestView();
    }

    return _buildAuthView(context, auth);
  }

  Widget _buildGuestView() {
    final theme = context.watch<ThemeProvider>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.person_outline_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re browsing as a guest',
              style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            _guestFeatureCard(Icons.favorite, 'Save Favorites', 'Bookmark movies you love for quick access', Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            _guestFeatureCard(Icons.bookmark, 'Build Watchlist', 'Plan what to watch next', const Color(0xFF58A6FF)),
            const SizedBox(height: 10),
            _guestFeatureCard(Icons.history, 'Track History', 'Keep a record of every movie you watch', const Color(0xFF3FB950)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: widget.onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text('Sign In / Create Account', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
            _sectionHeader('Settings'),
            _settingsItem(
              icon: theme.isDark ? Icons.light_mode : Icons.dark_mode,
              label: theme.isDark ? 'Light Mode' : 'Dark Mode',
              trailing: Switch(
                value: !theme.isDark,
                activeTrackColor: Theme.of(context).colorScheme.primary,
                activeThumbColor: Theme.of(context).colorScheme.onPrimary,
                inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                onChanged: (_) => theme.toggle(),
              ),
              onTap: () => theme.toggle(),
            ),
            _settingsItem(
              icon: Icons.language,
              label: 'Language',
              trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
              onTap: _showLanguageDialog,
            ),
            _settingsItem(
              icon: Icons.info_outline,
              label: 'About',
              trailing: _appVersion != null
                  ? Text('v$_appVersion', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)))
                  : null,
              onTap: _showAboutDialog,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _guestFeatureCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthView(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final theme = context.watch<ThemeProvider>();
    final hp = context.watch<HistoryProvider>();
    final fp = context.watch<FavoritesProvider>();
    final wp = context.watch<WatchlistProvider>();
    final recentHistory = hp.recentlyWatched;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => await hp.fetchHistory(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(user, auth),
              const SizedBox(height: 24),
              _buildStatsRow(fp, wp, hp),
              const SizedBox(height: 24),
              _buildHistorySection(recentHistory, hp),
              const SizedBox(height: 24),
              _sectionHeader('Settings'),
              _settingsItem(
                icon: theme.isDark ? Icons.light_mode : Icons.dark_mode,
                label: theme.isDark ? 'Light Mode' : 'Dark Mode',
                trailing: Switch(
                  value: !theme.isDark,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  activeThumbColor: Theme.of(context).colorScheme.onPrimary,
                  inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                  inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                  onChanged: (_) => theme.toggle(),
                ),
                onTap: () => theme.toggle(),
              ),
              _buildChangePasswordSection(auth),
              _settingsItem(
                icon: Icons.rate_review_outlined,
                label: 'My Reviews',
                trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
              ),
              _settingsItem(
                icon: Icons.language,
                label: 'Language',
                trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                onTap: _showLanguageDialog,
              ),
              _settingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon'), backgroundColor: Colors.orangeAccent),
                ),
              ),
              _settingsItem(
                icon: Icons.devices,
                label: 'Manage Sessions',
                trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen())),
              ),
              _settingsItem(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear Cache',
                onTap: _showCacheCleared,
              ),
              _settingsItem(
                icon: Icons.info_outline,
                label: 'About',
                trailing: _appVersion != null
                    ? Text('v$_appVersion', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)))
                    : null,
                onTap: _showAboutDialog,
              ),
              const SizedBox(height: 24),
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showDeleteDialog,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Delete Account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user, AuthProvider auth) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickAvatar(context),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: _buildAvatarImage(user),
                child: _buildAvatarFallback(user),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'User',
          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text('@${user?.username ?? ''}', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _infoRow(Icons.email_outlined, user?.email ?? ''),
              if (user?.phone != null && user!.phone!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _infoRow(Icons.phone_outlined, user.phone!),
                ),
              if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _infoRow(Icons.cake_outlined, user.dateOfBirth!),
                ),
              if (user?.country != null && user!.country!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _infoRow(Icons.public_outlined, user.country!),
                ),
              if (user?.marketingOptIn == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _infoRow(Icons.email_outlined, 'Marketing emails enabled', iconColor: const Color(0xFF3FB950)),
                ),
            ],
          ),
        ),
        if (user?.emailVerified == false) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Email not verified', style: GoogleFonts.inter(fontSize: 12, color: Colors.orangeAccent)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _resendVerification(auth, user?.email ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Resend',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orangeAccent),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
      ],
    );
  }

  Future<void> _resendVerification(AuthProvider auth, String email) async {
    final error = await auth.resendVerification(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Verification email sent'),
          backgroundColor: error != null ? Theme.of(context).colorScheme.error : Colors.green,
        ),
      );
    }
  }

  Widget _buildStatsRow(FavoritesProvider fp, WatchlistProvider wp, HistoryProvider hp) {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.favorite, '${fp.totalCount}', 'Favorites', Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.bookmark, '${wp.totalCount}', 'Watchlist', const Color(0xFF58A6FF))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.history, '${hp.totalCount}', 'History', const Color(0xFF3FB950))),
      ],
    );
  }

  Widget _statCard(IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List recentHistory, HistoryProvider hp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
            const SizedBox(width: 6),
            Text(
              'Watch History',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
            if (!hp.isEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '(${hp.history.length})',
                style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
              ),
            ],
            const Spacer(),
            if (!hp.isEmpty)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentHistory.isNotEmpty)
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentHistory.length > 5 ? 5 : recentHistory.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final movie = recentHistory[index];
                return SizedBox(
                  width: 140,
                  child: _historyCard(movie),
                );
              },
            ),
          )
        else if (hp.isLoading)
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _historyCardSkeleton(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                const SizedBox(height: 8),
                Text('No watch history yet', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _historyCard(movie) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailsScreen(movie: movie),
            ),
          );
        },
        child: Hero(
          tag: 'movie_poster_${movie.id}',
          child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
          children: [
            if (movie.posterUrl != null)
              CachedNetworkImage(
                imageUrl: movie.posterUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: Theme.of(context).cardColor),
                errorWidget: (_, _, _) => Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
              )
            else
              Container(color: Theme.of(context).cardColor, child: Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(movie.watchedAt),
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            if (movie.watchCount > 1)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay, size: 12, color: Theme.of(context).colorScheme.onPrimary),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.watchCount}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary),
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
    );
  }

  Widget _historyCardSkeleton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        decoration: BoxDecoration(color: Theme.of(context).cardColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10, width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8, width: 70,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection(AuthProvider auth) {
    return Column(
      children: [
        _settingsItem(
          icon: Icons.lock_outline,
          label: 'Change Password',
          trailing: Icon(_cpExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
          onTap: () => setState(() => _cpExpanded = !_cpExpanded),
        ),
        if (_cpExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpController,
                  obscureText: !_showCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_showCurrentPassword ? Icons.visibility_off : Icons.visibility),
                      tooltip: _showCurrentPassword ? 'Hide current password' : 'Show current password',
                      onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _npController,
                  obscureText: !_showNewPassword,
                  onChanged: (v) {
                    int s = 0;
                    if (v.length >= 8) s++;
                    if (v.contains(RegExp(r'[A-Z]'))) s++;
                    if (v.contains(RegExp(r'[a-z]'))) s++;
                    if (v.contains(RegExp(r'[0-9]'))) s++;
                    setState(() => _newPasswordStrength = s);
                  },
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility),
                      tooltip: _showNewPassword ? 'Hide new password' : 'Show new password',
                      onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _newPasswordStrength / 4,
                    minHeight: 4,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation(_strengthColor()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_strengthLabel(), style: TextStyle(fontSize: 12, color: _strengthColor())),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cnpController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      tooltip: _showConfirmPassword ? 'Hide confirm password' : 'Show confirm password',
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Update'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => setState(() { _cpExpanded = false; _pwError = null; }),
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
                if (_pwError != null) ...[
                  const SizedBox(height: 8),
                  Text(_pwError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
                ],

              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
      trailing: trailing ?? Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  ImageProvider? _buildAvatarImage(user) {
    final url = user?.avatarUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final parts = url.split(',');
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return MemoryImage(base64Decode(parts[1]));
      }
    }
    return CachedNetworkImageProvider(url);
  }

  Widget? _buildAvatarFallback(user) {
    if (user?.avatarUrl == null || user!.avatarUrl!.isEmpty) {
      return Icon(Icons.person, size: 48, color: Theme.of(context).colorScheme.primary);
    }
    return null;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
