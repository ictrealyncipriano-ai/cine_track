import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/favorites_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import '../screens/home_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
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
    final fp = context.read<FavoritesProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !fp.isLoadingMore &&
        fp.hasMore) {
      fp.loadMoreFavorites();
    }
  }

  Future<void> _load() async {
    if (!_initialized) {
      _initialized = true;
      await context.read<FavoritesProvider>().fetchFavorites();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<FavoritesProvider>().fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FavoritesProvider>();
    final favorites = fp.favorites;

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
                      'Favorites',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                      if (!fp.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(${favorites.length})',
                          style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        ),
                      ),
                    const Spacer(),
                    if (!fp.isEmpty)
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (v) {
                          setState(() => _sortBy = v);
                          context.read<FavoritesProvider>().fetchFavorites(sortBy: v);
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
            if (fp.errorMessage != null)
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
                            fp.errorMessage!,
                            style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            fp.clearError();
                            fp.fetchFavorites();
                          },
                          child: Icon(Icons.refresh, color: Theme.of(context).colorScheme.error, size: 16),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => fp.clearError(),
                          child: Icon(Icons.close, color: Theme.of(context).colorScheme.error, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (fp.isLoading)
              const SliverFillRemaining(
                child: MovieGridShimmer(crossAxisCount: 3),
              )
            else if (favorites.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.favorite_outline,
                  title: 'No favorites yet',
                  subtitle: 'Movies you favorite will appear here',
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
                        if (index >= favorites.length) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return MovieCard(movie: favorites[index]);
                    },
                    childCount: favorites.length + (fp.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
