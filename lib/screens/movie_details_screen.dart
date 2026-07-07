import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../models/cast_member.dart';
import '../models/review.dart';
import '../models/trailer_video.dart';
import '../providers/movie_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import '../providers/reviews_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/rating_bar.dart';
import 'stream_player_screen.dart';
import 'trailer_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Movie? _detailed;
  List<CastMember> _cast = [];
  List<Movie> _similarMovies = [];
  List<Movie> _recommendedMovies = [];
  TrailerVideo? _teaser;
  int _userRating = 0;
  final _reviewController = TextEditingController();
  bool _showReviewForm = false;
  bool _reviewSubmitting = false;
  String? _fetchError;


  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _fetchCredits();
    _fetchSimilar();
    _fetchRecommendations();
    _fetchReviews();
    _fetchTeaser();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      setState(() => _fetchError = null);
      final tmdb = context.read<MovieProvider>();
      final details = await tmdb.fetchMovieDetails(widget.movie.id);
      if (mounted) {
        setState(() => _detailed = details);
      }
    } catch (e) {
      if (mounted) setState(() => _fetchError = 'Failed to load movie details');
    }
  }

  Future<void> _fetchCredits() async {
    try {
      final tmdb = context.read<MovieProvider>();
      final cast = await tmdb.fetchMovieCredits(widget.movie.id);
      if (mounted) {
        setState(() => _cast = cast.take(15).toList());
      }
    } catch (e) {
      if (mounted) setState(() => _fetchError = _fetchError ?? 'Failed to load cast');
    }
  }

  Future<void> _fetchSimilar() async {
    try {
      final tmdb = context.read<MovieProvider>();
      final similar = await tmdb.fetchSimilarMovies(widget.movie.id);
      if (mounted) {
        setState(() => _similarMovies = similar);
      }
    } catch (e) {
      if (mounted) setState(() => _fetchError = _fetchError ?? 'Failed to load similar movies');
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      final tmdb = context.read<MovieProvider>();
      final recommended = await tmdb.fetchRecommendations(widget.movie.id);
      if (mounted) {
        setState(() => _recommendedMovies = recommended);
      }
    } catch (e) {
      if (mounted) setState(() => _fetchError = _fetchError ?? 'Failed to load recommendations');
    }
  }

  Future<void> _fetchTeaser() async {
    try {
      final tmdb = context.read<MovieProvider>();
      final teaser = await tmdb.fetchMovieTeaser(widget.movie.id);
      if (mounted) {
        setState(() => _teaser = teaser);
      }
    } catch (e) {
      if (mounted) setState(() => _fetchError = _fetchError ?? 'Failed to load trailer');
    }
  }

  Future<void> _retryFetch() async {
    setState(() => _fetchError = null);
    _fetchDetails();
    _fetchCredits();
    _fetchSimilar();
    _fetchRecommendations();
    _fetchTeaser();
  }

  Future<void> _fetchReviews() async {
    final rp = context.read<ReviewsProvider>();
    await rp.fetchReviews(widget.movie.id);
    if (mounted && rp.userReview != null) {
      setState(() {
        _userRating = rp.userReview!.rating;
        _reviewController.text = rp.userReview!.reviewText;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_userRating < 1) return;
    setState(() => _reviewSubmitting = true);
    final rp = context.read<ReviewsProvider>();
    final success = await rp.addReview(widget.movie.id, _userRating, _reviewController.text.trim());
    if (mounted) {
      setState(() {
        _reviewSubmitting = false;
        if (success) _showReviewForm = false;
      });
    }
  }

  Future<void> _deleteReview() async {
    final rp = context.read<ReviewsProvider>();
    await rp.deleteReview(widget.movie.id);
    if (mounted) {
      setState(() {
        _userRating = 0;
        _reviewController.clear();
        _showReviewForm = false;
      });
    }
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null) return 'N/A';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final movie = _detailed ?? widget.movie;
    final fp = context.watch<FavoritesProvider>();
    final wp = context.watch<WatchlistProvider>();
    final rp = context.watch<ReviewsProvider>();
    final isFav = fp.isFavorite(movie.id);
    final isWl = wp.isInWatchlist(movie.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: movie.backdropUrl != null
                  ? CachedNetworkImage(
                      imageUrl: movie.backdropUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: Theme.of(context).cardColor),
                      errorWidget: (_, _, _) => Container(color: Theme.of(context).cardColor),
                    )
                  : Container(color: Theme.of(context).cardColor),
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
                      Hero(
                        tag: 'movie_poster_${movie.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 100,
                            height: 150,
                            child: movie.posterUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: movie.posterUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(color: Theme.of(context).cardColor),
                                    errorWidget: (_, _, _) => Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                                  )
                                : Container(color: Theme.of(context).cardColor, child: Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                          ),
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
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (movie.releaseDate.isNotEmpty) ...[
                                  Text(
                                    movie.releaseDate.length >= 4 ? movie.releaseDate.substring(0, 4) : movie.releaseDate,
                                    style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                if (movie.runtime != null) ...[
                                  Text(
                                    '${_formatRuntime(movie.runtime)} min',
                                    style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      movie.voteAverage.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
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
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      g,
                                      style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
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
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview.isNotEmpty ? movie.overview : 'No overview available.',
                    style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
                  ),
                  if (_fetchError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fetchError!,
                              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _retryFetch,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text('Retry', style: GoogleFonts.inter(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_teaser != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrailerPlayerScreen(
                                video: _teaser!,
                                movieTitle: movie.title,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        label: Text(
                          _teaser!.isTeaser ? 'Watch Teaser' : 'Watch Trailer',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                              backgroundColor: isFav ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                              foregroundColor: isFav ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                              backgroundColor: isWl ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                              foregroundColor: isWl ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildReviewsSection(rp),
                  if (_cast.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Cast',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cast.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final member = _cast[index];
                          return SizedBox(
                            width: 80,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Theme.of(context).cardColor,
                                  backgroundImage: member.profileUrl != null
                                      ? CachedNetworkImageProvider(member.profileUrl!)
                                      : null,
                                  child: member.profileUrl == null
                                      ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  member.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                                Text(
                                  member.character,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_similarMovies.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Similar Movies',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similarMovies.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 140,
                            child: MovieCard(movie: _similarMovies[index]),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_recommendedMovies.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Recommendations',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendedMovies.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 140,
                            child: MovieCard(movie: _recommendedMovies[index]),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ReviewsProvider rp) {
    if (rp.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Text(
                'Ratings & Reviews',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              if (rp.averageRating != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${rp.averageRating!.toStringAsFixed(1)} (${rp.totalReviews})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 12),
        if (rp.userReview != null && !_showReviewForm)
          _buildUserReviewCard(rp.userReview!)
        else if (_showReviewForm || rp.userReview == null)
          _buildReviewForm(rp),
        if (_showReviewForm && rp.userReview != null)
          TextButton.icon(
            onPressed: () => setState(() {
              _showReviewForm = false;
              _userRating = rp.userReview!.rating;
              _reviewController.text = rp.userReview!.reviewText;
            }),
            icon: const Icon(Icons.close, size: 16),
            label: Text('Cancel', style: GoogleFonts.inter(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          ),
        if (rp.reviews.where((r) => r.id != rp.userReview?.id).isNotEmpty) ...[
          const SizedBox(height: 12),
          ...rp.reviews
              .where((r) => r.id != rp.userReview?.id)
              .map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOtherReviewCard(review),
                  )),
        ],
      ],
    );
  }

  Widget _buildUserReviewCard(Review review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingBar(rating: review.rating, starSize: 18),
              const Spacer(),
              Text(
                'Your review',
                style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
              ),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.reviewText,
              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _showReviewForm = true;
                  _userRating = review.rating;
                  _reviewController.text = review.reviewText;
                }),
                icon: const Icon(Icons.edit, size: 14),
                label: Text('Edit', style: GoogleFonts.inter(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _deleteReview,
                icon: const Icon(Icons.delete, size: 14),
                label: Text('Delete', style: GoogleFonts.inter(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm(ReviewsProvider rp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: RatingBar(
              rating: _userRating,
              starSize: 28,
              interactive: true,
              onRatingChanged: (r) => setState(() => _userRating = r),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Write your review (optional)',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _userRating < 1 || _reviewSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _reviewSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : Text(
                      rp.userReview != null ? 'Update Review' : 'Submit Review',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherReviewCard(Review review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                review.userName,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
              const Spacer(),
              RatingBar(rating: review.rating, starSize: 14),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.reviewText,
              style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
