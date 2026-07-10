import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../helpers/responsive.dart';
import '../../config.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesk = Responsive.isDesktop(context);
    final padding = Responsive.horizontalPadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Settings',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              theme: theme,
              title: 'Application',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow(theme, 'App Name', 'CineTrack'),
                _buildInfoRow(theme, 'Version', '1.0.0'),
                _buildInfoRow(theme, 'API URL', AppConfig.apiBaseUrl),
                _buildInfoRow(theme, 'Environment',
                    AppConfig.apiBaseUrl.contains('localhost') ? 'Development' : 'Production'),
              ],
            ),
            SizedBox(height: isDesk ? 28 : 24),
            _buildSection(
              theme: theme,
              title: 'Quick Links',
              icon: Icons.link_outlined,
              children: [
                _buildLinkTile(
                  theme: theme,
                  icon: Icons.people_outline,
                  label: 'User Management',
                  subtitle: 'Manage users and permissions',
                  onTap: () => context.go('/admin/users'),
                ),
                _buildLinkTile(
                  theme: theme,
                  icon: Icons.rate_review_outlined,
                  label: 'Review Moderation',
                  subtitle: 'Approve or reject user reviews',
                  onTap: () => context.go('/admin/reviews'),
                ),
                _buildLinkTile(
                  theme: theme,
                  icon: Icons.history,
                  label: 'Activity Log',
                  subtitle: 'View all admin actions',
                  onTap: () => context.go('/admin/activity'),
                ),
                _buildLinkTile(
                  theme: theme,
                  icon: Icons.movie_outlined,
                  label: 'Movie Management',
                  subtitle: 'View and manage movies',
                  onTap: () => context.go('/admin/movies'),
                ),
              ],
            ),
            SizedBox(height: isDesk ? 28 : 24),
            _buildSection(
              theme: theme,
              title: 'About',
              icon: Icons.help_outline,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'CineTrack Admin Panel provides tools to manage users, '
                    'moderate reviews, view activity logs, and track movie engagement. '
                    'All administrative actions are logged for audit purposes.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
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
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
