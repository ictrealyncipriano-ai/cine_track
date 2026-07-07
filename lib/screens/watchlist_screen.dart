import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import '../screens/home_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _initialized = false;
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final wp = context.read<WatchlistProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !wp.isLoadingMore &&
        wp.hasMore) {
      wp.loadMoreWatchlist();
    }
  }

  Future<void> _load() async {
    if (!_initialized) {
      _initialized = true;
      await context.read<WatchlistProvider>().fetchWatchlist();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<WatchlistProvider>().fetchWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WatchlistProvider>();
    final watchlist = wp.watchlist;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Watchlist',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                      if (!wp.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(${watchlist.length})',
                          style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        ),
                      ),
                    const Spacer(),
                    if (!wp.isEmpty)
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (v) {
                          setState(() => _sortBy = v);
                          context.read<WatchlistProvider>().fetchWatchlist(sortBy: v);
                        },
                        icon: Icon(Icons.sort, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                        color: Theme.of(context).cardColor,
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'recent', child: Text('Recent', style: TextStyle(color: _sortBy == 'recent' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                          PopupMenuItem(value: 'title', child: Text('Title A-Z', style: TextStyle(color: _sortBy == 'title' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                          PopupMenuItem(value: 'rating', child: Text('Rating', style: TextStyle(color: _sortBy == 'rating' ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (wp.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            wp.errorMessage!,
                            style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            wp.clearError();
                            wp.fetchWatchlist();
                          },
                          child: Icon(Icons.refresh, color: Theme.of(context).colorScheme.error, size: 16),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => wp.clearError(),
                          child: Icon(Icons.close, color: Theme.of(context).colorScheme.error, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (wp.isLoading)
              const SliverFillRemaining(
                child: MovieGridShimmer(crossAxisCount: 3),
              )
            else if (watchlist.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.bookmark_outline,
                  title: 'No watchlist yet',
                  subtitle: 'Movies you save will appear here',
                  actionLabel: 'Browse Movies',
                  onAction: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= watchlist.length) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return MovieCard(movie: watchlist[index]);
                    },
                    childCount: watchlist.length + (wp.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
