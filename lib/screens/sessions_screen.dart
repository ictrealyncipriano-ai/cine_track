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
    _loadSessions();
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
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    } else {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
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
                        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadSessions, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _sessions == null || _sessions!.isEmpty
                  ? const Center(child: Text('No sessions found', style: TextStyle(color: Colors.white54)))
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
                              color: const Color(0xFF161B22),
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
                                              color: Colors.white,
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
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                                      ),
                                      Text(
                                        'Expires: $expiresAt',
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                                      ),
                                      if (deviceInfo != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${deviceInfo['platform'] ?? '?'} · ${deviceInfo['model'] ?? '?'} · ${deviceInfo['os_version'] ?? '?'}',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
                                        ),
                                      ],
                                      if (ipAddress.isNotEmpty)
                                        Text(
                                          ipAddress,
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white24),
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
                                        foregroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: Colors.redAccent),
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
