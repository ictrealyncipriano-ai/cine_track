import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';

class SeeAllScreen extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final VoidCallback loadMore;
  final bool hasMore;
  final bool isLoadingMore;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.movies,
    required this.loadMore,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !widget.isLoadingMore &&
        widget.hasMore) {
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.movies;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          widget.loadMore();
        },
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : MediaQuery.of(context).size.width > 600 ? 4 : 3,
            childAspectRatio: 0.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: movies.length + (widget.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= movies.length) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return MovieCard(movie: movies[index]);
          },
        ),
      ),
    );
  }
}
