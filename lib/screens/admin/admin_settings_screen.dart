import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config.dart';
import '../../helpers/responsive.dart';
import '../../providers/admin/admin_settings_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSettingsProvider>().fetchSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminSettingsProvider>();
    final padding = Responsive.horizontalPadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (prov.successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(prov.successMessage!, style: GoogleFonts.inter(fontSize: 13, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  if (prov.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(prov.error!, style: GoogleFonts.inter(fontSize: 13, color: Colors.red))),
                          ],
                        ),
                      ),
                    ),
                  _buildSettingsSection(theme, prov),
                  const SizedBox(height: 28),
                  _buildInfoSection(theme),
                  SizedBox(height: padding),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, AdminSettingsProvider prov) {
    final s = prov.settings;
    final allowReg = s['allow_registrations'] as bool? ?? true;
    final maintMode = s['maintenance_mode'] as bool? ?? false;
    final requireEmail = s['require_email_verification'] as bool? ?? true;
    final defaultRole = s['default_user_role'] as String? ?? 'user';

    return _buildCard(theme, 'Application Settings', Icons.tune_outlined, [
      _buildToggle(theme, 'Allow New Registrations', allowReg,
          'Enable or disable new user signups', (v) {
        prov.saveSettings({'allow_registrations': v});
      }),
      const Divider(height: 24),
      _buildToggle(theme, 'Maintenance Mode', maintMode,
          'Put the site in maintenance mode (blocks all non-admin access)', (v) {
        prov.saveSettings({'maintenance_mode': v});
      }),
      const Divider(height: 24),
      _buildToggle(theme, 'Require Email Verification', requireEmail,
          'Require users to verify their email before accessing the app', (v) {
        prov.saveSettings({'require_email_verification': v});
      }),
      const Divider(height: 24),
      _buildDropdown(theme, 'Default User Role', defaultRole,
          'Role assigned to newly registered users', ['user', 'moderator'], (v) {
        if (v != null) prov.saveSettings({'default_user_role': v});
      }),
    ]);
  }

  Widget _buildInfoSection(ThemeData theme) {
    return _buildCard(theme, 'Application Info', Icons.info_outline, [
      _buildInfoRow(theme, 'App Name', 'CineTrack'),
      _buildInfoRow(theme, 'Version', '1.0.0'),
      _buildInfoRow(theme, 'API URL', AppConfig.apiBaseUrl),
      _buildInfoRow(theme, 'Environment',
          AppConfig.apiBaseUrl.contains('localhost') ? 'Development' : 'Production'),
    ]);
  }

  Widget _buildCard(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6, height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildToggle(ThemeData theme, String label, bool value, String subtitle, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildDropdown(ThemeData theme, String label, String value, String subtitle, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
