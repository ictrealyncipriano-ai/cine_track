import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/responsive.dart';
import '../../providers/admin_provider.dart';

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({super.key});

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  String _sortBy = 'interactions';
  String _sortOrder = 'desc';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAdminMovies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetch({int page = 1}) {
    context.read<AdminProvider>().fetchAdminMovies(
      page: page,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesk = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Movie Management',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Column(
        children: [
          // ── Search & Sort ──
          _buildSearchBar(context),
          // ── Content ──
          Expanded(
            child: admin.isLoadingAdminMovies
                ? const Center(child: CircularProgressIndicator())
                : admin.adminMoviesError != null
                    ? _buildError(admin)
                    : admin.adminMovies.isEmpty
                        ? _buildEmpty()
                        : _buildMovieList(admin, isDesk, theme),
          ),
          // ── Pagination ──
          if (admin.totalAdminMovies > 20)
            _buildPagination(admin),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search movies...',
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
            value: _sortBy,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'interactions', child: Text('Most Interactions')),
              DropdownMenuItem(value: 'reviews', child: Text('Most Reviews')),
              DropdownMenuItem(value: 'favorites', child: Text('Most Favorites')),
              DropdownMenuItem(value: 'title', child: Text('Title')),
              DropdownMenuItem(value: 'last_interaction', child: Text('Recent')),
            ],
            onChanged: (v) {
              setState(() => _sortBy = v ?? 'interactions');
              _fetch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMovieList(AdminProvider admin, bool isDesk, ThemeData theme) {
    if (isDesk) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DataTable(
          sortColumnIndex: _sortBy == 'title' ? 1 : 0,
          sortAscending: _sortOrder == 'asc',
          columns: [
            const DataColumn(label: Text('Movie')),
            DataColumn(
              label: const Text('Title'),
              onSort: (_, asc) => _sort('title', asc),
            ),
            DataColumn(label: const Text('Reviews')),
            DataColumn(label: const Text('Favorites')),
            DataColumn(label: const Text('Watchlist')),
            DataColumn(label: const Text('Total')),
            DataColumn(label: const Text('Last Active')),
          ],
          rows: admin.adminMovies.map((m) => DataRow(
            cells: [
              DataCell(_buildThumbnail(m)),
              DataCell(Text(
                m['title'] as String? ?? 'Unknown',
                style: GoogleFonts.inter(fontSize: 13),
              )),
              DataCell(Text(
                '${m['review_count'] ?? 0}',
                style: GoogleFonts.inter(fontSize: 13),
              )),
              DataCell(Text(
                '${m['favorite_count'] ?? 0}',
                style: GoogleFonts.inter(fontSize: 13),
              )),
              DataCell(Text(
                '${m['watchlist_count'] ?? 0}',
                style: GoogleFonts.inter(fontSize: 13),
              )),
              DataCell(_buildInteractionBadge(m)),
              DataCell(Text(
                _relativeDate(m['last_interaction'] as String?),
                style: GoogleFonts.inter(fontSize: 11),
              )),
            ],
          )).toList(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: admin.adminMovies.length,
      itemBuilder: (_, i) => _buildMovieCard(admin.adminMovies[i], theme),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie, ThemeData theme) {
    final title = movie['title'] as String? ?? 'Unknown';
    final posterPath = movie['poster_path'] as String?;
    final reviews = movie['review_count'] ?? 0;
    final favorites = movie['favorite_count'] ?? 0;
    final watchlist = movie['watchlist_count'] ?? 0;
    final total = movie['total_interactions'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Poster thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: posterPath != null && posterPath.isNotEmpty
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w92$posterPath',
                      width: 48,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 72,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        child: Icon(Icons.movie, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      child: Icon(Icons.movie, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniStat(theme, Icons.rate_review_outlined, '$reviews'),
                      const SizedBox(width: 12),
                      _miniStat(theme, Icons.favorite_outline, '$favorites'),
                      const SizedBox(width: 12),
                      _miniStat(theme, Icons.bookmark_outline, '$watchlist'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(ThemeData theme, IconData icon, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 3),
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(Map<String, dynamic> movie) {
    final posterPath = movie['poster_path'] as String?;
    if (posterPath == null || posterPath.isEmpty) {
      return Container(
        width: 32,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.movie, size: 16, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        'https://image.tmdb.org/t/p/w92$posterPath',
        width: 32,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 32,
          height: 48,
          color: Colors.grey.withValues(alpha: 0.1),
          child: Icon(Icons.movie, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildInteractionBadge(Map<String, dynamic> movie) {
    final total = movie['total_interactions'] ?? 0;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: total > 10
            ? Colors.green.withValues(alpha: 0.15)
            : total > 3
                ? Colors.amber.withValues(alpha: 0.15)
                : theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$total',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: total > 10
              ? Colors.green
              : total > 3
                  ? Colors.amber
                  : theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  void _sort(String column, bool asc) {
    setState(() {
      _sortBy = column;
      _sortOrder = asc ? 'asc' : 'desc';
    });
    _fetch();
  }

  Widget _buildPagination(AdminProvider admin) {
    final totalPages = (admin.totalAdminMovies / 20).ceil();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: admin.adminMoviesPage > 1
                ? () => _fetch(page: admin.adminMoviesPage - 1)
                : null,
          ),
          Text(
            'Page ${admin.adminMoviesPage} of $totalPages',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: admin.adminMoviesPage < totalPages
                ? () => _fetch(page: admin.adminMoviesPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildError(AdminProvider admin) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load movies: ${admin.adminMoviesError}'),
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
          Icon(Icons.movie_outlined, size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No movies found',
              style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context)
                  .colorScheme.onSurface.withValues(alpha: 0.54))),
          const SizedBox(height: 8),
          Text('Movies appear here when users interact with them.',
              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context)
                  .colorScheme.onSurface.withValues(alpha: 0.38))),
        ],
      ),
    );
  }

  String _relativeDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 60) return '${diff.inDays ~/ 30}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      return 'Today';
    } catch (_) {
      return dateStr;
    }
  }
}
