import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/admin/movie_management_provider.dart';

class TmdbSearchResult {
  final int tmdbId;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;

  const TmdbSearchResult({
    required this.tmdbId,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0,
  });

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    return TmdbSearchResult(
      tmdbId: (json['tmdb_id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TmdbSearchDialog extends StatefulWidget {
  const TmdbSearchDialog({super.key});

  static Future<TmdbSearchResult?> show(BuildContext context) {
    return showDialog<TmdbSearchResult>(
      context: context,
      builder: (_) => const TmdbSearchDialog(),
    );
  }

  @override
  State<TmdbSearchDialog> createState() => _TmdbSearchDialogState();
}

class _TmdbSearchDialogState extends State<TmdbSearchDialog> {
  final _controller = TextEditingController();
  List<TmdbSearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      final provider = context.read<MovieManagementProvider>();
      final data = await provider.searchTmdb(query);
      final results = (data['results'] as List<dynamic>?)
              ?.map((e) => TmdbSearchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      setState(() => _results = results);
    } catch (e) {
      setState(() => _results = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search TMDB...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSearching ? null : _search,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !_hasSearched
                ? Center(
                    child: Text(
                      'Search for a movie to add',
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  )
                : _results.isEmpty && !_isSearching
                    ? Center(
                        child: Text(
                          'No results found',
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _results.length,
                        itemBuilder: (_, i) => _buildResultTile(_results[i], theme),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(TmdbSearchResult result, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: result.posterPath != null
              ? Image.network(
                  'https://image.tmdb.org/t/p/w92${result.posterPath}',
                  width: 46,
                  height: 69,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 46,
                    height: 69,
                    color: Colors.grey.withValues(alpha: 0.1),
                    child: const Icon(Icons.movie, size: 20),
                  ),
                )
              : Container(
                  width: 46,
                  height: 69,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: const Icon(Icons.movie, size: 20),
                ),
        ),
        title: Text(
          result.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${result.releaseDate ?? 'Unknown'}  \u2022  TMDB #${result.tmdbId}',
          style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.54)),
        ),
        trailing: const Icon(Icons.add_circle_outline, size: 22),
        onTap: () => Navigator.pop(context, result),
      ),
    );
  }
}
