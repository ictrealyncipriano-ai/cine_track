import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import 'stream_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Movie? _detailed;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final tmdb = context.read<MovieProvider>();
      final details = await tmdb.fetchMovieDetails(widget.movie.id);
      if (mounted) {
        setState(() => _detailed = details);
      }
    } catch (_) {
    }
  }

  int _formatRuntime(int? minutes) {
    return minutes ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final movie = _detailed ?? widget.movie;
    final fp = context.watch<FavoritesProvider>();
    final wp = context.watch<WatchlistProvider>();
    final isFav = fp.isFavorite(movie.id);
    final isWl = wp.isInWatchlist(movie.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0D1117),
            flexibleSpace: FlexibleSpaceBar(
              background: movie.backdropUrl != null
                  ? CachedNetworkImage(
                      imageUrl: movie.backdropUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF161B22)),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF161B22)),
                    )
                  : Container(color: const Color(0xFF161B22)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 100,
                          height: 150,
                          child: movie.posterUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: movie.posterUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: const Color(0xFF161B22)),
                                  errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.white38),
                                )
                              : Container(color: const Color(0xFF161B22), child: const Icon(Icons.movie, color: Colors.white38)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (movie.releaseDate.isNotEmpty) ...[
                                  Text(
                                    movie.releaseDate.length >= 4 ? movie.releaseDate.substring(0, 4) : movie.releaseDate,
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                if (movie.runtime != null) ...[
                                  Text(
                                    '${_formatRuntime(movie.runtime)} min',
                                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                                    const SizedBox(width: 4),
                                    Text(
                                      movie.voteAverage.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFFFC107),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (movie.genres.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: movie.genres.map((g) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161B22),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      g,
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Overview',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview.isNotEmpty ? movie.overview : 'No overview available.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              fp.toggleFavorite(movie);
                            },
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_outline, size: 18),
                            label: Text(isFav ? 'Favorited' : 'Favorite'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFav ? Colors.redAccent : const Color(0xFF161B22),
                              foregroundColor: isFav ? Colors.white : Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              wp.toggleWatchlist(movie);
                            },
                            icon: Icon(isWl ? Icons.bookmark : Icons.bookmark_outline, size: 18),
                            label: Text(isWl ? 'Saved' : 'Watchlist'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isWl ? const Color(0xFF7C4DFF) : const Color(0xFF161B22),
                              foregroundColor: isWl ? Colors.white : Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StreamPlayerScreen(movie: movie),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: Text('Watch Now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
