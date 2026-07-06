import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../config.dart';

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
          _reviews = (data['reviews'] as List<dynamic>).cast<Map<String, dynamic>>();
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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Failed to load reviews', style: GoogleFonts.inter(color: Colors.white54)),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('No reviews yet', style: GoogleFonts.inter(fontSize: 16, color: Colors.white54)),
            const SizedBox(height: 8),
            Text('Rate and review movies to see them here', style: GoogleFonts.inter(fontSize: 13, color: Colors.white24)),
          ],
        ),
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
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final posterUrl = review['movie_poster'] != null
        ? '${AppConfig.imageBaseUrl}${review['movie_poster']}'
        : null;
    final rating = review['rating'] as int? ?? 0;
    final reviewText = review['review_text'] as String? ?? '';
    final createdAt = review['created_at'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
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
                      placeholder: (_, __) => Container(color: const Color(0xFF0D1117), width: 56, height: 84),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF0D1117), width: 56, height: 84, child: const Icon(Icons.movie, color: Colors.white24)),
                    )
                  : Container(
                      color: const Color(0xFF0D1117),
                      width: 56, height: 84,
                      child: const Icon(Icons.movie, color: Colors.white24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['movie_title'] as String? ?? 'Unknown',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                          color: filled ? const Color(0xFFFFC107) : Colors.white24,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '$rating/10',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ),
                  if (reviewText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reviewText,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(createdAt),
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ],
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
