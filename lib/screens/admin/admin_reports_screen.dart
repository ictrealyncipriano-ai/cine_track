import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../helpers/responsive.dart';
import '../../providers/admin/analytics_provider.dart';
import '../../widgets/admin/date_range_chip.dart';
import '../../widgets/admin/admin_stat_card.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AnalyticsProvider>();
    final isDesk = Responsive.isDesktop(context);
    final padding = Responsive.horizontalPadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Reports', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
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
                  DateRangeChip(selected: prov.range, onSelected: (r) => prov.setRange(r)),
                  const SizedBox(height: 20),
                  _buildStatGrid(prov, theme),
                  const SizedBox(height: 24),
                  _buildRegistrationChart(prov, theme, isDesk),
                  const SizedBox(height: 24),
                  _buildReviewsChart(prov, theme, isDesk),
                  const SizedBox(height: 24),
                  _buildReviewStatusPie(prov, theme),
                  const SizedBox(height: 24),
                  _buildTopMovies(prov, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatGrid(AnalyticsProvider prov, ThemeData theme) {
    final o = prov.overview;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(width: 180, child: AdminStatCard(icon: Icons.people, label: 'Total Users', count: '${o?['total_users'] ?? '...'}', color: theme.colorScheme.primary)),
        SizedBox(width: 180, child: AdminStatCard(icon: Icons.person_add, label: 'New Today', count: '${o?['new_today'] ?? '...'}', color: Colors.green)),
        SizedBox(width: 180, child: AdminStatCard(icon: Icons.trending_up, label: 'Active (7d)', count: '${o?['active_7d'] ?? '...'}', color: Colors.amber)),
        SizedBox(width: 180, child: AdminStatCard(icon: Icons.rate_review, label: 'Total Reviews', count: '${o?['total_reviews'] ?? '...'}', color: Colors.blue)),
      ],
    );
  }

  Widget _buildRegistrationChart(AnalyticsProvider prov, ThemeData theme, bool isDesk) {
    final data = prov.registrations;
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((e) => (e['cnt'] as int? ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.3;
    return _section(theme, 'Registrations', Icons.person_add, [
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY.ceilToDouble(),
            barGroups: List.generate(data.length, (i) {
              final cnt = (data[i]['cnt'] as int? ?? 0).toDouble();
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: cnt, color: Colors.green, width: isDesk ? 16 : 12, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
              ]);
            }),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final label = data[i]['date'] as String? ?? '';
                return Padding(padding: const EdgeInsets.only(top: 4), child: Text(label.length > 5 ? label.substring(label.length - 5) : label, style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))));
              }, reservedSize: 20)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))))),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: null, getDrawingHorizontalLine: (v) => FlLine(color: theme.colorScheme.onSurface.withValues(alpha: 0.06), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
          ),
        ),
      ),
    ]);
  }

  Widget _buildReviewsChart(AnalyticsProvider prov, ThemeData theme, bool isDesk) {
    final data = prov.reviewsPerDay;
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((e) => (e['cnt'] as int? ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.3;
    return _section(theme, 'Reviews per Day', Icons.rate_review_outlined, [
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY.ceilToDouble(),
            barGroups: List.generate(data.length, (i) {
              final cnt = (data[i]['cnt'] as int? ?? 0).toDouble();
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: cnt, color: Colors.amber, width: isDesk ? 16 : 12, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
              ]);
            }),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final label = data[i]['date'] as String? ?? '';
                return Padding(padding: const EdgeInsets.only(top: 4), child: Text(label.length > 5 ? label.substring(label.length - 5) : label, style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))));
              }, reservedSize: 20)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))))),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: theme.colorScheme.onSurface.withValues(alpha: 0.06), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
          ),
        ),
      ),
    ]);
  }

  Widget _buildReviewStatusPie(AnalyticsProvider prov, ThemeData theme) {
    final data = prov.reviewStatuses;
    if (data.isEmpty) return const SizedBox.shrink();
    final statusColors = {'pending': Colors.orange, 'approved': Colors.green, 'rejected': Colors.red, 'reported': Colors.purple};
    final total = data.fold<int>(0, (s, e) => s + (e['cnt'] as int? ?? 0));
    return _section(theme, 'Review Statuses', Icons.pie_chart_outline, [
      SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: data.map((e) {
                    final cnt = (e['cnt'] as int? ?? 0).toDouble();
                    final status = e['status'] as String? ?? '';
                    return PieChartSectionData(value: cnt, color: statusColors[status] ?? Colors.grey, radius: 50, title: total > 0 ? '${(cnt / total * 100).toStringAsFixed(0)}%' : '0%', titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.map((e) {
                final status = e['status'] as String? ?? '';
                final cnt = e['cnt'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColors[status] ?? Colors.grey, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Text('$status ($cnt)', style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildTopMovies(AnalyticsProvider prov, ThemeData theme) {
    final movies = prov.topMovies;
    return _section(theme, 'Top Movies', Icons.movie_outlined, [
      if (movies.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No data yet', style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)))))
      else
        ...movies.asMap().entries.map((e) {
          final m = e.value;
          final title = m['title'] as String? ?? 'Unknown';
          final total = m['total_interactions'] as String? ?? '0';
          final posterPath = m['poster_path'] as String?;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 24, child: Text('${e.key + 1}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)))),
                Container(width: 32, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                  child: posterPath != null ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network('https://image.tmdb.org/t/p/w92$posterPath', width: 32, height: 48, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.movie, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)))) : Icon(Icons.movie, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(total, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary))),
              ],
            ),
          );
        }),
    ]);
  }

  Widget _section(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 6, height: 20, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }
}
