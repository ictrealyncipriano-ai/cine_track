import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/session.dart';
import '../providers/auth_provider.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Session>? _sessions;
  bool _loading = true;
  bool _revokingAll = false;
  String? _error;
  final Set<int> _revokingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSessions());
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.getSessions();
    if (!mounted) return;

    if (result['error'] != null) {
      setState(() {
        _loading = false;
        _error = result['error'];
      });
    } else {
      final rawList = List<Map<String, dynamic>>.from(result['sessions']);
      setState(() {
        _loading = false;
        _sessions = rawList.map((j) => Session.fromJson(j)).toList();
      });
    }
  }

  Future<void> _revokeSession(Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Revoke Session?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'This will sign out the device using "${session.friendlyName}".\n\nThis action cannot be undone.',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Revoke',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _revokingIds.add(session.id));

    final auth = context.read<AuthProvider>();
    final error = await auth.revokeSession(session.id);
    if (!mounted) return;

    setState(() => _revokingIds.remove(session.id));

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session revoked'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSessions();
    }
  }

  Future<void> _revokeAll() async {
    final nonCurrent = _sessions?.where((s) => !s.isCurrent).toList() ?? [];
    if (nonCurrent.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Revoke All Other Sessions?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'This will sign out all other devices (${nonCurrent.length} sessions).\n\nYou will stay signed in on this device.\n\nThis action cannot be undone.',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Revoke All',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _revokingAll = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.revokeAllSessions();
    if (!mounted) return;

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'All other sessions revoked'),
          backgroundColor: Colors.green,
        ),
      );
    }
    setState(() => _revokingAll = false);
    _loadSessions();
  }

  String _relativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Never';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        title: Text('Sessions', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: colorScheme.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadSessions, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _sessions == null || _sessions!.isEmpty
                  ? Center(child: Text('No sessions found', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.54))))
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildRevokeAllButton(theme),
                          const SizedBox(height: 8),
                          ..._sessions!.map((s) => _buildSessionCard(s, theme)),
                        ],
                      ),
                    ),
      ),
    );
  }

  Widget _buildRevokeAllButton(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final nonCurrentCount = _sessions?.where((s) => !s.isCurrent).length ?? 0;
    if (nonCurrentCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: (_revokingAll || _loading) ? null : _revokeAll,
          icon: _revokingAll
              ? SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.error,
                  ),
                )
              : const Icon(Icons.logout, size: 18),
          label: Text('Revoke all other sessions ($nonCurrentCount)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(Session session, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isCurrent = session.isCurrent;
    final isExpired = session.isExpired;

    Color borderColor;
    Color? labelColor;
    String? labelText;
    if (isCurrent) {
      borderColor = Colors.greenAccent;
      labelColor = Colors.greenAccent;
      labelText = 'Current';
    } else if (isExpired) {
      borderColor = colorScheme.error.withValues(alpha: 0.3);
      labelColor = colorScheme.error;
      labelText = 'Expired';
    } else {
      borderColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpired
              ? colorScheme.error.withValues(alpha: 0.04)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _deviceIcon(session, colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              session.friendlyName,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isExpired
                                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (labelText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: labelColor!.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                labelText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: labelColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      _infoRow(
                        Icons.login,
                        'Created ${_relativeTime(session.createdAt)}',
                        colorScheme,
                      ),
                      if (session.lastUsedAt != null)
                        _infoRow(
                          Icons.touch_app,
                          'Last active ${_relativeTime(session.lastUsedAt)}',
                          colorScheme,
                        ),
                      _infoRow(
                        Icons.schedule,
                        isExpired ? 'Expired ${_relativeTime(session.expiresAt)}' : 'Expires ${_relativeTime(session.expiresAt)}',
                        colorScheme,
                        faded: isExpired,
                      ),
                      if (session.rememberMe)
                        _infoRow(
                          Icons.remember_me,
                          'Remembered for 7 days',
                          colorScheme,
                        ),
                      if (session.deviceInfo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${session.deviceInfo!['platform'] ?? '?'} · ${session.deviceInfo!['model'] ?? '?'} · ${session.deviceInfo!['os_version'] ?? '?'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.24),
                          ),
                        ),
                      ],
                      if (session.userAgent.isNotEmpty && session.deviceInfo == null) ...[
                        const SizedBox(height: 2),
                        Text(
                          session.userAgent,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.18),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      _infoRow(
                        Icons.language,
                        session.ipAddress,
                        colorScheme,
                      ),
                    ],
                  ),
                ),
                if (!isCurrent && !isExpired)
                  _buildRevokeButton(session, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevokeButton(Session session, ColorScheme colorScheme) {
    final isRevoking = _revokingIds.contains(session.id);
    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: isRevoking ? null : () => _revokeSession(session),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.error),
          ),
        ),
        child: isRevoking
            ? SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.error,
                ),
              )
            : Text('Revoke', style: GoogleFonts.inter(fontSize: 13)),
      ),
    );
  }

  Widget _deviceIcon(Session session, ColorScheme colorScheme) {
    IconData icon;
    Color color;
    switch (session.deviceIconLabel) {
      case 'android':
        icon = Icons.phone_android;
        color = const Color(0xFF3DDC84);
      case 'ios':
        icon = Icons.phone_iphone;
        color = const Color(0xFF000000);
      default:
        icon = Icons.laptop_windows;
        color = colorScheme.onSurface.withValues(alpha: 0.54);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _infoRow(IconData icon, String text, ColorScheme colorScheme, {bool faded = false}) {
    final alpha = faded ? 0.24 : 0.54;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.38)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: alpha),
            ),
          ),
        ],
      ),
    );
  }
}
