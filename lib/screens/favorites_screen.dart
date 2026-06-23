import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/favorites_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _load();
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Favorites',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (!fp.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '(${favorites.length})',
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.white38),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: fp.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : favorites.isEmpty
                      ? const EmptyState(
                          icon: Icons.favorite_outline,
                          title: 'No favorites yet',
                          subtitle: 'Tap the heart icon on any movie to save it here',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            return MovieCard(movie: favorites[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
