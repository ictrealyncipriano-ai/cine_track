import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final mp = context.read<MovieProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !mp.isLoadingMore &&
        mp.hasMoreSearch) {
      mp.loadMoreSearch();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<MovieProvider>().search(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MovieProvider>();
    final results = mp.searchResults;
    final isLoading = mp.isLoading;
    final isLoadingMore = mp.isLoadingMore;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () {
                          _controller.clear();
                          context.read<MovieProvider>().search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: _buildContent(results, isLoading, isLoadingMore, _controller.text),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      List<dynamic> results, bool isLoading, bool isLoadingMore, String query) {
    if (query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'Search millions of movies',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No results for "$query"',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (info) {
        if (info is ScrollEndNotification) {
          final mp = context.read<MovieProvider>();
          if (_scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 200 &&
              !mp.isLoadingMore &&
              mp.hasMoreSearch) {
            mp.loadMoreSearch();
          }
        }
        return false;
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: results.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= results.length) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return MovieCard(movie: results[index]);
        },
      ),
    );
  }
}
