import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/movie_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/error_retry.dart';
import 'movie_details_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = context.read<MovieProvider>();
      mp.fetchGenres();
      if (mp.trending.isEmpty) {
        _onRefresh();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final mp = context.read<MovieProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !mp.isLoadingMore &&
        mp.selectedGenreId != null) {
      mp.loadMoreGenre();
    }
  }

  Future<void> _onRefresh() async {
    final mp = context.read<MovieProvider>();
    await Future.wait([
      mp.fetchTrending(),
      mp.fetchNowPlaying(),
      mp.fetchTopRated(),
      mp.fetchUpcoming(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MovieProvider>();
    final hp = context.watch<HistoryProvider>();
    final recentlyWatched = hp.recentlyWatched;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Browse Movies',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (recentlyWatched.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 18, color: Color(0xFFFFC107)),
                          const SizedBox(width: 6),
                          Text(
                            'Recently Watched',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: recentlyWatched.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final movie = recentlyWatched[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailsScreen(movie: movie),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: movie.posterUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: movie.posterUrl!,
                                              width: 110,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: const Color(0xFF161B22)),
                                              errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24),
                                            )
                                          : Container(color: const Color(0xFF161B22), child: const Icon(Icons.movie, color: Colors.white24)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    movie.title,
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            if (mp.genres.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: mp.genres.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final genre = mp.genres[index];
                      final selected = mp.selectedGenreId == genre.id;
                      return FilterChip(
                        label: Text(
                          genre.name,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          if (selected) {
                            mp.clearGenreFilter();
                          } else {
                            mp.discoverByGenre(genre.id);
                          }
                        },
                        backgroundColor: const Color(0xFF161B22),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Colors.black,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
                ),
              ),
            if (mp.selectedGenreId != null)
              _buildGenreGrid(mp)
            else ...[
              _buildSection(context, 'Trending Now', mp.trending, mp.isLoading),
              _buildSection(context, 'Now Playing', mp.nowPlaying, mp.isLoading),
              _buildSection(context, 'Coming Soon', mp.upcoming, mp.isLoading),
              _buildSection(context, 'Top Rated', mp.topRated, mp.isLoading),
            ],
            if (mp.error != null && mp.selectedGenreId == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ErrorRetry(
                    message: mp.error!,
                    onRetry: _onRefresh,
                  ),
                ),
              ),
            if (mp.error != null && mp.selectedGenreId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ErrorRetry(
                    message: mp.error!,
                    onRetry: () => mp.discoverByGenre(mp.selectedGenreId!),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreGrid(MovieProvider mp) {
    if (mp.isLoading && mp.genreMovies.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final label = mp.genres
        .where((g) => g.id == mp.selectedGenreId)
        .map((g) => g.name)
        .firstOrNull;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          if (mp.genreMovies.isEmpty && !mp.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text('No movies found',
                  style: TextStyle(color: Colors.white38)),
            )
            else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: mp.genreMovies.length,
                itemBuilder: (context, index) {
                  return MovieCard(movie: mp.genreMovies[index]);
                },
              ),
            ),
            if (mp.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<dynamic> movies, bool isLoading) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (isLoading && movies.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary),
              ),
            )
          else if (movies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text('No movies available',
                  style: TextStyle(color: Colors.white38)),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 140,
                    child: MovieCard(movie: movies[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}