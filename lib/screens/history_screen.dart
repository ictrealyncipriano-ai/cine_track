import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/history_provider.dart';
import '../widgets/empty_state.dart';
import 'movie_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _initialized = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final hp = context.read<HistoryProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !hp.isLoadingMore &&
        hp.hasMore) {
      hp.loadMoreHistory();
    }
  }

  Future<void> _load() async {
    if (!_initialized) {
      _initialized = true;
      await context.read<HistoryProvider>().fetchHistory();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<HistoryProvider>().fetchHistory();
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HistoryProvider>();
    final history = hp.history;

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
                      'Watch History',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (!hp.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(${history.length})',
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white38),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (hp.errorMessage != null)
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
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hp.errorMessage!,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => hp.clearError(),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (hp.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (history.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.history,
                  title: 'No watch history yet',
                  subtitle: 'Movies you watch will appear here',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= history.length) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final movie = history[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MovieDetailsScreen(movie: movie),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 120,
                                  child: movie.posterUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: movie.posterUrl!,
                                          width: 80,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: const Color(0xFF0D1117)),
                                          errorWidget: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24),
                                        )
                                      : Container(color: const Color(0xFF0D1117), child: const Icon(Icons.movie, color: Colors.white24)),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          movie.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDate(movie.watchedAt),
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        if (movie.watchCount > 1) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.replay, size: 14, color: Color(0xFFFFC107)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Watched ${movie.watchCount} times',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: const Color(0xFFFFC107),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: history.length + (hp.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
