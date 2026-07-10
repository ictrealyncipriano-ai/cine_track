import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_stat_card.dart';
import '../../widgets/admin/admin_activity_tile.dart';
import '../../widgets/admin/admin_pending_review_card.dart';

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

  // ────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: admin.isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : admin.dashboardError != null
              ? _buildError(admin)
              : RefreshIndicator(
                  onRefresh: () => admin.fetchDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildContent(admin),
                  ),
                ),
    );
  }

  Widget _buildContent(AdminProvider admin) {
    final isDesk = Responsive.isDesktop(context);
    final padding = Responsive.horizontalPadding(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Welcome Header ──
        _buildWelcomeHeader(theme, padding),
        SizedBox(height: isDesk ? 28 : 24),
        // ── Stat Cards ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildStatGrid(admin, isDesk),
        ),
        SizedBox(height: isDesk ? 32 : 28),
        // ── Two-column (desktop) or stacked (mobile) sections ──
        _buildMiddleSection(admin, isDesk, padding),
        SizedBox(height: isDesk ? 32 : 28),
        // ── Analytics & Top Movies ──
        _buildAnalyticsSection(admin, isDesk, padding),
        SizedBox(height: isDesk ? 32 : 28),
        // ── Quick Actions ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildQuickActions(theme),
        ),
        // Bottom spacer for safe area
        SizedBox(height: padding),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Welcome Header
  // ────────────────────────────────────────────────────────────────

  Widget _buildWelcomeHeader(ThemeData theme, double padding) {
    final now = DateTime.now();
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dayName = dayNames[now.weekday - 1];
    final dateStr =
        '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(padding, 24, padding, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, Admin',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Here's what's happening with your platform today.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Date badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Stat Cards Grid
  // ────────────────────────────────────────────────────────────────

  Widget _buildStatGrid(AdminProvider admin, bool isDesk) {
    final stats = admin.dashboardStats ?? {};
    final theme = Theme.of(context);

    final cards = [
      AdminStatCard(
        icon: Icons.people_outline,
        count: _fmt(stats['total_users']),
        label: 'Total Users',
        color: theme.colorScheme.primary,
        trend: 12.5,
        onTap: () => context.go('/admin/users'),
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
        color: const Color(0xFF5B8DEF),
      ),
      AdminStatCard(
        icon: Icons.rate_review_outlined,
        count: _fmt(stats['total_reviews']),
        label: 'Total Reviews',
        color: Colors.amber.shade700,
      ),
    ];

    if (isDesk) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final padding = Responsive.horizontalPadding(context);
    // Available width = screen - padding on both sides - spacing between 2 cards
    final cardWidth = (screenWidth - padding * 2 - 12) / 2;
    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: cards
          .map((c) => SizedBox(width: cardWidth, child: c))
          .toList(),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Middle Section — Pending Reviews + Recent Activity
  // ────────────────────────────────────────────────────────────────

  Widget _buildMiddleSection(AdminProvider admin, bool isDesk, double padding) {
    if (isDesk) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildPendingReviews(admin),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: _buildRecentActivity(admin),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildPendingReviews(admin),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildRecentActivity(admin),
        ),
      ],
    );
  }

  // ── Pending Reviews ──────────────────────────────────────────

  Widget _buildPendingReviews(AdminProvider admin) {
    final theme = Theme.of(context);
    final reviews = admin.pendingReviewsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Pending Reviews',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${reviews.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/admin/reviews'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          _buildEmptyBox(
            icon: Icons.check_circle_outline,
            message: 'No pending reviews',
            subtitle: 'All reviews have been moderated.',
          )
        else
          ...reviews.take(3).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminPendingReviewCard(
                    review: r,
                    onTap: () => context.go('/admin/reviews'),
                  ),
                ),
              ),
      ],
    );
  }

  // ── Recent Activity ──────────────────────────────────────────

  Widget _buildRecentActivity(AdminProvider admin) {
    final theme = Theme.of(context);
    final activity = admin.recentActivity;

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
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (activity.isNotEmpty) ...[
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/admin/activity'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (activity.isEmpty)
          _buildEmptyBox(
            icon: Icons.history,
            message: 'No recent activity',
            subtitle: 'Activity will appear here as users interact.',
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: activity.take(8).map((a) {
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

  // ────────────────────────────────────────────────────────────────
  // Analytics & Top Movies Section
  // ────────────────────────────────────────────────────────────────

  Widget _buildAnalyticsSection(AdminProvider admin, bool isDesk, double padding) {
    final theme = Theme.of(context);
    final analytics = admin.analytics;
    final topMovies = admin.topMovies;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: isDesk
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildRegistrationChart(theme, analytics),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: _buildTopMoviesCard(theme, topMovies),
                ),
              ],
            )
          : Column(
              children: [
                _buildRegistrationChart(theme, analytics),
                const SizedBox(height: 24),
                _buildTopMoviesCard(theme, topMovies),
              ],
            ),
    );
  }

  // ── Bar Chart ──────────────────────────────────────────────────

  Widget _buildBarChart(ThemeData theme, {
    required String title,
    required List<dynamic> values,
    required List<dynamic> dates,
    required Color barColor,
  }) {
    if (values.isEmpty) {
      return _buildEmptyBox(
        icon: Icons.bar_chart_outlined,
        message: 'No data yet',
        subtitle: 'Data will appear as users interact.',
      );
    }

    final maxVal = values.cast<num>().fold<num>(0, (a, b) => a > b ? a : b);
    final maxBarHeight = 120.0;

    return Container(
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
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: maxBarHeight + 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length.clamp(0, 14), (i) {
                final val = values[i] is num ? (values[i] as num).toDouble() : 0.0;
                final barH = maxVal > 0 ? (val / maxVal) * maxBarHeight : 0.0;
                final dateStr = dates.length > i ? dates[i].toString() : '';
                final dayLabel = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            val.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: barH.clamp(0, maxBarHeight),
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.7),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 7.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Registration Trend Chart ──────────────────────────────────

  Widget _buildRegistrationChart(ThemeData theme, Map<String, dynamic>? analytics) {
    if (analytics == null) {
      return _buildEmptyBox(
        icon: Icons.bar_chart_outlined,
        message: 'Analytics loading...',
        subtitle: 'Charts will appear here.',
      );
    }

    final registrations = analytics['registrations'] as Map<String, dynamic>?;
    final reviewsPerDay = analytics['reviews_per_day'] as Map<String, dynamic>?;
    final reviewStatuses = analytics['review_statuses'] as Map<String, dynamic>?;

    return Column(
      children: [
        _buildBarChart(
          theme,
          title: 'New Registrations (14 days)',
          values: registrations?['values'] as List<dynamic>? ?? [],
          dates: registrations?['dates'] as List<dynamic>? ?? [],
          barColor: Colors.green,
        ),
        const SizedBox(height: 16),
        _buildBarChart(
          theme,
          title: 'Reviews Per Day (14 days)',
          values: reviewsPerDay?['values'] as List<dynamic>? ?? [],
          dates: reviewsPerDay?['dates'] as List<dynamic>? ?? [],
          barColor: Colors.amber,
        ),
        if (reviewStatuses != null && reviewStatuses.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildReviewStatusPie(theme, reviewStatuses),
        ],
      ],
    );
  }

  // ── Review Status Breakdown ───────────────────────────────────

  Widget _buildReviewStatusPie(ThemeData theme, Map<String, dynamic> statuses) {
    final total = statuses.values.fold<int>(0, (a, b) => a + (b as int));
    if (total == 0) return const SizedBox.shrink();

    final statusColors = <String, Color>{
      'pending': Colors.orange,
      'approved': Colors.green,
      'rejected': Colors.red,
      'reported': Colors.purple,
    };

    return Container(
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
              Text(
                'Review Status Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Simple stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 24,
              child: Row(
                children: statuses.entries.map((e) {
                  final pct = (e.value as int) / total;
                  return Expanded(
                    flex: (pct * 100).round().clamp(1, 100),
                    child: Container(
                      color: statusColors[e.key] ?? Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: statuses.entries.map((e) {
              final pct = total > 0 ? ((e.value as int) / total * 100).toStringAsFixed(0) : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColors[e.key] ?? Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key}: ${e.value} ($pct%)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Top Movies ────────────────────────────────────────────────

  Widget _buildTopMoviesCard(ThemeData theme, List<Map<String, dynamic>> topMovies) {
    return Container(
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
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.movie_outlined, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top Movies',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/movies'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topMovies.isEmpty)
            _buildMiniEmptyBox(theme)
          else
            ...topMovies.take(5).map((m) {
              final title = m['title'] as String? ?? 'Unknown';
              final interactions = m['total_interactions'] ?? 0;
              final posterPath = m['poster_path'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: posterPath != null && posterPath.isNotEmpty
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w92$posterPath',
                              width: 36,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 36, height: 54,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                                child: Icon(Icons.movie, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                              ),
                            )
                          : Container(
                              width: 36, height: 54,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                              child: Icon(Icons.movie, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$interactions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniEmptyBox(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.movie_outlined, size: 28,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          Text(
            'No movie data yet',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Quick Actions
  // ────────────────────────────────────────────────────────────────

  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      _QuickAction(
        icon: Icons.rate_review_outlined,
        label: 'Moderate Reviews',
        subtitle: 'Approve or reject user reviews',
        color: Colors.amber,
        route: '/admin/reviews',
      ),
      _QuickAction(
        icon: Icons.people_outline,
        label: 'Manage Users',
        subtitle: 'View, promote, or ban users',
        color: theme.colorScheme.primary,
        route: '/admin/users',
      ),
      _QuickAction(
        icon: Icons.settings_outlined,
        label: 'Settings',
        subtitle: 'Configure application settings',
        color: Colors.blue,
        route: '/admin/settings',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...actions.map((a) => _buildActionCard(a, theme)),
      ],
    );
  }

  Widget _buildActionCard(_QuickAction action, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: action.route != null
              ? () => context.go(action.route!)
              : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // Accent bar
                Container(
                  width: 3,
                  height: 36,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    action.icon,
                    size: 19,
                    color: action.color,
                  ),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
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

  // ────────────────────────────────────────────────────────────────
  // Shared Helpers
  // ────────────────────────────────────────────────────────────────

  Widget _buildEmptyBox({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AdminProvider admin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              admin.dashboardError ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.54),
              ),
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

/// Internal model for quick action cards.
class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}
