import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Map<String, dynamic>>? _sessions;
  bool _loading = true;
  String? _error;

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
      setState(() {
        _loading = false;
        _sessions = List<Map<String, dynamic>>.from(result['sessions']);
      });
    }
  }

  Future<void> _revokeSession(int id) async {
    final auth = context.read<AuthProvider>();
    final error = await auth.revokeSession(id);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } else {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Sessions', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadSessions, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _sessions == null || _sessions!.isEmpty
                  ? Center(child: Text('No sessions found', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))))
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions!.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = _sessions![index];
                          final isCurrent = s['is_current'] == true;
                          final createdAt = s['created_at'] as String? ?? 'Unknown';
                          final expiresAt = s['expires_at'] as String? ?? 'Unknown';
                          final deviceInfo = s['device_info'] as Map<String, dynamic>?;
                          final ipAddress = s['ip_address'] as String? ?? '';
                          final id = s['id'] as int;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: isCurrent ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)) : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Session #$id',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.greenAccent.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Current',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Created: $createdAt',
                                        style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                                      ),
                                      Text(
                                        'Expires: $expiresAt',
                                        style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                                      ),
                                      if (deviceInfo != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${deviceInfo['platform'] ?? '?'} · ${deviceInfo['model'] ?? '?'} · ${deviceInfo['os_version'] ?? '?'}',
                                          style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                                        ),
                                      ],
                                      if (ipAddress.isNotEmpty)
                                        Text(
                                          ipAddress,
                                          style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!isCurrent)
                                  SizedBox(
                                    height: 36,
                                    child: TextButton(
                                      onPressed: () => _revokeSession(id),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                                        ),
                                      ),
                                      child: Text('Revoke', style: GoogleFonts.inter(fontSize: 13)),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
