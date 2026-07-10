import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../config.dart';
import '../models/movie.dart';
import '../widgets/loading_shimmer.dart';
import '../screens/home_screen.dart';
import '../widgets/empty_state.dart';
import 'movie_details_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/reviews/my.php');
      if (mounted) {
        setState(() {
          _reviews = (data['reviews'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('My Reviews', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      top: false,
      child: Builder(
        builder: (_) {
    if (_isLoading) {
      return const MovieListShimmer();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
            const SizedBox(height: 16),
            Text('Failed to load reviews', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'No reviews yet',
        subtitle: 'Your reviews will appear here',
        actionLabel: 'Discover Movies',
        onAction: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (_, i) => _reviewCard(_reviews[i]),
      ),
    );
        },
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final posterUrl = review['movie_poster'] != null
        ? '${AppConfig.imageBaseUrl}${review['movie_poster']}'
        : null;
    final rating = review['rating'] as int? ?? 0;
    final reviewText = review['review_text'] as String? ?? '';
    final createdAt = review['created_at'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailsScreen(
                  movie: Movie(
                    id: review['movie_id'] as int,
                    title: review['movie_title'] as String? ?? '',
                    overview: '',
                    releaseDate: '',
                    voteAverage: 0.0,
                    posterPath: review['movie_poster'] as String?,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      width: 56, height: 84,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: Theme.of(context).scaffoldBackgroundColor, width: 56, height: 84),
                      errorWidget: (_, _, _) => Container(color: Theme.of(context).scaffoldBackgroundColor, width: 56, height: 84, child: Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24))),
                    )
                  : Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 56, height: 84,
                      child: Icon(Icons.movie, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['movie_title'] as String? ?? 'Unknown',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final filled = i < rating / 2;
                        return Icon(
                          filled ? Icons.star : Icons.star_border,
                          size: 16,
                          color: filled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '$rating/10',
                        style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                      ),
                    ],
                  ),
                  if (reviewText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reviewText,
                      style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(createdAt),
                    style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}
