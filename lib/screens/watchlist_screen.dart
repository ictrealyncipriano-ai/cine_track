import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _load();
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Watchlist',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (!wp.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '(${watchlist.length})',
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.white38),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: wp.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : watchlist.isEmpty
                      ? const EmptyState(
                          icon: Icons.bookmark_outline,
                          title: 'No watchlist items yet',
                          subtitle: 'Tap the bookmark icon on any movie to save it here',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: watchlist.length,
                          itemBuilder: (context, index) {
                            return MovieCard(movie: watchlist[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
