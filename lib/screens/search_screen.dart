import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/loading_shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  int? _filterGenreId;
  int? _filterYear;
  String _filterSortBy = 'popularity.desc';

  static const List<int> _years = [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2010, 2000, 1990, 1980];

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
      context.read<MovieProvider>().search(query.trim(), genreId: _filterGenreId, year: _filterYear, sortBy: _filterSortBy);
    });
  }

  void _onFilterChanged() {
    context.read<MovieProvider>().search(_controller.text.trim(), genreId: _filterGenreId, year: _filterYear, sortBy: _filterSortBy);
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _controller.clear();
                          context.read<MovieProvider>().search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          if (mp.genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: mp.genres.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final genre = mp.genres[index];
                          final selected = _filterGenreId == genre.id;
                          return FilterChip(
                            label: Text(genre.name, style: TextStyle(fontSize: 12, color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _filterGenreId = selected ? null : genre.id);
                              _onFilterChanged();
                            },
                            backgroundColor: Theme.of(context).cardColor,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<int>(
                    icon: Icon(Icons.calendar_today, size: 18, color: _filterYear != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                    tooltip: 'Filter by year',
                    color: Theme.of(context).cardColor,
                    onSelected: (y) {
                      setState(() => _filterYear = y == _filterYear ? null : y);
                      _onFilterChanged();
                    },
                    itemBuilder: (_) => _years.map((y) => PopupMenuItem(value: y, child: Text('$y', style: TextStyle(color: _filterYear == y ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))))).toList(),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.sort, size: 18, color: _filterSortBy != 'popularity.desc' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                    tooltip: 'Sort by',
                    color: Theme.of(context).cardColor,
                    onSelected: (s) {
                      setState(() => _filterSortBy = s);
                      _onFilterChanged();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'popularity.desc', child: Text('Popular', style: TextStyle(color: _filterSortBy == 'popularity.desc' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                      PopupMenuItem(value: 'vote_average.desc', child: Text('Rating', style: TextStyle(color: _filterSortBy == 'vote_average.desc' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                      PopupMenuItem(value: 'release_date.desc', child: Text('Newest', style: TextStyle(color: _filterSortBy == 'release_date.desc' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                    ],
                  ),
                ],
              ),
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
              Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
              const SizedBox(height: 16),
              Text(
                'Search millions of movies',
                style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return MovieGridShimmer(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No results for "$query"',
            style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : MediaQuery.of(context).size.width > 600 ? 4 : 3,
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
