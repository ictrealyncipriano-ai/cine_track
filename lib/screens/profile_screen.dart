import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/history_provider.dart';
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
  String? _pwSuccess;

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
                backgroundColor: error != null ? Colors.redAccent : Colors.green,
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
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: Colors.white54)),
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
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
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
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pwController,
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
              if (deleteError != null) ...[
                const SizedBox(height: 8),
                Text(deleteError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
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
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: Text('Clear cached images and data?', style: GoogleFonts.inter(color: Colors.white54)),
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
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Language', style: TextStyle(color: Colors.white)),
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
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? const Color(0xFFFFC107) : Colors.white38),
      title: Text(name, style: GoogleFonts.inter(color: selected ? Colors.white : Colors.white54)),
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
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/logo.png', height: 64),
            ),
            const SizedBox(height: 16),
            Text('CineTrack', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('v$_appVersion', style: GoogleFonts.inter(color: Colors.white54)),
            const SizedBox(height: 16),
            Text(
              'Track your movies, build watchlists, and discover new favorites.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
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
        setState(() { _pwError = error; _pwSuccess = null; });
      } else {
        _cpController.clear();
        _npController.clear();
        _cnpController.clear();
        setState(() {
          _cpExpanded = false;
          _pwError = null;
          _pwSuccess = 'Password changed successfully';
        });
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
              style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to sync your favorites, watchlist, and history across all your devices.',
              style: GoogleFonts.inter(fontSize: 15, color: Colors.white70, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: widget.onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
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
                activeTrackColor: const Color(0xFFFFC107),
                activeThumbColor: Colors.black,
                inactiveTrackColor: Colors.white24,
                inactiveThumbColor: Colors.white54,
                onChanged: (_) => theme.toggle(),
              ),
              onTap: () => theme.toggle(),
            ),
            _settingsItem(
              icon: Icons.language,
              label: 'Language',
              trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
              onTap: _showLanguageDialog,
            ),
            _settingsItem(
              icon: Icons.info_outline,
              label: 'About',
              trailing: _appVersion != null
                  ? Text('v$_appVersion', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38))
                  : null,
              onTap: _showAboutDialog,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthView(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final theme = context.watch<ThemeProvider>();
    final hp = context.watch<HistoryProvider>();
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
              _buildHistorySection(recentHistory, hp),
              const SizedBox(height: 24),
              _sectionHeader('Settings'),
              _settingsItem(
                icon: theme.isDark ? Icons.light_mode : Icons.dark_mode,
                label: theme.isDark ? 'Light Mode' : 'Dark Mode',
                trailing: Switch(
                  value: !theme.isDark,
                  activeTrackColor: const Color(0xFFFFC107),
                  activeThumbColor: Colors.black,
                  inactiveTrackColor: Colors.white24,
                  inactiveThumbColor: Colors.white54,
                  onChanged: (_) => theme.toggle(),
                ),
                onTap: () => theme.toggle(),
              ),
              _buildChangePasswordSection(),
              _settingsItem(
                icon: Icons.rate_review_outlined,
                label: 'My Reviews',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
              ),
              _settingsItem(
                icon: Icons.language,
                label: 'Language',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: _showLanguageDialog,
              ),
              _settingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon'), backgroundColor: Colors.orangeAccent),
                ),
              ),
              _settingsItem(
                icon: Icons.devices,
                label: 'Manage Sessions',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
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
                    ? Text('v$_appVersion', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38))
                    : null,
                onTap: _showAboutDialog,
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
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
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
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
                    color: const Color(0xFFFFC107),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0D1117), width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'User',
          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text('@${user?.username ?? ''}', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(user?.email ?? '', style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
        if (user?.emailVerified == false) ...[
          const SizedBox(height: 8),
          Text('Email not verified', style: GoogleFonts.inter(fontSize: 12, color: Colors.orangeAccent)),
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

  Widget _buildHistorySection(List recentHistory, HistoryProvider hp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              'Watch History',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            if (!hp.isEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '(${hp.history.length})',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
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
        if (hp.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (recentHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.history, size: 32, color: Colors.white24),
                const SizedBox(height: 8),
                Text('No watch history yet', style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
              ],
            ),
          )
        else
          Column(
            children: recentHistory.take(5).toList().map((movie) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64, height: 96,
                        child: movie.posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: movie.posterUrl!,
                                width: 64, height: 96,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(color: const Color(0xFF0D1117)),
                                errorWidget: (_, _, _) => const Icon(Icons.movie, color: Colors.white24),
                              )
                            : Container(color: const Color(0xFF0D1117), child: const Icon(Icons.movie, color: Colors.white24)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(movie.watchedAt),
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                              ),
                              if (movie.watchCount > 1) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.replay, size: 12, color: Color(0xFFFFC107)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Watched ${movie.watchCount} times',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFFC107)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildChangePasswordSection() {
    return Column(
      children: [
        _settingsItem(
          icon: Icons.lock_outline,
          label: 'Change Password',
          trailing: Icon(_cpExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: Colors.white24),
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
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _npController,
                  obscureText: true,
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
                    fillColor: const Color(0xFF161B22),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _newPasswordStrength / 4,
                    minHeight: 4,
                    backgroundColor: Colors.white10,
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
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: context.read<AuthProvider>().isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Update'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => setState(() { _cpExpanded = false; _pwError = null; _pwSuccess = null; }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white24),
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
                  Text(_pwError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                if (_pwSuccess != null) ...[
                  const SizedBox(height: 8),
                  Text(_pwSuccess!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
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
          color: Colors.white38, letterSpacing: 1.2,
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
      leading: Icon(icon, size: 20, color: color ?? Colors.white54),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: color ?? Colors.white70)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  ImageProvider? _buildAvatarImage(user) {
    final url = user?.avatarUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      return MemoryImage(base64Decode(url.split(',')[1]));
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
