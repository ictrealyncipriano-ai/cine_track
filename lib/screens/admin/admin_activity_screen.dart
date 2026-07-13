import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../helpers/time_ago.dart';
import '../../providers/admin/activity_log_provider.dart';
import '../../widgets/pagination_bar.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  String? _actionFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogProvider>().fetchLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetch({int page = 1}) {
    context.read<ActivityLogProvider>().fetchLogs(
      page: page,
      action: _actionFilter,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<ActivityLogProvider>();
    final isDesk = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Activity Log',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          // ── Filters ──
          _buildFilters(context, admin),
          // ── Content ──
          Expanded(
            child: admin.isLoading
                ? const Center(child: CircularProgressIndicator())
                : admin.error != null
                    ? _buildError(admin)
                    : admin.logs.isEmpty
                        ? _buildEmpty()
                        : _buildLogList(admin, theme, isDesk),
          ),
          // ── Pagination ──
          if (admin.totalLogs > 30)
            PaginationBar(
              currentPage: admin.currentPage,
              totalPages: (admin.totalLogs / 30).ceil(),
              onPageChanged: (p) => _fetch(page: p),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ActivityLogProvider admin) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _fetch(),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _actionFilter,
            hint: const Text('All Actions'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Actions')),
              ...admin.actionTypes.map(
                (a) => DropdownMenuItem(value: a, child: Text(a)),
              ),
            ],
            onChanged: (v) {
              setState(() => _actionFilter = v);
              _fetch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(ActivityLogProvider admin, ThemeData theme, bool isDesk) {
    if (isDesk) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Admin')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Target')),
            DataColumn(label: Text('Details')),
            DataColumn(label: Text('Date')),
          ],
          rows: admin.logs.map((log) => DataRow(
            cells: [
              DataCell(Text(
                log.adminName ?? 'Unknown',
                style: GoogleFonts.inter(fontSize: 13),
              )),
              DataCell(_buildActionChip(theme, log.actionType)),
              DataCell(Text(
                '${log.targetType} #${log.targetId?.toString() ?? ''}',
                style: GoogleFonts.inter(fontSize: 12),
              )),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  log.description ?? '',
                  style: GoogleFonts.inter(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
              DataCell(Text(
                timeAgo(log.createdAt),
                style: GoogleFonts.inter(fontSize: 12),
              )),
            ],
          )).toList(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: admin.logs.length,
      itemBuilder: (_, i) {
        final log = admin.logs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _actionColor(log.actionType, theme)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _actionIcon(log.actionType),
                    size: 18,
                    color: _actionColor(log.actionType, theme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            log.adminName ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildActionChip(theme, log.actionType),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.description ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.targetType} — ${timeAgo(log.createdAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionChip(ThemeData theme, String action) {
    final color = _actionColor(action, theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _actionColor(String action, ThemeData theme) {
    switch (action) {
      case 'ban':
      case 'delete':
        return Colors.red;
      case 'unban':
        return Colors.green;
      case 'promote':
      case 'demote':
        return Colors.amber;
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'ban':
        return Icons.block;
      case 'unban':
        return Icons.check_circle_outline;
      case 'promote':
        return Icons.arrow_upward;
      case 'demote':
        return Icons.arrow_downward;
      case 'approve':
        return Icons.thumb_up;
      case 'reject':
        return Icons.thumb_down;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildError(ActivityLogProvider admin) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load activity logs: ${admin.error}'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _fetch(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No activity logs found',
              style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context)
                  .colorScheme.onSurface.withValues(alpha: 0.54))),
        ],
      ),
    );
  }

}
