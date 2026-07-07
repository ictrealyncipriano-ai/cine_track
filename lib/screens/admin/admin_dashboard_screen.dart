import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_stat_card.dart';
import '../../widgets/admin/admin_activity_tile.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesk = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: admin.isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : admin.dashboardError != null
              ? _buildError(admin)
              : RefreshIndicator(
                  onRefresh: () => admin.fetchDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isDesk ? 32 : 20),
                    child: ResponsiveContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stat cards ──
                          _buildStatGrid(admin, isDesk),
                          const SizedBox(height: 32),
                          // ── Recent Activity ──
                          _buildRecentActivity(admin, context),
                          const SizedBox(height: 24),
                          // ── Quick Actions ──
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatGrid(AdminProvider admin, bool isDesk) {
    final stats = admin.dashboardStats ?? {};
    final cards = [
      AdminStatCard(
        icon: Icons.people_outline,
        count: _fmt(stats['total_users']),
        label: 'Total Users',
        color: Theme.of(context).colorScheme.primary,
      ),
      AdminStatCard(
        icon: Icons.person_add_outlined,
        count: _fmt(stats['new_today']),
        label: 'New Today',
        color: Colors.green,
      ),
      AdminStatCard(
        icon: Icons.trending_up,
        count: _fmt(stats['active_7d']),
        label: 'Active (7d)',
        color: Colors.blue,
      ),
      AdminStatCard(
        icon: Icons.rate_review_outlined,
        count: _fmt(stats['total_reviews']),
        label: 'Total Reviews',
        color: Colors.amber,
      ),
    ];

    if (isDesk) {
      return Row(
        children: cards
            .map((c) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                )))
            .toList(),
      );
    }
    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: cards.map((c) => SizedBox(width: MediaQuery.of(context).size.width / 2 - 28, child: c)).toList(),
    );
  }

  Widget _buildRecentActivity(AdminProvider admin, BuildContext context) {
    final activity = admin.recentActivity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (activity.length >= 20) ...[
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('See All >'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (activity.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No recent activity',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: activity.take(10).map((a) {
                return AdminActivityTile(
                  userName: a['user_name'] as String? ?? 'Unknown',
                  actionType: a['action_type'] as String? ?? '',
                  description: a['description'] as String? ?? '',
                  movieTitle: a['movie_title'] as String?,
                  createdAt: a['created_at'] as String? ?? '',
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionChip(
              avatar: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Moderate Reviews'),
              onPressed: () => Navigator.pushNamed(context, '/admin/reviews'),
            ),
            ActionChip(
              avatar: const Icon(Icons.people_outline, size: 18),
              label: const Text('Manage Users'),
              onPressed: () => Navigator.pushNamed(context, '/admin/users'),
            ),
            ActionChip(
              avatar: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Settings'),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(AdminProvider admin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              admin.dashboardError ?? '',
              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => admin.fetchDashboard(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic val) {
    if (val == null) return '0';
    if (val is int) return val.toString();
    if (val is double) return val.toInt().toString();
    return val.toString();
  }
}
